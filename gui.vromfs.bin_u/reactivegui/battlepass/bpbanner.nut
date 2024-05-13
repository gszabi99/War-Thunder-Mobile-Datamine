from "%globalsDarg/darg_library.nut" import *
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let { openBattlePassWnd, isBpSeasonActive, hasBpRewardsToReceive } = require("battlePassState.nut")
let { framedImageBtn } = require("%rGui/components/imageButton.nut")
let { openEventWnd, eventSeason, unseenLootboxes, unseenLootboxesShowOnce, MAIN_EVENT_ID, isEventActive
} = require("%rGui/event/eventState.nut")
let { eventLootboxes } = require("%rGui/event/eventLootboxes.nut")
let { translucentButtonsHeight } = require("%rGui/components/translucentButton.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { getEventPresentation } = require("%appGlobals/config/eventSeasonPresentation.nut")

let bannerIconSize = [hdpxi(216), hdpxi(127)]
let buttonSize = [translucentButtonsHeight * 1.5, translucentButtonsHeight]
let horPadding = hdpx(80)

let mainEventBtn = framedImageBtn($"ui/gameuiskin#icon_events.svg",
  @() openEventWnd(),
  {
    size = buttonSize
    imageSize = [hdpx(70), hdpx(70)]
    sound = { click = "click" }
  },
  @() {
    watch = [unseenLootboxes, unseenLootboxesShowOnce, eventLootboxes]
    pos = [0.5 * buttonSize[0], -0.5 * buttonSize[1]]
    children = eventLootboxes.get().reduce(@(res, v) res || !!unseenLootboxes.get()?[MAIN_EVENT_ID][v.name], false)
      || unseenLootboxesShowOnce.get().findindex(@(v) v == MAIN_EVENT_ID) != null
          ? priorityUnseenMark
        : null
  })

return function () {
  let { color, image, imageOffset } = getEventPresentation(eventSeason.get())
  return {
    watch = [isBpSeasonActive, hasBpRewardsToReceive, isEventActive, eventSeason]
    size = [bannerIconSize[0] * 2, SIZE_TO_CONTENT]
    children = isBpSeasonActive.get()
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
              {
                flow = FLOW_HORIZONTAL
                gap = hdpx(40)
                children = [
                  isEventActive.get() ? mainEventBtn : null
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
    : isEventActive.get() ? mainEventBtn
    : null
  }
}
