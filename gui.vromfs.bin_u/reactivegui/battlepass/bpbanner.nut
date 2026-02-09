from "%globalsDarg/darg_library.nut" import *
let { getEventPresentation } = require("%appGlobals/config/eventSeasonPresentation.nut")
let { getOPPresentation } = require("%appGlobals/config/passPresentation.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let { seenPasses, isPassGoodsUnseen } = require("%rGui/battlePass/passState.nut")
let { isBpSeasonActive, hasBpRewardsToReceive, battlePassGoods } = require("%rGui/battlePass/battlePassState.nut")
let { isOPSeasonActive, hasOPRewardsToReceive, operationPassGoods, OPCampaign } = require("%rGui/battlePass/operationPassState.nut")
let { isEpSeasonActive, hasEpRewardsToReceive, eventPassGoods } = require("%rGui/battlePass/eventPassState.nut")
let { openEventWnd, eventSeason, unseenLootboxes, unseenLootboxesShowOnce, MAIN_EVENT_ID, isEventActive,
  isFitSeasonRewardsRequirements
} = require("%rGui/event/eventState.nut")
let { eventLootboxes } = require("%rGui/event/eventLootboxes.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { openPassScene, BATTLE_PASS, OPERATION_PASS } = require("passState.nut")
let { translucentButton, translucentButtonsVGap } = require("%rGui/components/translucentButton.nut")


let bannerIconSize = [hdpxi(216), hdpxi(127)]
let horPadding = hdpx(80)

let mainEventBtn = translucentButton("ui/gameuiskin#icon_events.svg", "",
  @() openEventWnd(),
  @(_) @() {
    watch = [unseenLootboxes, unseenLootboxesShowOnce, eventLootboxes]
    children = eventLootboxes.get().reduce(@(res, v) res || !!unseenLootboxes.get()?[MAIN_EVENT_ID][v.name], false)
      || unseenLootboxesShowOnce.get().findindex(@(v) v == MAIN_EVENT_ID) != null
          ? priorityUnseenMark
        : null
})

let isPassActive = Computed(@() isBpSeasonActive.get() || isOPSeasonActive.get() || isEpSeasonActive.get())
let hasAnyPassRewards = Computed(@() hasBpRewardsToReceive.get() || hasOPRewardsToReceive.get() || hasEpRewardsToReceive.get())

let hasUnseenOP = Computed(@() isPassGoodsUnseen(operationPassGoods.get(), seenPasses.get()))
let hasAnyUnseenPass = Computed(@() isPassGoodsUnseen(battlePassGoods.get(), seenPasses.get())
  || hasUnseenOP.get()
  || isPassGoodsUnseen(eventPassGoods.get(), seenPasses.get()))

return function () {
  let { color, image, imageOffset } = getEventPresentation(eventSeason.get())
  return {
    watch = [isPassActive, isEventActive, eventSeason, isFitSeasonRewardsRequirements]
    size = [bannerIconSize[0] * 2, SIZE_TO_CONTENT]
    pos = [-hdpx(22), 0]
    children = !isFitSeasonRewardsRequirements.get() ? null
      : isPassActive.get()
        ? {
            rendObj = ROBJ_9RECT
            image = gradTranspDoubleSideX
            texOffs = [0, gradDoubleTexOffset]
            screenOffs = [0, hdpx(130)]
            color = 0x90000000
            padding = [hdpx(20), horPadding, hdpx(20), horPadding ]
            flow = FLOW_VERTICAL
            gap = hdpx(10)
            halign = ALIGN_CENTER
            hplace = ALIGN_CENTER
            children = [
              {
                size = [flex(), bannerIconSize[1]]
                halign = ALIGN_CENTER
                valign = ALIGN_CENTER
                children = [
                  {
                    size = [bannerIconSize[0] * 1.5 + horPadding * 2, hdpx(75)]
                    rendObj = ROBJ_9RECT
                    image = gradTranspDoubleSideX
                    texOffs = [0, gradDoubleTexOffset]
                    screenOffs = [0, hdpx(130)]
                    color
                  }
                  {
                    size = bannerIconSize
                    rendObj = ROBJ_IMAGE
                    keepAspect = true
                    pos = imageOffset.map(@(pos, idx) pos * bannerIconSize[idx])
                    image = Picture($"{image}:{bannerIconSize[0]}:{bannerIconSize[1]}:P")
                  }
                ]
              }
              @() {
                watch = [isEventActive, OPCampaign, isOPSeasonActive]
                flow = FLOW_HORIZONTAL
                gap = translucentButtonsVGap
                children = [
                  isEventActive.get() ? mainEventBtn : null
                  translucentButton("ui/gameuiskin#icon_bp.svg",
                    "",
                    @() openPassScene(BATTLE_PASS),
                    @(_) @() {
                      watch = [hasAnyPassRewards, hasAnyUnseenPass]
                      children = !hasAnyPassRewards.get() && !hasAnyUnseenPass.get() ? null
                        : priorityUnseenMark
                    })
                  !isOPSeasonActive.get() || OPCampaign.get() == null ? null
                    : translucentButton(getOPPresentation(OPCampaign.get()).iconTab,
                        "",
                        @() openPassScene(OPERATION_PASS),
                        @(_) @() {
                          watch = [hasOPRewardsToReceive, hasUnseenOP]
                          children = !hasOPRewardsToReceive.get() && !hasUnseenOP.get() ? null
                            : priorityUnseenMark
                        })
                ]
              }
            ]
          }
      : isEventActive.get() ? mainEventBtn
      : null
  }
}
