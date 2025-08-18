from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { eventbus_send } = require("eventbus")
let { platformId, aliases } = require("%sqstd/platform.nut")
let { toIntegerSafe } = require("%sqstd/string.nut")
let mkFormatAst = require("%darg/helpers/mkFormatAst.nut")
let urlAliases = require("%rGui/news/urlAliases.nut")
let wordHyphenation = require("%globalScripts/wordHyphenation.nut")
let { locColorTable } = require("%rGui/style/stdColors.nut")
let { expandArrow, defaultExpandAnimationDuration } = require("%rGui/components/expandArrow.nut")

let selectorBtnW = hdpx(465)
let widthImgMax = saSize[0] - saBordersRv[1]*2 - selectorBtnW
let insideBlockPadding = [hdpx(10), hdpx(20)]
let blockInterval = hdpx(6)
let headerMargin = 2 * blockInterval
let urlLineWidth = hdpx(1)
let borderWidth = hdpx(1)

let spoilerWidth = saSize[0] - saBordersRv[0]*2 - selectorBtnW - hdpx(124)
let contentBackground = 0x66000000

let btnActive = 0xFFCFCFCF
let btnHovActive = 0xFFFFFFFF
let btnDef = 0xFF507878
let btnHovDef = 0xFF709898

let commonTextColor = 0xFFC0C0C0
let activeTextColor = 0xFF333333
let urlColor = 0xFF17C0FC
let urlHoverColor = 0xFF84E0FA
let separatorColor = 0x33333333
let accentDefaultColor = locColorTable.info

let h1Style = { color = 0xFFDCDCFA, margin = [headerMargin, 0] }.__update(fontBig)
let h2Style = { color = 0xFFDCDCFA, margin = [headerMargin, 0] }.__update(fontMedium)
let h3Style = { color = 0xFFDCDCFA, margin = [headerMargin, 0] }.__update(fontSmallAccented)
let emphasisStyle = { color = activeTextColor, margin = [headerMargin, 0] }
let noteStyle = { color = 0xFF808080 }.__update(fontTiny)

let openUrl = @(url) eventbus_send("openUrl", { baseUrl = urlAliases?[url] ?? url })

let textArea = @(params) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  text = wordHyphenation((params?.v == "" && params?.t == "paragraph" ? "\n" : params?.v) ?? "")
  behavior = Behaviors.TextArea
  color = commonTextColor
  colorTable = locColorTable
}.__update(fontSmall, params)

function url(data, _, __) {
  if (data?.url == null)
    return textArea(data)
  let stateFlags = Watched(0)
  let onClick = @() openUrl(data.url)
  return function() {
    let color = stateFlags.get() & S_HOVER ? urlHoverColor : urlColor
    return {
      watch = stateFlags
      rendObj = ROBJ_TEXT
      text = data?.v ?? data.url
      color

      behavior = Behaviors.Button
      onElemState = @(sf) stateFlags.set(sf)
      onClick

      children = {
        size = [flex(), urlLineWidth]
        vplace = ALIGN_BOTTOM
        rendObj = ROBJ_SOLID
        color
      }
    }.__update(fontSmall, data)
  }
}

let mkUlElement = @(bullet) function(elem, level = 0) {
  local indent = hdpx(level * 50)
  if (elem == null)
    return null
  let children = [bullet]
  if (type(elem) == "array")
    children.extend(elem)
  else
    children.append(elem)
  return {
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    margin = [0, 0, 0, indent]
    children
  }
}

function objListToArrayWithLevels(x, level = 0) {
  let result = []
  foreach (e in x.v) {
    if (type(e) == "string") {
      result.append({ text = e, level = level })
    } else if (type(e) == "table" && "v" in e) {
      let subResult = objListToArrayWithLevels(e, level + 1)
      result.extend(subResult)
    }
  }
  return result
}

let mkList = @(elemFunc) @(obj, formatTextFunc, _) {
    flow = FLOW_VERTICAL
    size = FLEX_H
    children = objListToArrayWithLevels(obj).map(@(e) elemFunc(formatTextFunc(e.text), e.level))
  }

let ulBullet = { rendObj = ROBJ_TEXT, text = " • " }.__update(fontSmall)
let ulNoBullet = ulBullet.__merge({ text = "   " })
let hangingIndent = calc_comp_size(ulNoBullet)[0]
let bullets = mkList(mkUlElement(ulBullet))
let indent = mkList(mkUlElement(ulNoBullet))

let separator = {
  size = [flex(), urlLineWidth]
  margin = [blockInterval, blockInterval, hdpx(20), 0]
  rendObj = ROBJ_SOLID
  color = separatorColor
}
let textParsed = @(text) text == "----" ? separator : textArea({ text })

let formatList = @(v, formatTextFunc) type(v) != "array" ? formatTextFunc(v)
  : v.map(@(elem) formatTextFunc(elem))

let horizontal = @(obj, formatTextFunc, _) obj.__merge({
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  children = formatList(obj.v, formatTextFunc)
})

let vertical = @(obj, formatTextFunc, _) obj.__merge({
  size = FLEX_H
  flow = FLOW_VERTICAL
  children = formatList(obj.v, formatTextFunc)
})

let accent = @(obj, formatTextFunc, _) obj.__merge({
  size = FLEX_H
  margin = blockInterval
  children = [
    {
      size = flex()
      rendObj = ROBJ_SOLID
      color = locColorTable?[obj?.color] ?? accentDefaultColor
      opacity = 0.2
    }
    {
      size = FLEX_H
      rendObj = ROBJ_BOX
      borderWidth = const [0, 0, 0, hdpx(4)]
      borderColor = locColorTable?[obj?.color] ?? accentDefaultColor
      padding = const [hdpx(20), hdpx(40)]
      flow = FLOW_VERTICAL
      children = formatList(obj.v, formatTextFunc).map(@(p) p.__merge({color = locColorTable?[obj?.color] ?? accentDefaultColor}))
  }]
})

let getColWeightByPresetAndIdx = @(idx, preset) toIntegerSafe(preset?[idx + 1], 100, false)

function columns(obj, formatTextFunc, _) {
  local preset = obj?.preset ?? "single"
  preset = preset.split("_")
  local cols = obj.v.filter(@(v) v?.t == "column")
  cols = cols.slice(0, preset.len())
  return {
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    children = cols.map(@(col, idx) {
      flow = FLOW_VERTICAL
      size = [flex(getColWeightByPresetAndIdx(idx, preset)), SIZE_TO_CONTENT]
      children = formatTextFunc(col.v)
      clipChildren = true
    })
  }
}

let mkWatchVideo = @(caption) {
  rendObj = ROBJ_SOLID
  color = 0x96000000
  halign = ALIGN_CENTER
  size = FLEX_H
  children = {
    rendObj = ROBJ_TEXT
    text = caption ?? loc("Watch video")
    padding = hdpx(5)
  }
}

function video(obj, _, __) {
  let stateFlags = Watched(0)
  let width = hdpx(obj?.imageWidth ?? 300)
  let height = hdpx(obj?.imageHeight ?? 80)
  let onClick = obj?.v == null ? null : @() openUrl(obj.v)
  let watchVideo = mkWatchVideo(obj?.caption)
  return @() {
    watch = stateFlags
    size = [width, height]
    hplace = ALIGN_CENTER
    margin = hdpx(5)
    padding = borderWidth

    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags.set(sf)
    onClick

    rendObj = ROBJ_BOX
    fillColor = 0xFF0C0C0C
    borderColor = stateFlags.get() & S_HOVER ? urlHoverColor : 0xFF191919
    borderWidth
    children = watchVideo
  }.__update(obj)
}

let image = @(obj, _, style = {}) {
  size = obj?.width == null || obj?.height == null ? FLEX_H
    : obj.width > widthImgMax ? [widthImgMax, widthImgMax * (obj.height.tofloat() / obj.width.tofloat())]
    : [obj.width, obj.height]
  padding = blockInterval
  hplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture(obj.v)
  margin = const [hdpx(15), 0, hdpx(10)]
  imageAffectsLayout = true
  keepAspect = true
  children = {
    rendObj = ROBJ_TEXT
    text = obj?.caption
    vplace = ALIGN_BOTTOM
    fontFxColor = 0x96000000
    fontFxFactor = min(64, hdpx(64))
    fontFx = FFT_GLOW
  }
}.__update(obj, style)

function spoiler(obj, formatTextFunc, __) {
  let isExpanded = Watched(false)
  let isHover = Watched(false)
  let contentHeight = Watched(0)
  let buttonHeight = Watched(0)
  let spoilerHeight = Watched(0)
  let resetSpoilerHeight = @() spoilerHeight.set(buttonHeight.get())

  buttonHeight.subscribe(@(v) spoilerHeight.set(v))

  let button = @() {
    watch = [isExpanded, isHover]
    size = [spoilerWidth, SIZE_TO_CONTENT]
    padding = insideBlockPadding
    rendObj = ROBJ_BOX
    flow = FLOW_HORIZONTAL
    gap = hdpx(20)
    valign = ALIGN_CENTER
    fillColor = isHover.get() && isExpanded.get() ? btnHovActive
      : !isHover.get() && isExpanded.get() ? btnActive
      : !isHover.get() && !isExpanded.get() ? btnDef
      : btnHovDef
    behavior = Behaviors.Button
    onClick = @() isExpanded.set(!isExpanded.get())
    onHover = @(sf) isHover.set(sf)
    children = [
      @() {
        watch = isExpanded
        rendObj = ROBJ_TEXTAREA
        size = FLEX_H
        behavior = Behaviors.TextArea
        text = obj.summary
        color = isExpanded.get() ? activeTextColor : commonTextColor
      }.__update(fontSmall)
      expandArrow(isExpanded, defaultExpandAnimationDuration)
    ]
  }

  let content = @() {
    watch = [isExpanded, contentHeight, buttonHeight]
    pos = [0, buttonHeight.get()]
    size = [spoilerWidth, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    padding = insideBlockPadding
    rendObj = ROBJ_BOX
    fillColor = contentBackground
    clipChildren = true
    children = formatList(obj.v, formatTextFunc)
    transform = {translate = [0, (!isExpanded.get() ? -contentHeight.get() : 0)]}
    transitions = [{
      prop = AnimProp.translate
      from = [0, -contentHeight.get()], to = [0, 0]
      duration = defaultExpandAnimationDuration
    }]
  }

  contentHeight.set(calc_comp_size(content)[1])
  buttonHeight.set(calc_comp_size(button)[1])

  isExpanded.subscribe(function(v) {
    if (v) {
      clearTimer(resetSpoilerHeight)
      spoilerHeight.set(buttonHeight.get() + contentHeight.get())
    } else
      resetTimeout(defaultExpandAnimationDuration, resetSpoilerHeight)
  })

  return @() {
    watch = spoilerHeight
    size = [spoilerWidth, spoilerHeight.get()]
    margin = [headerMargin, 0]
    clipChildren = true
    children = [
      content
      button
    ]
  }
}

function tabs(obj, formatTextFunc, __) {
  let currentTab = Watched(obj.v?[0])
  function createCaptionBtn(tab) {
    let stateFlags = Watched(0)
    return function() {
      let sf = stateFlags.get()
      let isHovered = sf & S_HOVER
      return {
        watch = [stateFlags, currentTab]
        size = flex()
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        rendObj = ROBJ_BOX
        fillColor = currentTab.get()?.header == tab?.header && !isHovered ? btnActive
          : currentTab.get()?.header == tab?.header && isHovered ? btnHovActive
          : currentTab.get()?.header != tab?.header && isHovered ? btnHovDef : btnDef
        behavior = Behaviors.Button
        margin = obj.v?[obj.v.len() - 1] != tab ? [0, hdpx(10), 0, 0] : 0
        onElemState = @(x) stateFlags.set(x)
        onClick = @() currentTab.set(tab)
        children = {
          rendObj = ROBJ_TEXT
          text = tab?.header ?? "untitled"
          color = currentTab.get()?.header == tab?.header ? activeTextColor : commonTextColor
        }.__update(fontSmall)
      }
    }
  }
  return @() {
    watch = currentTab
    size = FLEX_H
    margin = [headerMargin, 0]
    flow = FLOW_VERTICAL
    rendObj = ROBJ_BOX
    children = [
      @() {
        size = const [flex(),hdpx(100)]
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        clipChildren = true
        rendObj = ROBJ_BOX
        children = obj.v.map(@(tab) createCaptionBtn(tab))
      },
      {
        size = FLEX_H
        rendObj = ROBJ_SOLID
        color = contentBackground
        flow = FLOW_VERTICAL
        padding = hdpx(20)
        clipChildren = true
        children = currentTab.get()?.v.map(@(item) formatList(item, formatTextFunc))
      }
    ]
  }
}

let textAreaFormatter = @(obj, _ = null, __ = null) textArea(obj)
let mkTextFormatter = @(ovr) @(obj, _ = null, __ = null) textArea(obj.__merge(ovr))
let formatters = {
  def = textAreaFormatter
  textArea = textAreaFormatter
  text = textAreaFormatter
  paragraph = textAreaFormatter

  string = @(text, _ = null, __ = null) textParsed(text),
  textParsed = @(obj, _ = null, __ = null) textParsed(obj?.v)

  hangingText = mkTextFormatter({ hangingIndent })
  h1 = mkTextFormatter(h1Style)
  h2 = mkTextFormatter(h2Style)
  h3 = mkTextFormatter(h3Style)
  emphasis = mkTextFormatter(emphasisStyle)
  note = mkTextFormatter(noteStyle)
  preformat = mkTextFormatter({ preformatted = FMT_KEEP_SPACES | FMT_NO_WRAP })

  image
  url
  sep = @(obj, _ = null, __ = null) separator.__merge(obj)
  video

  bullets
  list = bullets
  indent
  columns
  column = vertical
  horizontal
  vertical
  accent
  spoiler
  tabs
}

let filterFormat = @(o) o?.platform != null
  && o.platform.findvalue(@(p) aliases?[p] ?? (p == platformId)) == null

return {
  formatText = mkFormatAst({ formatters, style = { lineGaps = hdpx(5) }, filter = filterFormat })
  formatters
  selectorBtnW
}
