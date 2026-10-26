from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/config/eventSeasonPresentation.nut" import getEventPresentation
from "%rGui/components/translucentButton.nut" import translucentButton, translucentButtonsVGap, translucentButtonsWidth
from "%rGui/event/eventState.nut" import eventSeason, eventSeasonIdx, MAIN_EVENT_ID
from "%rGui/quests/questsState.nut" import tutorialQuestBtnKey
import "%rGui/seasonScene/mkSeasonSceneUnseenMark.nut" as mkSeasonSceneUnseenMark
from "%rGui/seasonScene/seasonSceneState.nut" import openMainSeasonScene
from "%rGui/style/gradients.nut" import gradTranspDoubleSideX, gradDoubleTexOffset
from "%rGui/style/stdColors.nut" import hoverColor
from "%rGui/style/stdAnimations.nut" import mkPressTransitionScale


const bannerBtnKey = "bp_banner_btn" 

let bannerIconSize = [hdpxi(184), hdpxi(108)]
const borderColor = 0xFFDEDEDE
let bannerWidth = translucentButtonsVGap * 2 + translucentButtonsWidth * 3
const textRowHeight = hdpx(30)
let bannerHeight = hdpx(20) + bannerIconSize[1] + textRowHeight

let mainEventBtn = @(unseenMark) translucentButton("ui/gameuiskin#icon_events.svg",
  @() openMainSeasonScene(),
  null,
  @(_) unseenMark)

function mkBpBanner(isPassActive, isEventActive) {
  let stateFlags = Watched(0)
  let unseenMark = mkSeasonSceneUnseenMark(MAIN_EVENT_ID)
  let mainBtn = isEventActive ? mainEventBtn(unseenMark) : null
  let bannerImage = Picture($"ui/gameuiskin#gradient_btn_full.svg:{bannerWidth}:{bannerHeight}:P")
  let seasonMark = {
    pos = const [hdpx(10), 0]
    size = 0
    hplace = ALIGN_RIGHT
    valign = ALIGN_CENTER
    children = unseenMark
  }
  return function () {
    let { color, image, imageOffset } = getEventPresentation(eventSeason.get())
    let bannerContent = {
      size = const [FLEX, SIZE_TO_CONTENT]
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
              size = const [FLEX, hdpx(75)]
              rendObj = ROBJ_9RECT
              image = gradTranspDoubleSideX
              texOffs = [0, gradDoubleTexOffset]
              screenOffs = const [0, hdpx(130)]
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
          size = const [SIZE_TO_CONTENT, textRowHeight]
          valign = ALIGN_CENTER
          children = eventSeasonIdx.get() < 0 ? null
            : [
                {
                  rendObj = ROBJ_TEXT
                  color = 0xFFFFFFFF
                  text = utf8ToUpper(loc("events/seasonNumber", { number = eventSeasonIdx.get() }))
                }.__update(fontBoldTinyShaded)
                seasonMark
              ]
        }
      ]
    }
    return {
      watch = eventSeason
      children = !isPassActive ? mainBtn
        : @() {
            watch = stateFlags
            key = bannerBtnKey
            onAttach = @() tutorialQuestBtnKey.set(bannerBtnKey)
            onDetach = @() tutorialQuestBtnKey.set(null)
            size = [bannerWidth, bannerHeight]
            sound = const { click = "click" }
            rendObj = ROBJ_9RECT
            image = bannerImage
            texOffs = [bannerHeight / 2, bannerHeight / 2]
            screenOffs = [bannerHeight / 2, bannerHeight / 2]
            color = stateFlags.get() & S_HOVER ? hoverColor : borderColor
            onElemState = @(sf) stateFlags.set(sf)
            behavior = Behaviors.Button
            onClick = @() openMainSeasonScene()
            children = bannerContent
            ...mkPressTransitionScale(stateFlags.get(), 0.9)
          }
    }
  }
}

return mkBpBanner
