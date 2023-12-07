from "%globalsDarg/darg_library.nut" import *
let { registerScene } = require("%rGui/navState.nut")
let { curLbId, curLbData, curLbSelfRow, curLbErrName, curLbCfg, isLbWndOpened,
  isRefreshLbEnabled, lbPage, lbMyPage, lbLastPage, lbTotalPlaces, isLbRequestInProgress,
  minRatingBattles, bestBattlesCount
} = require("lbState.nut")
let { hasCurLbRewards, curLbRewards, curLbTimeRange } = require("lbRewardsState.nut")
let { lbCfgOrdered } = require("lbConfig.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { actualizeStats } = require("%rGui/unlocks/userstat.nut")
let { secondsToHoursLoc, parseUnixTimeCached } = require("%appGlobals/timeToText.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { hoverColor, localPlayerColor } = require("%rGui/style/stdColors.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { mkPaginator } = require("%rGui/components/paginator.nut")
let { spinner, spinnerOpacityAnim } = require("%rGui/components/spinner.nut")
let { mkPlaceIconSmall } = require("%rGui/components/playerPlaceIcon.nut")
let { lbHeaderHeight, lbTableHeight, lbVGap, lbHeaderRowHeight, lbRowHeight, lbDotsRowHeight,
  lbTableBorderWidth, lbPageRows, rowBgHeaderColor, rowBgOddColor, rowBgEvenColor,
  prizeIcons, getRowBgColor, lbRewardsBlockWidth
} = require("lbStyle.nut")
let { RANK, NAME, PRIZE } = require("lbCategory.nut")
let { mkPublicInfo, refreshPublicInfo } = require("%rGui/contacts/contactPublicInfo.nut")
let { contactNameBlock, contactAvatar } = require("%rGui/contacts/contactInfoPkg.nut")
let { withTooltip, tooltipDetach } = require("%rGui/tooltip.nut")
let lbRewardsBlock = require("lbRewardsBlock.nut")

let tabIconSize = hdpxi(60)
let headerIconHeight = evenPx(36)
let headerIconWidth = (1.5 * headerIconHeight).tointeger()
let rankCellWidth = lbHeaderRowHeight * (isWidescreen ? 2.5 : 2.0)
let nameWidth = calc_str_box("WWWWWWWWWWWWWWWWWW", isWidescreen ? fontTiny : fontVeryTiny)[0]
let nameGap = hdpx(10)
let nameCellWidth = lbRowHeight + nameGap + nameWidth
let defTxtColor = 0xFFD8D8D8

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
    valign = ALIGN_BOTTOM
    children = [
      {
        size = [tabIconSize, tabIconSize]
        rendObj = ROBJ_IMAGE
        image = Picture($"{icon}:{tabIconSize}:{tabIconSize}:P")
        color = color.value
        keepAspect = true
        imageValign = ALIGN_BOTTOM
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
    gap = hdpx(10)
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

let function rewardsTimer() {
  let { start = null, end = null } = curLbTimeRange.value
  if (start == null && end == null)
    return { watch = curLbTimeRange }

  local locId = null
  local timeLeft = 0
  if (start != null) {
    let startTime = parseUnixTimeCached(start)
    if (startTime > serverTime.value) {
      locId = "lb/seasonStartTime"
      timeLeft = startTime - serverTime.value
    }
  }
  if (end != null && locId == null) {
    let endTime = parseUnixTimeCached(end)
    if (endTime > serverTime.value) {
      locId = "lb/seasonEndTime"
      timeLeft = endTime - serverTime.value
    }
    else
      locId = "lb/seasonFinished"
  }

  return {
    watch = [curLbTimeRange, serverTime]
    rendObj = ROBJ_TEXT
    color = defTxtColor
    text = locId == null ? null : loc(locId, { time = secondsToHoursLoc(timeLeft) })
  }.__update(fontTiny)
}

let header = {
  size = [flex(), lbHeaderHeight]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(40)
  children = [
    backButton(close)
    lbTabs
    { size = flex() }

    rewardsTimer
  ]
}

let styleByCategory = {
  [RANK] = { size = [rankCellWidth, SIZE_TO_CONTENT] },
  [NAME] = { size = [nameCellWidth, SIZE_TO_CONTENT], halign = ALIGN_LEFT },
}

let mkLbCell = @(category, rowData) {
  size = [flex(category.relWidth), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXT
  color = rowData?.self ? localPlayerColor : defTxtColor
  halign = ALIGN_CENTER
  vplace = ALIGN_CENTER
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

let function mkNameCell(category, rowData) {
  let userId = rowData._id.tostring()
  let info = mkPublicInfo(userId)
  let realnick = category.getText(rowData)
  let nameFont = isWidescreen || calc_str_box(realnick, fontTiny)[0] <= nameWidth
    ? fontTiny
    : fontVeryTiny
  return @() {
    watch = info
    key = userId
    size = [nameCellWidth, lbRowHeight]
    onAttach = @() refreshPublicInfo(userId)
    flow = FLOW_HORIZONTAL
    gap = nameGap
    valign = ALIGN_CENTER
    children = [
      contactAvatar(info.value, lbRowHeight - hdpx(2))
      contactNameBlock({ realnick }, info.value, [], { nameStyle = nameFont, titleStyle = fontVeryTiny })
    ]
  }
}

let function mkPrizeCell(category, rowData) {
  let place = rowData?.idx ?? -1
  let rewardIdx = Computed(function() {
    if (place < 0)
      return -1
    return curLbRewards.value.findindex(@(r) r.progress == -1 ? true
      : r.rType == "tillPlaces" ? r.progress > place
      : r.rType == "tillPercent" && lbTotalPlaces.value > 0 ? r.progress >= 100.0 * place / lbTotalPlaces.value
      : false)
  })
  return @() {
    watch = rewardIdx
    size = [flex(category.relWidth), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    vplace = ALIGN_CENTER
    children = {
      size = [headerIconHeight, headerIconHeight]
      rendObj = ROBJ_IMAGE
      image = rewardIdx.value not in prizeIcons ? null
        : Picture($"ui/gameuiskin#{prizeIcons[rewardIdx.value]}:{headerIconHeight}:{headerIconHeight}:P")
    }
  }
}

let cellCtorByCategory = {
  [RANK] = mkRankCell,
  [NAME] = mkNameCell,
  [PRIZE] = mkPrizeCell,
}

let mkRow = @(categories, row) categories.map(@(c) (cellCtorByCategory?[c] ?? mkLbCell)(c, row))

let dots = {
  rendObj = ROBJ_TEXT
  color = defTxtColor
  halign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  text = "..."
}.__update(fontTiny)

let mkDotsRow = @(categories) categories.map(@(c) {
    size = [flex(c.relWidth), SIZE_TO_CONTENT]
  }.__update(
    styleByCategory?[c] ?? {},
    c == RANK ? dots : {}
  ))

let function headerIconButton(icon, contentCtor, hasHint) {
  if (!hasHint && icon == null)
    return null

  let stateFlags = Watched(0)
  let key = {}
  return @() {
    key
    watch = stateFlags
    behavior = Behaviors.Button
    xmbNode = {}
    onElemState = withTooltip(stateFlags, key, contentCtor)
    onDetach = tooltipDetach(stateFlags)

    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      icon == null ? null
        : {
            size = [headerIconWidth, headerIconHeight]
            rendObj = ROBJ_IMAGE
            image = Picture($"{icon}:{headerIconWidth}:{headerIconHeight}:P")
            color = stateFlags.value & S_HOVER ? hoverColor : 0xFFFFFFFF
            keepAspect = true
          }
      !hasHint ? null
        : {
            rendObj = ROBJ_VECTOR_CANVAS
            size = [hdpx(40), hdpx(40)]
            lineWidth = hdpx(2)
            fillColor = 0
            color = stateFlags.value & S_HOVER ? hoverColor : 0xFFFFFFFF
            commands = [[VECTOR_ELLIPSE, 50, 50, 50, 50]]
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            children = {
              rendObj = ROBJ_TEXT
              text = "?"
              color = stateFlags.value & S_HOVER ? hoverColor : 0xFFFFFFFF
            }.__update(fontTinyAccented)
          }
    ]
    transform = { scale = stateFlags.value & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
  }
}

let mkHeaderRow = @(categories) categories.map(function(c) {
  let { locId, hintLocId, relWidth, icon } = c
  let hintCtor = @() {
    flow = FLOW_HORIZONTAL
    halign = ALIGN_RIGHT
    content = "\n".join([
        loc(locId)
        hintLocId == "" ? null : loc(hintLocId)
      ], true)
  }
  return {
    size = [flex(relWidth), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    children = headerIconButton(icon, hintCtor, hintLocId != "")
  }.__update(styleByCategory?[c] ?? {})
})

let flexGap = { size = flex() }
let myRequirementsRow = @(emptyColor) function() {
  let res = {
    watch = [minRatingBattles, bestBattlesCount]
    size = [flex(), lbRowHeight]
    rendObj = ROBJ_SOLID
    color = emptyColor
  }
  let count = minRatingBattles.value - bestBattlesCount.value
  if (count <= 0)
    return res
  return res.__update({
    color = 0x805B1D1D //0x60441616
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      flexGap
      {
        maxWidth = (saSize[0] - lbRewardsBlockWidth - lbVGap) - hdpx(150)
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc("lb/needMoreBattlesForLeaderboad", { count, countText = colorize(0xFFFFFFFF, count) })
        color = defTxtColor
      }.__update(fontTiny)
      flexGap
      {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = "/".concat(colorize(0xFFFFFFFF, bestBattlesCount.value), minRatingBattles.value)
        color = defTxtColor
      }.__update(fontTiny)
      flexGap
    ]
  })
}

let function lbTableFull(categories, lbData, selfRow) {
  let selfIdx = selfRow?.idx ?? -1
  let startIdx = lbData?[0].idx ?? -1
  let endIdx = lbData.reduce(@(res, row) max(res, row.idx), startIdx)

  let rows = lbData.map(@(row) mkRow(categories, row))
  let dotsRow = mkDotsRow(categories)
  local myRowIdx = selfIdx - startIdx
  local needRequirementsRow = false
  if (rows.len() < lbPageRows)
    rows.resize(lbPageRows, null)
  if (selfIdx >= 0) {
    if (selfIdx < startIdx || startIdx < 0) {
      myRowIdx = 0
      rows.insert(0, mkRow(categories, selfRow))
      if (selfIdx + 1 < startIdx || startIdx < 0)
        rows.insert(1, dotsRow)
    }
    else if (selfIdx > endIdx) {
      if (selfIdx - 1 > endIdx)
        rows.append(dotsRow)
      myRowIdx = rows.len()
      rows.append(mkRow(categories, selfRow))
    }
  }
  else {
    rows.append(dotsRow)
    needRequirementsRow = true
  }

  let rowsChildren = rows.map(@(children, idx) {
    size = [flex(), children == dotsRow ? lbDotsRowHeight : lbRowHeight]
    rendObj = ROBJ_SOLID
    color = getRowBgColor(idx % 2, myRowIdx == idx)
    flow = FLOW_HORIZONTAL
    children
  })

  if (needRequirementsRow)
    rowsChildren.append(myRequirementsRow((rowsChildren.len() % 2) ? rowBgOddColor : rowBgEvenColor))

  if (rowsChildren.len() < lbPageRows + 2)
    rowsChildren.append({
      size = flex()
      rendObj = ROBJ_SOLID
      color = (rowsChildren.len() % 2) ? rowBgOddColor : rowBgEvenColor
    })

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
         size = flex()
         rendObj = ROBJ_BOX
         borderColor = rowBgOddColor
         borderWidth = [0, lbTableBorderWidth, lbTableBorderWidth, lbTableBorderWidth]
         padding = [0, lbTableBorderWidth, lbTableBorderWidth, lbTableBorderWidth]
         flow = FLOW_VERTICAL
         children = rowsChildren
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

let needPaginator = Computed(@() (curLbData.value?.len() ?? 0) != 0)
let paginator = @() {
  watch = needPaginator
  size = [flex(), SIZE_TO_CONTENT]
  children = !needPaginator.value ? null
    : mkPaginator(lbPage, lbLastPage, lbMyPage, { key = needPaginator, animations = wndSwitchAnim })
}

let scene = bgShaded.__merge({
  key = {}
  size = flex()
  padding = saBordersRv

  function onAttach() {
    lbPage(0)
    isRefreshLbEnabled(true)
    actualizeStats()
    if (curLbId.value == null)
      curLbId(lbCfgOrdered.findvalue(@(c) c?.campaign == curCampaign.value)?.id
        ?? lbCfgOrdered.findvalue(@(_) true)?.id)
  }
  onDetach = @() isRefreshLbEnabled(false)

  flow = FLOW_VERTICAL
  gap = lbVGap
  children = [
    header
    @() {
      watch = hasCurLbRewards
      size = flex()
      flow = FLOW_HORIZONTAL
      gap = lbVGap
      children = [
        content
        hasCurLbRewards.value ? lbRewardsBlock : null
      ]
    }
    paginator
  ]
  animations = wndSwitchAnim
})

registerScene("lbWnd", scene, close, isLbWndOpened)