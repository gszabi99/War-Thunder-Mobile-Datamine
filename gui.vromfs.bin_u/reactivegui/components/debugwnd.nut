from "%globalsDarg/darg_library.nut" import *
let { set_clipboard_text } = require("dagor.clipboard")
let { tostring_r, utf8ToLower } = require("%sqstd/string.nut")
let { startswith, endswith } = require("string")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")
let textInput = require("%rGui/components/textInputBase.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")

let wndWidth = min(sw(95), sh(150))

let gap = hdpx(5)
let defaultColor = 0xFFA0A0A0
let defFilterText = mkWatched(persist, "filterText", "")

let closeButtonHeight = calc_str_box("A", fontVeryTiny)[1] + 2 * hdpx(5) 
let closeButton = function(close) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    behavior = Behaviors.Button
    rendObj = ROBJ_SOLID
    onClick = close
    onElemState = @(s) stateFlags.set(s)
    hotkeys = [[btnBEscUp, loc("mainmenu/btnClose")]]
    color = (stateFlags.get() & S_ACTIVE) != 0 ? Color(106, 34, 17, 153) : Color(0, 0, 0, 0)
    children = {
      size = [closeButtonHeight, closeButtonHeight]
      rendObj = ROBJ_IMAGE
      image = Picture($"!ui/gameuiskin#btn_close.svg:{closeButtonHeight}:{closeButtonHeight}")
    }
  }
}

function tabButton(text, idx, curTab) {
  let stateFlags = Watched(0)
  return function() {
    let isSelected = curTab.get() == idx
    let sf = stateFlags.get()
    return {
      children = {
        rendObj = ROBJ_TEXT
        text
        color = isSelected ? Color(255, 255, 255) : defaultColor
      }.__update(fontVeryTiny)
      behavior = Behaviors.Button
      onClick = @() curTab.set(idx)
      onElemState = @(s) stateFlags.set(s)
      watch = [stateFlags, curTab]
      padding = const [hdpx(5), hdpx(10)]
      rendObj = ROBJ_BOX
      fillColor = sf & S_HOVER ? Color(200, 200, 200) : isSelected ? Color(0, 0, 0, 0) : Color(0, 0, 0)
      borderColor = Color(200, 200, 200)
      borderWidth = isSelected ? [hdpx(1), hdpx(1), 0, hdpx(1)] : [0, 0, hdpx(1), 0]
    }
  }
}
let hGap = freeze({ rendObj = ROBJ_SOLID size = const [hdpx(1), hdpx(10)] vplace = ALIGN_CENTER color = Color(40, 40, 40, 40) })
let mkTabs = @(tabs, curTab) @() {
  watch = curTab
  children = wrap(
    tabs.map(@(_, idx) tabButton(tabs[idx].id, idx, curTab)),
    {
      width = wndWidth
      vGap = gap
      hGap
    })
}

let textArea = @(text) {
  size = FLEX_H
  color = defaultColor
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  preformatted = FMT_AS_IS 
  text
}.__update(fontVeryTiny)

let dataToText = @(data) tostring_r(data, { maxdeeplevel = 10, compact = false })

function defaultRowFilter(rowData, rowKey, txt) {
  if (txt == "")
    return true
  if (startswith(txt, "\"") && endswith(txt, "\""))
    return txt.slice(1, -1) == rowKey.tostring()
  else if (startswith(txt, "\""))
    return startswith(rowKey.tostring(), txt.slice(1))
  else if (endswith(txt, "\""))
    return endswith(rowKey.tostring(), txt.slice(0, -1))

  if (utf8ToLower(rowKey.tostring()).contains(txt))
    return true
  if (rowData == null)
    return false
  let dataType = type(rowData)
  if (dataType == "array" || dataType == "table") {
    foreach (key, value in rowData)
      if (defaultRowFilter(value, key, txt))
        return true
    return false
  }
  return utf8ToLower(rowData.tostring()).indexof(txt) != null
}

function filterData(data, curLevel, filterLevel, rowFilter, countLeft) {
  let isArray = type(data) == "array"
  if (!isArray && type(data) != "table")
    return rowFilter(data, "") ? data : null

  let res = isArray ? [] : {}
  foreach (key, rowData in data) {
    local curData = rowData
    if (filterLevel <= curLevel) {
      let isVisible = countLeft.get() >= 0 && rowFilter(rowData, key)
      if (!isVisible)
        continue
      countLeft.set(countLeft.get() - 1)
      if (countLeft.get() < 0)
        break
    }
    else {
      curData = filterData(rowData, curLevel + 1, filterLevel, rowFilter, countLeft)
      if (curData == null)
        continue
    }

    if (isArray)
      res.append(curData)
    else
      res[key] <- curData
    if (countLeft.get() < 0)
      break
  }
  return (curLevel == 0 || res.len() > 0) ? res : null
}

let mkFilter = @(rowFilterBase, filterArr) filterArr.len() == 0 ? @(_, __) true
  : function(rowData, key) {
      foreach (anyList in filterArr) {
        local res = true
        foreach (andText in anyList)
          if (!rowFilterBase(rowData, key, andText)) {
            res = false
            break
          }
        if (res)
          return true
      }
      return false
    }

local mkInfoBlockKey = 0
function mkInfoBlock(curTabIdx, tabs, filterText, textWatch) {
  let curTabV = tabs?[curTabIdx]
  local dataWatch = curTabV?.data
  if (!(dataWatch instanceof Watched))
    dataWatch = Watched(dataWatch)
  let recalcText = function() {
    let filterArr = utf8ToLower(filterText.get()).split("||").map(@(v) v.split("&&"))
    let rowFilterBase = curTabV?.rowFilter ?? defaultRowFilter
    let rowFilter = mkFilter(rowFilterBase, filterArr)
    let countLeft = Watched(curTabV?.maxItems ?? 100)
    let resData = filterData(dataWatch.get(), 0, curTabV?.recursionLevel ?? 0, rowFilter, countLeft)
    local resText = dataToText(resData)
    if (countLeft.get() < 0)
      resText = $"{resText}\n...... has more items ......"
    textWatch.set(resText)
  }

  function timerRestart(_) {
    gui_scene.clearTimer(recalcText)
    gui_scene.setTimeout(0.8, recalcText)
  }
  filterText.subscribe(timerRestart)
  dataWatch.subscribe(timerRestart)

  mkInfoBlockKey++
  return @() {
    watch = textWatch
    key = mkInfoBlockKey
    size = FLEX_H
    children = textArea(textWatch.get())
    onAttach = recalcText
    function onDetach() {
      gui_scene.clearTimer(recalcText)
      filterText.unsubscribe(timerRestart)
      dataWatch.unsubscribe(timerRestart)
    }
  }
}

let debugWndContent = @(tabs, curTab, filterText, close, textWatch, childrenOverTabs = null) {
  size = [wndWidth + 2 * gap, sh(90)]
  stopMouse = true
  padding = gap
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  rendObj = ROBJ_SOLID
  color = Color(30, 30, 30, 240)
  flow = FLOW_VERTICAL
  gap = gap

  children = [
    {
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      valign = ALIGN_TOP
      children = [
        {
          size = const [flex(4), SIZE_TO_CONTENT]
          children = childrenOverTabs
        }
        textInput(filterText, {
          placeholder = "filter..."
          textStyle = fontVeryTiny
          ovr = { padding = const [hdpx(5), hdpx(10)] }
          onChange = @(value) filterText.set(value)
          onEscape = @() filterText.get() == "" ? close() : filterText.set("")
          hotkeys = [["L.Ctrl C", { action = @() set_clipboard_text(textWatch.get()) }]]
        }.__update(fontVeryTiny))
        closeButton(close)
      ]
    }
    mkTabs(tabs, curTab)
    makeVertScroll(
      @() {
        watch = curTab
        size = FLEX_H
        children = mkInfoBlock(curTab.get(), tabs, filterText, textWatch)
      },
      { rootBase = { behavior = Behaviors.Pannable } })
  ]
}

function mkDebugScreen(tabs, close, rootOverride = {}, filterText = defFilterText) {
  if (!(tabs instanceof Watched))
    tabs = Watched(tabs)

  let curTab = Watched(0)
  let textWatch = Watched("")
  return @() {
    watch = tabs
    size = flex()
    children = debugWndContent(tabs.get(), curTab, filterText, close, textWatch)
    hotkeys = [[btnBEscUp, { action = close, description = loc("Cancel") }]]
  }.__update(rootOverride)
}

function openDebugWnd(tabs, childrenOverTabs = null, rootOverride = {}, wndUid = "debugWnd", filterText = defFilterText
) {
  if (!(tabs instanceof Watched))
    tabs = Watched(tabs)

  let close = @() removeModalWindow(wndUid)
  let curTab = Watched(0)
  let textWatch = Watched("")
  return addModalWindow({
    key = wndUid
    size = flex()
    hotkeys = [[btnBEscUp, { action = close, description = loc("Cancel") }]]
    children = @() {
      watch = tabs
      size = flex()
      children = debugWndContent(tabs.get(), curTab, filterText, close, textWatch, childrenOverTabs)
    }
  }.__update(rootOverride))
}

return {
  mkDebugScreen
  openDebugWnd
  defaultRowFilter
  closeButton
}