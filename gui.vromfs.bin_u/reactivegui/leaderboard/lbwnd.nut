from "%globalsDarg/darg_library.nut" import *
let { registerScene } = require("%rGui/navState.nut")
let { isEventActive } = require("%rGui/event/eventState.nut")
let { curLbId, curLbData, curLbSelfRow, curLbErrName, curLbCfg, isLbWndOpened,
  isRefreshLbEnabled, lbPage, lbMyPage, lbLastPage, lbTotalPlaces, isLbRequestInProgress,
  minRatingBattles, bestBattlesCount, hasBestBattles, isLbBestBattlesOpened
} = require("lbState.nut")
let { hasCurLbRewards, curLbRewards, curLbTimeRange } = require("lbRewardsState.nut")
let { lbCfgOrdered } = require("lbConfig.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { getPlayerName } = require("%appGlobals/user/nickTools.nut")
let { myUserName, myUserRealName } = require("%appGlobals/profileStates.nut")
let { actualizeStats } = require("%rGui/unlocks/userstat.nut")
let { secondsToHoursLoc, parseUnixTimeCached } = require("%appGlobals/timeToText.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { modalWndBg, modalWndHeaderBg } = require("%rGui/components/modalWnd.nut")
let { localPlayerColor } = require("%rGui/style/stdColors.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { mkPaginator } = require("%rGui/components/paginator.nut")
let { spinner, spinnerOpacityAnim } = require("%rGui/components/spinner.nut")
let { mkPlaceIconSmall } = require("%rGui/components/playerPlaceIcon.nut")
let { mkCustomButton, buttonStyles, mergeStyles } = require("%rGui/components/textButton.nut")
let { PRIMARY, defButtonHeight } = buttonStyles
let { lbHeaderHeight, lbTableHeight, lbVGap, lbHeaderRowHeight, lbRowHeight, lbDotsRowHeight,
  lbTableBorderWidth, lbPageRows, rowBgOddColor, rowBgEvenColor,
  prizeIcons, getRowBgColor, lbRewardsBlockWidth, lbTabIconSize
} = require("lbStyle.nut")
let { RANK, NAME, PRIZE } = require("lbCategory.nut")
let { mkPublicInfo, refreshPublicInfo } = require("%rGui/contacts/contactPublicInfo.nut")
let { contactNameBlock, contactAvatar } = require("%rGui/contacts/contactInfoPkg.nut")
let { mkLbHeaderRow, headerIconHeight } = require("mkLbHeaderRow.nut")
let lbRewardsBlock = require("lbRewardsBlock.nut")
let { mkTab } = require("%rGui/controls/tabs.nut")
let { viewProfile } = require("%rGui/mpStatistics/viewProfile.nut")
let { frameNick } = require("%appGlobals/decorators/nickFrames.nut")

let rankCellWidth = lbHeaderRowHeight * (isWidescreen ? 2.5 : 2.0)
let nameWidth = calc_str_box("WWWWWWWWWWWWWWWWWW", isWidescreen ? fontTiny : fontVeryTiny)[0]
let nameGap = hdpx(10)
let nameCellWidth = lbRowHeight + nameGap + nameWidth
let defTxtColor = 0xFFD8D8D8

let close = @() isLbWndOpened(false)

isEventActive.subscribe(function(isActive) {
  if (isActive)
    return
  isLbBestBattlesOpened(false)
  close()
})

let lbTabs = @() {
  watch = curLbId
  flow = FLOW_HORIZONTAL
  gap = hdpx(40)
  children = lbCfgOrdered.map(@(cfg) mkTab(cfg, curLbId.value == cfg.id, @() curLbId(cfg.id)))
}

function rewardsTimer() {
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

let header = @() {
  watch = hasBestBattles
  size = [flex(), lbHeaderHeight]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(40)
  children = [
    backButton(close)
    lbTabs
    { size = flex() }
    rewardsTimer
    !hasBestBattles.value ? null
      : mkCustomButton(
          {
            size = [lbTabIconSize, lbTabIconSize]
            rendObj = ROBJ_IMAGE
            image = Picture($"ui/gameuiskin#menu_stats.svg:{lbTabIconSize}:{lbTabIconSize}:P")
            keepAspect = true
          },
          @() isLbBestBattlesOpened(true),
          mergeStyles(PRIMARY,
          {
            ovr = { minWidth = defButtonHeight }
            hotkeys = ["^J:X | Enter"]
          }))
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

function mkRankCell(category, rowData) {
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

function mkNameCell(category, rowData) {
  let userId = rowData._id.tostring()
  let info = mkPublicInfo(userId)
  let realnick = category.getText(rowData)
  return function() {
    let { nickFrame = null } = info.get()?.decorators
    let visualName = frameNick(getPlayerName(realnick, myUserRealName.get(), myUserName.get()), nickFrame)
    let nameFont = isWidescreen || calc_str_box(visualName, fontTiny)[0] <= nameWidth
      ? fontTiny
      : fontVeryTiny
    return {
      watch = [info, myUserRealName, myUserName]
      key = userId
      size = [nameCellWidth, lbRowHeight]
      onAttach = @() refreshPublicInfo(userId)
      flow = FLOW_HORIZONTAL
      gap = nameGap
      valign = ALIGN_CENTER
      behavior = Behaviors.Button
      onClick = @() viewProfile(userId, { isInvitesAllowed = false })
      children = [
        contactAvatar(info.get(), lbRowHeight - hdpx(2))
        contactNameBlock({ realnick }, info.get(), [], { nameStyle = nameFont, titleStyle = fontVeryTiny })
      ]
    }
  }
}

function mkPrizeCell(category, rowData) {
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
      keepAspect = true
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
    color = 0x805B1D1D 
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

function lbTableFull(categories, lbData, selfRow) {
  let selfIdx = selfRow?.idx ?? -1
  let startIdx = lbData?[0].idx ?? -1
  let endIdx = lbData.reduce(@(res, row) max(res, row.idx), startIdx)

  let rows = lbData.map(@(row) mkRow(categories, row))
  let dotsRow = mkDotsRow(categories)
  local myRowIdx = selfIdx - max(startIdx, 0)
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

  return modalWndBg.__merge({
    key = categories
    size = [flex(), lbTableHeight]
    vplace = ALIGN_TOP
    flow = FLOW_VERTICAL
    children = [
       modalWndHeaderBg.__merge({
         size = [flex(), lbHeaderRowHeight]
         padding = lbTableBorderWidth
         flow = FLOW_HORIZONTAL
         valign = ALIGN_CENTER
         children = mkLbHeaderRow(categories, styleByCategory)
       })
       {
         size = flex()
         flow = FLOW_VERTICAL
         children = rowsChildren
       }
    ]
    animations = wndSwitchAnim
  })
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
      size = const [hdpx(1200), SIZE_TO_CONTENT]
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
  size = const [hdpx(1100), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  text
  color = defTxtColor
  animations = [spinnerOpacityAnim]
}.__update(fontSmall)

let lbRewardsWarning = {
  size = [lbRewardsBlockWidth, SIZE_TO_CONTENT]
  margin = hdpx(10)
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  text = loc("lb/warning/rewards")
  color = defTxtColor
}.__update(fontSmall)

function lbNoDataMsg() {
  let textsList = [loc("leaderboard/noLbData")]
  let count = minRatingBattles.value - bestBattlesCount.value
  if (count > 0)
    textsList.append(loc("lb/needMoreBattlesForLeaderboad", { count, countText = colorize(0xFFFFFFFF, count) }))
  return lbErrorMsg("\n\n".join(textsList))
    .__update({ watch = [minRatingBattles, bestBattlesCount] })
}

let content = @() {
  watch = [curLbCfg, curLbData, curLbSelfRow, isLbRequestInProgress, curLbErrName]
  size = flex()
  children = curLbCfg.value != null && (curLbData.value?.len() ?? 0) > 0
      ? lbTableFull(curLbCfg.value.categories, curLbData.value, curLbSelfRow.value)
    : isLbRequestInProgress.value ? waitLeaderBoard
    : curLbErrName.value == null ? lbNoDataMsg
    : lbErrorMsg(loc($"error/{curLbErrName.value}"))
}

let needPaginator = Computed(@() (curLbData.value?.len() ?? 0) != 0)
let paginator = @() {
  watch = needPaginator
  size = FLEX_H
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
        hasCurLbRewards.value ? lbRewardsBlock : lbRewardsWarning
      ]
    }
    paginator
  ]
  animations = wndSwitchAnim
})

registerScene("lbWnd", scene, close, isLbWndOpened)