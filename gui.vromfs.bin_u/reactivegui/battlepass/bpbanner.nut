from "%globalsDarg/darg_library.nut" import *
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let { openBattlePassWnd, bfFreeRewardsUnlock, hasBpRewardsToReceive } = require("battlePassState.nut")
let { framedImageBtn } = require("%rGui/components/imageButton.nut")
let { openEventWnd, eventWndShowAnimation, eventSeason, unseenLootboxes, unseenLootboxesShowOnce } = require("%rGui/event/eventState.nut")
let { translucentButtonsHeight } = require("%rGui/components/translucentButton.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")

let bannerIconSize = [hdpx(216), hdpx(127)]
let buttonSize = [translucentButtonsHeight * 1.5, translucentButtonsHeight]
let horPadding = hdpx(80)

return @() {
  watch = [bfFreeRewardsUnlock, hasBpRewardsToReceive]
  size = [bannerIconSize[0] * 1.5, SIZE_TO_CONTENT]
  children = bfFreeRewardsUnlock.get() != null
    ? {
        rendObj = ROBJ_9RECT
        image = gradTranspDoubleSideX
        texOffs = [0, gradDoubleTexOffset]
        screenOffs = [0, hdpx(300)]
        color = 0xA5000000
        padding = [hdpx(20), horPadding, hdpx(20), horPadding ]
        flow = FLOW_VERTICAL
        gap = hdpx(20)
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
                screenOffs = [0, hdpx(300)]
                color = 0xA5FF2B00
                pos = [0,  hdpx(-6)]
              }
              {
                size = bannerIconSize
                rendObj = ROBJ_IMAGE
                image = Picture($"ui/gameuiskin#banner_event_{eventSeason.value}.avif:{bannerIconSize[0]}:{bannerIconSize[1]}:P")
              }
            ]
          }
          {
            flow = FLOW_HORIZONTAL
            gap = hdpx(40)
            children = [
              framedImageBtn($"ui/gameuiskin#icon_events.svg",
                function() {
                  eventWndShowAnimation(true)
                  openEventWnd()
                },
                {
                  size = buttonSize
                  imageSize = [hdpx(70), hdpx(70)]
                  sound = { click = "click" }
                },
                @() {
                  watch = [unseenLootboxes, unseenLootboxesShowOnce]
                  pos = [0.5 * buttonSize[0], -0.5 * buttonSize[1]]
                  children = unseenLootboxes.value.len() > 0 || unseenLootboxesShowOnce.value.findindex(@(v) v) != null
                      ? priorityUnseenMark
                    : null
                }
                )
              framedImageBtn($"ui/gameuiskin#icon_bp.svg",
                openBattlePassWnd,
                {
                  size = buttonSize
                  sound = { click = "click" }
                },
                !hasBpRewardsToReceive.get() ? null
                  : priorityUnseenMark.__merge({ pos = [0.5 * buttonSize[0], -0.5 * buttonSize[1]] })
              )
            ]
          }
        ]
      }
    : null
}
