from "%globalsDarg/darg_library.nut" import *
let { getEventPresentation } = require("%appGlobals/config/eventSeasonPresentation.nut")
let { getOPPresentation } = require("%appGlobals/config/passPresentation.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let { seenPasses, isPassGoodsUnseen } = require("%rGui/battlePass/passState.nut")
let { hasBpRewardsToReceive, battlePassGoods } = require("%rGui/battlePass/battlePassState.nut")
let { isOPSeasonActive, hasOPRewardsToReceive, operationPassGoods, OPCampaign } = require("%rGui/battlePass/operationPassState.nut")
let { hasAnyEpRewardsToReceive, allEventPassGoods } = require("%rGui/battlePass/eventPassState.nut")
let { openEventWnd, eventSeason, unseenLootboxes, unseenLootboxesShowOnce, MAIN_EVENT_ID,
} = require("%rGui/event/eventState.nut")
let { eventLootboxes } = require("%rGui/event/eventLootboxes.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { openPassScene, BATTLE_PASS, OPERATION_PASS } = require("passState.nut")
let { translucentButton, translucentButtonsVGap } = require("%rGui/components/translucentButton.nut")
let { addUnlocksUpdater, removeUnlocksUpdater } = require("%rGui/unlocks/userstat.nut")


let bannerIconSize = [hdpxi(216), hdpxi(127)]
let horPadding = hdpx(80)
let bpBannerStatusKey = "bpBannerStatusKey"
let opBannerStatusKey = "opBannerStatusKey"

let mainEventBtn = translucentButton("ui/gameuiskin#icon_events.svg", "",
  @() openEventWnd(),
  @(_) @() {
    watch = [unseenLootboxes, unseenLootboxesShowOnce, eventLootboxes]
    children = eventLootboxes.get().reduce(@(res, v) res || !!unseenLootboxes.get()?[MAIN_EVENT_ID][v.name], false)
      || unseenLootboxesShowOnce.get().findindex(@(v) v == MAIN_EVENT_ID) != null
          ? priorityUnseenMark
        : null
})

let hasAnyPassRewards = Computed(@() hasBpRewardsToReceive.get() || hasOPRewardsToReceive.get() || hasAnyEpRewardsToReceive.get())

let hasUnseenOP = Computed(@() isPassGoodsUnseen(operationPassGoods.get(), seenPasses.get()))
let hasAnyUnseenPass = Computed(@() isPassGoodsUnseen(battlePassGoods.get(), seenPasses.get())
  || hasUnseenOP.get()
  || null != allEventPassGoods.get().findindex(@(v) isPassGoodsUnseen(v, seenPasses.get())))

return @(isPassActive, isEventActive) function () {
  let { color, image, imageOffset } = getEventPresentation(eventSeason.get())
  let mainBtn = isEventActive ? mainEventBtn : null
  return {
    watch = eventSeason
    size = [bannerIconSize[0] * 2, SIZE_TO_CONTENT]
    pos = [-hdpx(22), 0]
    children = !isPassActive ? mainBtn
      : {
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
              watch = [OPCampaign, isOPSeasonActive]
              flow = FLOW_HORIZONTAL
              gap = translucentButtonsVGap
              children = [
                mainBtn
                translucentButton("ui/gameuiskin#icon_bp.svg",
                  "",
                  @() openPassScene(BATTLE_PASS),
                  @(_) @() {
                    watch = [hasAnyPassRewards, hasAnyUnseenPass]
                    key = bpBannerStatusKey
                    onAttach = @() addUnlocksUpdater(bpBannerStatusKey)
                    onDetach = @() removeUnlocksUpdater(bpBannerStatusKey)
                    children = !hasAnyPassRewards.get() && !hasAnyUnseenPass.get() ? null
                      : priorityUnseenMark
                  })
                !isOPSeasonActive.get() || OPCampaign.get() == null ? null
                  : translucentButton(getOPPresentation(OPCampaign.get()).iconTab,
                      "",
                      @() openPassScene(OPERATION_PASS),
                      @(_) @() {
                        watch = [hasOPRewardsToReceive, hasUnseenOP]
                        key = opBannerStatusKey
                        onAttach = @() addUnlocksUpdater(opBannerStatusKey)
                        onDetach = @() removeUnlocksUpdater(opBannerStatusKey)
                        children = !hasOPRewardsToReceive.get() && !hasUnseenOP.get() ? null
                          : priorityUnseenMark
                      })
              ]
            }
          ]
        }
  }
}
