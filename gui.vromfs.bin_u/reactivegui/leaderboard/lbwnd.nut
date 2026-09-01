from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/decorators/nickFrames.nut" import frameNick
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/profileStates.nut" import myUserName, myUserRealName
from "%appGlobals/timeToText.nut" import secondsToHoursLoc, parseUnixTimeCached
from "%appGlobals/user/nickTools.nut" import getPlayerName
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/modalWnd.nut" import modalWndBg, modalWndHeaderBg
from "%rGui/components/paginator.nut" import mkPaginator
from "%rGui/components/playerPlaceIcon.nut" import mkPlaceIconSmall
from "%rGui/components/spinner.nut" import spinner, spinnerOpacityAnim
from "%rGui/components/textButton.nut" import mkCustomButton, buttonStyles, mergeStyles
from "%rGui/contacts/contactInfoPkg.nut" import contactNameBlock, contactAvatar
from "%rGui/contacts/contactPublicInfo.nut" import mkPublicInfo, refreshPublicInfo
from "%rGui/controls/tabs.nut" import mkTab
from "%rGui/event/eventState.nut" import isEventActive
from "%rGui/leaderboard/lbCategory.nut" import RANK, NAME, PRIZE
from "%rGui/leaderboard/lbConfig.nut" import lbCfgOrdered
import "%rGui/leaderboard/lbRewardsBlock.nut" as lbRewardsBlock
from "%rGui/leaderboard/lbRewardsState.nut" import hasCurLbRewards, curLbRewards, curLbTimeRange
from "%rGui/leaderboard/lbState.nut" import curLbId, curLbData, curLbSelfRow, curLbErrName, curLbCfg, isLbWndOpened,
  isRefreshLbEnabled, lbPage, lbMyPage, lbLastPage, lbTotalPlaces, isLbRequestInProgress, minRatingBattles,
  bestBattlesCount, hasBestBattles, isLbBestBattlesOpened
from "%rGui/leaderboard/lbStyle.nut" import lbHeaderHeight, lbTableHeight, lbVGap, lbHeaderRowHeight, lbRowHeight,
  lbDotsRowHeight, lbTableBorderWidth, lbPageRows, rowBgOddColor, rowBgEvenColor, prizeIcons, lbRewardsBlockWidth,
  lbTabIconSize
from "%rGui/leaderboard/mkLbHeaderRow.nut" import mkLbHeaderRow, headerIconHeight
from "%rGui/mpStatistics/viewProfile.nut" import viewProfile
from "%rGui/navState.nut" import registerScene
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/style/stdColors.nut" import localPlayerColor, selectColor
from "%rGui/unlocks/userstat.nut" import actualizeStats


let { COMMON, defButtonHeight } = buttonStyles

let rankCellWidth = lbHeaderRowHeight * (isWidescreen ? 2.5 : 2.0)
let nameWidth = calc_str_box("WWWWWWWWWWWWWWWWWW", isWidescreen ? fontTinyShaded : fontVeryTinyShaded)[0]
const nameGap = hdpx(10)
const premIconSize = hdpx(50)
let nameCellWidth = lbRowHeight + nameGap + nameWidth + premIconSize
const defTxtColor = 0xFFD8D8D8

let close = @() isLbWndOpened.set(false)

isEventActive.subscribe(function(isActive) {
  if (isActive)
    return
  isLbBestBattlesOpened.set(false)
  close()
})

let lbTabs = @() {
  watch = curLbId
  flow = FLOW_HORIZONTAL
  gap = hdpx(40)
  children = lbCfgOrdered.map(@(cfg) mkTab(cfg, curLbId.get() == cfg.id, @() curLbId.set(cfg.id)))
}

function rewardsTimer() {
  let { start = null, end = null } = curLbTimeRange.get()
  if (start == null && end == null)
    return { watch = curLbTimeRange }

  local locId = null
  local timeLeft = 0
  if (start != null) {
    let startTime = parseUnixTimeCached(start)
    if (startTime > serverTime.get()) {
      locId = "lb/seasonStartTime"
      timeLeft = startTime - serverTime.get()
    }
  }
  if (end != null && locId == null) {
    let endTime = parseUnixTimeCached(end)
    if (endTime > serverTime.get()) {
      locId = "lb/seasonEndTime"
      timeLeft = endTime - serverTime.get()
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
  size = [FLEX, lbHeaderHeight]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(40)
  children = [
    backButton(close)
    lbTabs
    { size = FLEX }
    rewardsTimer
    !hasBestBattles.get() ? null
      : mkCustomButton(
          {
            size = [lbTabIconSize, lbTabIconSize]
            rendObj = ROBJ_IMAGE
            image = Picture($"ui/gameuiskin#menu_stats.svg:{lbTabIconSize}:{lbTabIconSize}:P")
            keepAspect = true
          },
          @() isLbBestBattlesOpened.set(true),
          mergeStyles(COMMON,
          {
            ovr = { minWidth = defButtonHeight }
            hotkeys = ["^J:X | Enter"]
          }))
  ]
}

let styleByCategory = {
  [RANK] = { size = [rankCellWidth, SIZE_TO_CONTENT] },
  [NAME] = { size = [nameCellWidth, SIZE_TO_CONTENT] },
}

let mkLbCell = @(category, rowData) {
  size = [flex(category.relWidth), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXT
  color = rowData?.self ? localPlayerColor : defTxtColor
  halign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  text = category.getText(rowData)
}.__update(
  fontTinyShaded,
  styleByCategory?[category] ?? {})

function mkRankCell(category, rowData) {
  let value = category.getValue(rowData)
  if (value == null || value < 0 || value > 2)
    return mkLbCell(category, rowData)
  return {
    size = [rankCellWidth, FLEX]
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
      ? fontTinyShaded
      : fontVeryTinyShaded
    let nameStyle = (rowData?.self ? {color = localPlayerColor} : {}).__merge(nameFont)
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
        contactNameBlock({ realnick }, info.get(), [], { nameStyle, titleStyle = fontVeryTinyShaded })
      ]
    }
  }
}

function mkPrizeCell(category, rowData) {
  let place = rowData?.idx ?? -1
  let rewardIdx = Computed(function() {
    if (place < 0)
      return -1
    return curLbRewards.get().findindex(@(r) r.progress == -1 ? true
      : r.rType == "tillPlaces" ? r.progress > place
      : r.rType == "tillPercent" && lbTotalPlaces.get() > 0 ? r.progress >= 100.0 * place / lbTotalPlaces.get()
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
      image = rewardIdx.get() not in prizeIcons ? null
        : Picture($"ui/gameuiskin#{prizeIcons[rewardIdx.get()]}:{headerIconHeight}:{headerIconHeight}:P")
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

let flexGap = { size = FLEX }
let myRequirementsRow = @(emptyColor) function() {
  let res = {
    watch = [minRatingBattles, bestBattlesCount]
    size = [FLEX, lbRowHeight]
    rendObj = ROBJ_SOLID
    color = emptyColor
  }
  let count = minRatingBattles.get() - bestBattlesCount.get()
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
        text = "/".concat(colorize(0xFFFFFFFF, bestBattlesCount.get()), minRatingBattles.get())
        color = defTxtColor
      }.__update(fontTiny)
      flexGap
    ]
  })
}

function lbTableFull(categories, lbData, selfRow, hasRewards) {
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
  else if (hasRewards) {
    rows.append(dotsRow)
    needRequirementsRow = true
  }

  let rowsChildren = rows.map(@(children, idx) {
    size = [FLEX, children == dotsRow ? lbDotsRowHeight : lbRowHeight]
    rendObj = ROBJ_BOX
    fillColor = (idx % 2) ? rowBgOddColor : rowBgEvenColor
    flow = FLOW_HORIZONTAL
    borderColor = selectColor
    borderWidth = [0, 0, 0, myRowIdx == idx ? hdpx(4) : 0]
    children
  })

  if (needRequirementsRow)
    rowsChildren.append(myRequirementsRow((rowsChildren.len() % 2) ? rowBgOddColor : rowBgEvenColor))

  if (rowsChildren.len() < lbPageRows + 2)
    rowsChildren.append({
      size = FLEX
      rendObj = ROBJ_SOLID
      color = (rowsChildren.len() % 2) ? rowBgOddColor : rowBgEvenColor
    })

  return modalWndBg.__merge({
    key = categories
    size = [FLEX, lbTableHeight]
    vplace = ALIGN_TOP
    flow = FLOW_VERTICAL
    children = [
       modalWndHeaderBg.__merge({
         size = [FLEX, lbHeaderRowHeight]
         padding = lbTableBorderWidth
         flow = FLOW_HORIZONTAL
         valign = ALIGN_CENTER
         children = mkLbHeaderRow(categories, styleByCategory)
       })
       {
         size = FLEX
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
  let count = minRatingBattles.get() - bestBattlesCount.get()
  if (count > 0)
    textsList.append(loc("lb/needMoreBattlesForLeaderboad", { count, countText = colorize(0xFFFFFFFF, count) }))
  return lbErrorMsg("\n\n".join(textsList))
    .__update({ watch = [minRatingBattles, bestBattlesCount] })
}

let content = @(hasRewards) @() {
  watch = [curLbCfg, curLbData, curLbSelfRow, isLbRequestInProgress, curLbErrName]
  size = FLEX
  children = curLbCfg.get() != null && (curLbData.get()?.len() ?? 0) > 0
      ? lbTableFull(curLbCfg.get().categories, curLbData.get(), curLbSelfRow.get(), hasRewards)
    : isLbRequestInProgress.get() ? waitLeaderBoard
    : curLbErrName.get() == null ? lbNoDataMsg
    : lbErrorMsg(loc($"error/{curLbErrName.get()}"))
}

let needPaginator = Computed(@() (curLbData.get()?.len() ?? 0) != 0)
let paginator = @() {
  watch = needPaginator
  size = FLEX_H
  children = !needPaginator.get() ? null
    : mkPaginator(lbPage, lbLastPage, lbMyPage, { key = needPaginator, animations = wndSwitchAnim })
}

let scene = bgShaded.__merge({
  key = {}
  size = FLEX
  padding = saBordersRv

  function onAttach() {
    lbPage.set(0)
    isRefreshLbEnabled.set(true)
    actualizeStats()
    if (curLbId.get() == null)
      curLbId.set(lbCfgOrdered.findvalue(@(c) c?.campaign == curCampaign.get())?.id
        ?? lbCfgOrdered.findvalue(@(_) true)?.id)
  }
  onDetach = @() isRefreshLbEnabled.set(false)

  flow = FLOW_VERTICAL
  gap = lbVGap
  children = [
    header
    @() {
      watch = hasCurLbRewards
      size = FLEX
      flow = FLOW_HORIZONTAL
      gap = lbVGap
      children = [
        content(hasCurLbRewards.get())
        hasCurLbRewards.get() ? lbRewardsBlock : lbRewardsWarning
      ]
    }
    paginator
  ]
  animations = wndSwitchAnim
})

registerScene("lbWnd", scene, close, isLbWndOpened)