from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { getEventPresentation } = require("%appGlobals/config/eventSeasonPresentation.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let { eventSeason, eventSeasonIdx, MAIN_EVENT_ID } = require("%rGui/event/eventState.nut")
let { translucentButton, translucentButtonsVGap, translucentButtonsWidth } = require("%rGui/components/translucentButton.nut")
let { hoverColor } = require("%rGui/style/stdColors.nut")
let { openMainSeasonScene, LOOTBOX_TAB } = require("%rGui/seasonScene/seasonSceneState.nut")
let mkSeasonSceneUnseenMark = require("%rGui/seasonScene/mkSeasonSceneUnseenMark.nut")
let { tutorialQuestBtnKey } = require("%rGui/quests/questsState.nut")


let bannerBtnKey = "bp_banner_btn" 

let bannerIconSize = [hdpxi(184), hdpxi(108)]
let borderColor = 0xFFDEDEDE
let bannerWidth = translucentButtonsVGap * 2 + translucentButtonsWidth * 3
let textRowHeight = hdpx(30)
let bannerHeight = hdpx(20) + bannerIconSize[1] + textRowHeight

let mainEventBtn = @(unseenMark) translucentButton("ui/gameuiskin#icon_events.svg",
  @() openMainSeasonScene(LOOTBOX_TAB),
  null,
  @(_) unseenMark)

return @(isPassActive, isEventActive) function () {
  let { color, image, imageOffset } = getEventPresentation(eventSeason.get())
  let unseenMark = mkSeasonSceneUnseenMark(MAIN_EVENT_ID)
  let mainBtn = isEventActive ? mainEventBtn(unseenMark) : null
  let stateFlags = Watched(0)
  return {
    watch = eventSeason
    children = !isPassActive ? mainBtn
      : @() {
          watch = stateFlags
          key = bannerBtnKey
          onAttach = @() tutorialQuestBtnKey.set(bannerBtnKey)
          onDetach = @() tutorialQuestBtnKey.set(null)
          size = [bannerWidth, bannerHeight]
          sound = { click = "click" }
          rendObj = ROBJ_9RECT
          image = Picture($"ui/gameuiskin#gradient_btn_full.svg:{bannerWidth}:{bannerHeight}:P")
          texOffs = [bannerHeight / 2, bannerHeight / 2]
          screenOffs = [bannerHeight / 2, bannerHeight / 2]
          color = stateFlags.get() & S_HOVER ? hoverColor : borderColor
          onElemState = @(sf) stateFlags.set(sf)
          behavior = Behaviors.Button
          onClick = @() openMainSeasonScene(LOOTBOX_TAB)
          children = {
            size = [FLEX, SIZE_TO_CONTENT]
            rendObj = ROBJ_BOX
            valign = ALIGN_CENTER
            halign = ALIGN_CENTER
            flow = FLOW_VERTICAL
            padding = const [hdpx(10), hdpx(20), hdpx(10), hdpx(20)]
            children = [
              {
                size = [FLEX, bannerIconSize[1]]
                halign = ALIGN_CENTER
                valign = ALIGN_CENTER
                children = [
                  {
                    size = [FLEX, hdpx(75)]
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
                watch = eventSeasonIdx
                size = [SIZE_TO_CONTENT, textRowHeight]
                flow = FLOW_HORIZONTAL
                valign = ALIGN_CENTER
                gap = hdpx(10)
                children = [
                  {
                    rendObj = ROBJ_TEXT
                    color = 0xFFFFFFFF
                    text = utf8ToUpper(loc("events/seasonNumber", { number = eventSeasonIdx.get() }))
                  }.__update(fontBoldTinyShaded)
                  unseenMark
                ]
              }
            ]
          }
          transform = { scale = stateFlags.get() & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
          transitions = [{ prop = AnimProp.scale, duration = 0.15, easing = InOutQuad }]
        }
  }
}
