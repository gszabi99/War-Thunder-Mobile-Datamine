from "%globalsDarg/darg_library.nut" import *
let { registerScene } = require("%rGui/navState.nut")
let { curLbId, curLbData, curLbSelfRow, curLbErrName, curLbCfg, isLbWndOpened,
  isRefreshLbEnabled, lbPage, lbMyPage, lbLastPage, isLbRequestInProgress
} = require("lbState.nut")
let { lbCfgOrdered } = require("lbConfig.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { hoverColor, localPlayerColor } = require("%rGui/style/stdColors.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { mkPaginator } = require("%rGui/components/paginator.nut")
let { spinner, spinnerOpacityAnim } = require("%rGui/components/spinner.nut")
let { mkPlaceIconSmall } = require("%rGui/components/playerPlaceIcon.nut")
let { lbHeaderHeight, lbTableHeight, lbVGap, lbHeaderRowHeight, lbRowHeight, lbTableBorderWidth, lbPageRows
} = require("lbStyle.nut")
let { RANK, NAME } = require("lbCategory.nut")
let { infoTooltipButton } = require("%rGui/components/infoButton.nut")


let tabIconSize = hdpxi(80)
let rankCellWidth = hdpx(150)
let defTxtColor = 0xFFD8D8D8
let headerTxtColor = 0xFFA0A0A0
let rowBgHeaderColor = 0xC0000000
let rowBgOddColor = 0x60000000
let rowBgEvenColor = 0x60141414

let close = @() isLbWndOpened(false)

let function mkLbTab(cfg, isSelected) {
  let { id, icon, locId } = cfg
  let stateFlags = Watched(0)
  let color = Computed(@() isSelected ? 0xFFFFFFFF
    : stateFlags.value & S_HOVER ? hoverColor
    : 0xFFC0C0C0)
  let isPushed = Computed(@() !isSelected && (stateFlags.value & S_ACTIVE) != 0)

  let content = @() {
    watch = color
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    valign = ALIGN_CENTER
    children = [
      {
        size = [tabIconSize, tabIconSize]
        rendObj = ROBJ_IMAGE
        image = Picture($"{icon}:{tabIconSize}:{tabIconSize}:P")
        color = color.value
      }
      {
        rendObj = ROBJ_TEXT
        text = loc(locId)
        color = color.value
      }.__update(fontSmall)
    ]
  }

  let underline = @() {
    watch = stateFlags
    size = [flex(), hdpx(5)]
    rendObj = ROBJ_SOLID
    color = isSelected ? 0xFFFFFFFF
      : stateFlags.value & S_HOVER ? hoverColor
      : 0
  }

  return @() {
    watch = isPushed

    behavior = Behaviors.Button
    sound = { click  = "click" }
    onElemState = @(sf) stateFlags(sf)
    onClick = @() curLbId(id)

    flow = FLOW_VERTICAL
    children = [
      content
      underline
    ]
    transform = { scale = isPushed.value ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]
  }
}

let lbTabs = @() {
  watch = curLbId
  flow = FLOW_HORIZONTAL
  gap = hdpx(40)
  children = lbCfgOrdered.map(@(cfg) mkLbTab(cfg, curLbId.value == cfg.id))
}

let header = {
  size = [flex(), lbHeaderHeight]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(40)
  children = [
    backButton(close)
    lbTabs
  ]
}

let styleByCategory = {
  [RANK] = { size = [rankCellWidth, SIZE_TO_CONTENT] },
  [NAME] = { halign = ALIGN_LEFT },
}

let mkLbCell = @(category, rowData) {
  size = [flex(category.relWidth), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXT
  color = rowData?.self ? localPlayerColor : defTxtColor
  halign = ALIGN_CENTER
  text = category.getText(rowData)
}.__update(
  fontTiny,
  styleByCategory?[category] ?? {})

let function mkRankCell(category, rowData) {
  let value = category.getValue(rowData)
  if (value == null || value < 0 || value > 2)
    return mkLbCell(category, rowData)
  return {
    size = [rankCellWidth, flex()]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = mkPlaceIconSmall(value + 1)
  }
}

let cellCtorByCategory = {
  [RANK] = mkRankCell
}

let mkRow = @(categories, row) categories.map(@(c) (cellCtorByCategory?[c] ?? mkLbCell)(c, row))

let dots = {
  rendObj = ROBJ_TEXT
  color = defTxtColor
  halign = ALIGN_CENTER
  text = "..."
}.__update(fontTiny)

let mkDotsRow = @(categories) categories.map(@(c) {
    size = [flex(c.relWidth), SIZE_TO_CONTENT]
  }.__update(
    styleByCategory?[c] ?? {},
    c == RANK ? dots : {}
  ))

let mkHeaderRow = @(categories) categories.map(@(c) {
  size = [flex(c.relWidth), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(10)
  children = [
    {
      rendObj = ROBJ_TEXT
      color = headerTxtColor
      text = "locId" in c ? loc(c.locId) : null
    }.__update(fontTiny)
    c.hintLocId == "" ? null
      : infoTooltipButton(@() loc(c.hintLocId))
  ]
}.__update(styleByCategory?[c] ?? {}))

let function lbTableFull(categories, lbData, selfRow) {
  let selfIdx = selfRow?.idx ?? -1
  let startIdx = lbData?[0].idx ?? -1
  let endIdx = lbData.reduce(@(res, row) max(res, row.idx), startIdx)

  let rows = lbData.map(@(row) mkRow(categories, row))
  if (rows.len() < lbPageRows)
    rows.resize(lbPageRows, null)
  if (selfIdx >= 0) {
    if (selfIdx < startIdx || startIdx < 0) {
      rows.insert(0, mkRow(categories, selfRow))
      if (selfIdx + 1 < startIdx || startIdx < 0)
        rows.insert(1, mkDotsRow(categories))
    }
    else if (selfIdx > endIdx) {
      if (selfIdx - 1 > endIdx)
        rows.append(mkDotsRow(categories))
      rows.append(mkRow(categories, selfRow))
    }
  }

  return {
    key = categories
    size = [flex(), lbTableHeight]
    flow = FLOW_VERTICAL
    children = [
       {
         size = [flex(), lbHeaderRowHeight]
         rendObj = ROBJ_SOLID
         color = rowBgHeaderColor
         padding = lbTableBorderWidth
         flow = FLOW_HORIZONTAL
         valign = ALIGN_CENTER
         children = mkHeaderRow(categories)
       }
       {
         size = [flex(), SIZE_TO_CONTENT]
         rendObj = ROBJ_BOX
         borderColor = rowBgOddColor
         borderWidth = [0, lbTableBorderWidth, lbTableBorderWidth, lbTableBorderWidth]
         padding = [0, lbTableBorderWidth, lbTableBorderWidth, lbTableBorderWidth]
         flow = FLOW_VERTICAL
         children = rows.map(@(children, idx) {
           size = [flex(), lbRowHeight]
           rendObj = ROBJ_SOLID
           color = (idx % 2) ? rowBgOddColor : rowBgEvenColor
           flow = FLOW_HORIZONTAL
           children
         })
       }
    ]
    animations = wndSwitchAnim
  }
}

let waitLeaderBoard = {
  key = {}
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow  = FLOW_VERTICAL
  gap = hdpx(50)
  children = [
    {
      size = [hdpx(1200), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      text = loc("wait/leaderboard")
      color = defTxtColor
    }.__update(fontSmall)
    spinner
  ]
  animations = [spinnerOpacityAnim]
}

let lbErrorMsg = @(text) {
  key = text
  size = [hdpx(1200), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  text
  color = defTxtColor
  animations = [spinnerOpacityAnim]
}.__update(fontSmall)

let content = @() {
  watch = [curLbCfg, curLbData, curLbSelfRow, isLbRequestInProgress, curLbErrName]
  size = flex()
  children = curLbCfg.value != null && (curLbData.value?.len() ?? 0) > 0
      ? lbTableFull(curLbCfg.value.categories, curLbData.value, curLbSelfRow.value)
    : isLbRequestInProgress.value ? waitLeaderBoard
    : lbErrorMsg(loc(curLbErrName.value == null ? "leaderboard/noLbData" : $"error/{curLbErrName.value}"))
}

let scene = bgShaded.__merge({
  key = {}
  size = flex()
  padding = saBordersRv

  function onAttach() {
    lbPage(0)
    isRefreshLbEnabled(true)
    if (curLbId.value == null)
      curLbId(lbCfgOrdered.findvalue(@(c) c?.campaign == curCampaign.value)?.id
        ?? lbCfgOrdered.findvalue(@(_) true)?.id)
  }
  onDetach = @() isRefreshLbEnabled(false)

  flow = FLOW_VERTICAL
  gap = lbVGap
  children = [
    header
    content
    mkPaginator(lbPage, lbLastPage, lbMyPage)
  ]
  animations = wndSwitchAnim
})

registerScene("lbWnd", scene, close, isLbWndOpened)