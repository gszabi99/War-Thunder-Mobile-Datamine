from "%globalsDarg/darg_library.nut" import *
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")

let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { lbRewardsBlockWidth, lbTableHeight, lbHeaderRowHeight, prizeIcons,
  rewardStyle, lbRewardRowPadding, lbRewardsGap, rowBgOddColor, rowBgEvenColor
} = require("%rGui/leaderboard/lbStyle.nut")
let { localPlayerColor } = require("%rGui/style/stdColors.nut")
let { curLbRewards } = require("%rGui/leaderboard/lbRewardsState.nut")
let { lbMyPlace, lbTotalPlaces, curLbCfg, curLbData } = require("%rGui/leaderboard/lbState.nut")
let { getRewardsViewInfo, sortRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { mkRewardsPreview } = require("%rGui/quests/rewardsComps.nut")
let { infoTooltipButton } = require("%rGui/components/infoButton.nut")
let { modalWndBg, modalWndHeaderBg } = require("%rGui/components/modalWnd.nut")
let { boxSize } = rewardStyle
let { withTooltip, tooltipDetach } = require("%rGui/tooltip.nut")
let { round } =  require("math")
let { contactsRequest, contactsRegisterHandler } = require("%rGui/contacts/contactsClient.nut")
let { curLbRequestData } = require("lbStateBase.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let { spinner } = require("%rGui/components/spinner.nut")

let reqPoints = Watched(null)
let requestDataPlayer = Watched(null)
requestDataPlayer.subscribe(@(_) reqPoints.set(null) )
let isRequestInProgress = Watched(false)

let prizeTextSlots = 2
let defTxtColor = 0xFFD8D8D8
let prizeIconSize = evenPx(60)
let MAX_REWARDS_SLOTS_COUNT = 3
let prizeTooltipSize = [hdpx(400), SIZE_TO_CONTENT]

function mkIsReady(rewardInfo) {
  let { rType, progress } = rewardInfo
  return Computed(@() lbMyPlace.get() <= 0 ? false
    : progress == -1 ? true
    : rType == "tillPlaces" ? progress >= lbMyPlace.get()
    : rType == "tillPercent" && lbTotalPlaces.get() > 0 ? progress >= 100.0 * (lbMyPlace.get() - 1) / lbTotalPlaces.get()
    : false)
}

function requestPlayerForPlacePoints(place) {
  if (curLbRequestData.get() == null || isRequestInProgress.get())
    return
  let requestData = curLbRequestData.get().__merge({ count = 1, start = place - 1})
  requestDataPlayer.set(requestData)
  isRequestInProgress.set(true)
  contactsRequest("cln_get_leaderboard_json:playerInfo", { data = requestData }, requestData)
}

contactsRegisterHandler("cln_get_leaderboard_json:playerInfo", function(result, requestData) {
  isRequestInProgress.set(false)
  if(!isEqual(requestData, requestDataPlayer.get())) {
    requestPlayerForPlacePoints(requestData.start + 1)
    return
  }
  let readyPoints = curLbCfg.get().battleCategories
    .findvalue(@(v) v.dataType.id == "RATING")?.getText(result.findvalue(@(_) true)) ?? 0
  reqPoints.set(readyPoints)
})

let mkPlaceTooltipContent = @(rewardInfo) function() {
  local res = ""
  local place = 0
  let { rType, progress } = rewardInfo
  if (rType == "tillPlaces") {
    place = progress
    res = loc("lb/rewards/rPlace", { place = progress })
  }
  if (rType == "tillPercent" && lbTotalPlaces.get() > 0) {
    place = round(lbTotalPlaces.get() * (progress / 100.0)).tointeger()
    res = "\n".concat(loc("lb/rewards/place/desc"),
      loc("lb/rewards/rPlace", { place }))
  }
  return {
    watch = [isRequestInProgress, lbTotalPlaces]
    size = prizeTooltipSize
    onAttach = @() requestPlayerForPlacePoints(place)
    flow = FLOW_VERTICAL
    children = [
      {
        size = prizeTooltipSize
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = res
      }.__update(fontTinyAccented)
      isRequestInProgress.get() ? spinner :
        @() {
          watch = reqPoints
          size = prizeTooltipSize
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = !reqPoints.get() ? null : loc("lb/rewards/rPoints", { points = reqPoints.get()})
        }.__update(fontTinyAccented)
    ]
  }
}

function mkPrizeInfo(rType, progress, idx, isReady) {
  let stateFlags = Watched(0)
  let key = {}
  let imgBase = {
    size = [prizeIconSize, prizeIconSize]
    rendObj = ROBJ_IMAGE
    keepAspect = true
    image = idx not in prizeIcons ? null
      : Picture($"ui/gameuiskin#{prizeIcons[idx]}:{prizeIconSize}:{prizeIconSize}:P")
  }
  let isPrizeForAny = progress == -1 || (progress >= 100 && rType == "tillPercent")
  return {
    size = [prizeTextSlots * boxSize, SIZE_TO_CONTENT]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    children = [
      isPrizeForAny ? imgBase
        : @() imgBase.__merge({
            key
            watch = stateFlags
            behavior = Behaviors.Button
            onElemState = withTooltip(stateFlags, key,
              @() (curLbData.get()?.len() ?? 0) == 0 ? null
                : {
                  content = mkPlaceTooltipContent({rType, progress}),
                  halign = ALIGN_LEFT,
                  flow = FLOW_HORIZONTAL
                })
            onDetach = tooltipDetach(stateFlags)
            transform = { scale = stateFlags.get() & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
          })
      @() {
        watch = isReady
        size = FLEX_H
        rendObj = ROBJ_TEXT
        behavior = Behaviors.Marquee
        speed = hdpx(30)
        delay = defMarqueeDelay
        halign = ALIGN_CENTER
        text = isPrizeForAny ? loc("lb/condition/any")
          : loc("lb/condition/topN", { value = rType == "tillPercent" ? $"{progress}%" : progress })
        color = isReady.get() ? localPlayerColor : defTxtColor
      }.__update(fontTiny)
    ]
  }
}

function mkRewardRow(rewardInfo, idx) {
  let { rType, progress, rewards } = rewardInfo
  local rewardsViewInfo = []
  foreach (id, count in rewards) {
    let reward = serverConfigs.get()?.userstatRewards[id]
    rewardsViewInfo.extend(getRewardsViewInfo(reward, count))
  }
  rewardsViewInfo = rewardsViewInfo.filter(@(r) r.rType != "medal")
  rewardsViewInfo.sort(sortRewardsViewInfo)

  let isReady = mkIsReady(rewardInfo)

  return {
    size = flex()
    maxHeight = boxSize + lbRewardRowPadding * 2
    padding = lbRewardRowPadding
    rendObj = ROBJ_SOLID
    color = (idx % 2) ? rowBgOddColor : rowBgEvenColor
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      mkPrizeInfo(rType, progress, idx, isReady)
      {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        halign = ALIGN_RIGHT
        gap = lbRewardsGap
        children = mkRewardsPreview(rewardsViewInfo, false, MAX_REWARDS_SLOTS_COUNT, rewardStyle)
      }
    ]
  }
}

return modalWndBg.__merge({
  size = [lbRewardsBlockWidth, lbTableHeight]
  key = {}
  vplace = ALIGN_TOP
  flow = FLOW_VERTICAL
  children = [
    modalWndHeaderBg.__merge({
      size = [flex(), lbHeaderRowHeight]
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      gap = hdpx(10)
      children = [
        {
          rendObj = ROBJ_TEXT
          text = loc("lb/seasonRewards")
          color = 0xFFD8D8D8
        }.__update(fontTiny)
        infoTooltipButton(@() loc("lb/seasonRewards/desc"), { halign = ALIGN_LEFT })
      ]
    })
    @() {
      watch = curLbRewards
      size = flex()
      flow = FLOW_VERTICAL
      children = curLbRewards.get().map(mkRewardRow)
    }
  ]
  animations = wndSwitchAnim
})
