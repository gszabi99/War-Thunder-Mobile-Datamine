from "%globalsDarg/darg_library.nut" import *
from "math" import round, ceil
from "eventbus" import eventbus_subscribe
from "%appGlobals/clientState/clientState.nut" import isInBattle
from "%rGui/missionState.nut" import isGtBattleRoyale
from "%rGui/style/gradients.nut" import simpleVerGrad

let isPlayerOutOfMap = mkWatched(persist, "isPlayerOutOfMap", false)
isInBattle.subscribe(@(_) isPlayerOutOfMap.set(false))
eventbus_subscribe("onShowReturnToMapMessage", @(data) isPlayerOutOfMap.set(data.showMessage))

let needVignetteOutOfMap = Computed(@() isGtBattleRoyale.get() && isPlayerOutOfMap.get())

const stripeColor = 0xDDE15403
const gradColor = 0x94973802
const dangerLineScrollTime = 0.5
const dangerLineFadeTime = 0.2

const dangerLineH = hdpxi(100)
const stripeImgH = dangerLineH
let stripeImgW = round(stripeImgH / 805.0 * 609).tointeger()
let stripeImgGap = round(dangerLineH * 0.56).tointeger()

let stripeW = stripeImgW + stripeImgGap
let stripesTotal = ceil(sw(100) / stripeW).tointeger() + 1

let stripeImg = {
  size = static [stripeImgW, stripeImgH]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin/danger_line_mask.svg:{stripeImgW}:{stripeImgH}:P")
  keepAspect = true
  imageValign = ALIGN_BOTTOM
  color = stripeColor
  transform = { rotate = 180 }
}

let childFadeOutAnim = { prop = AnimProp.opacity, from = 1, to = 1,
  duration = dangerLineFadeTime, playFadeOut = true }

let mkDangerLine = @(isTop) {
  size = const [flex(), dangerLineH]
  vplace = isTop ? ALIGN_TOP : ALIGN_BOTTOM
  rendObj = ROBJ_IMAGE
  image = simpleVerGrad
  color = gradColor
  transform = isTop ? {} : { rotate = 180 }
  animations = [
    { prop = AnimProp.translate, from = [0, dangerLineH * (isTop ? -1 : 1)], to = [0, 0],
      duration = dangerLineFadeTime, easing = OutQuad, play = true }
    { prop = AnimProp.translate, from = [0, 0], to = [0, dangerLineH * (isTop ? -1 : 1)],
      duration = dangerLineFadeTime, easing = OutQuad, playFadeOut = true }
  ]
  children = {
    size = static [stripesTotal * stripeW, dangerLineH]
    flow = FLOW_HORIZONTAL
    gap = stripeImgGap
    transform = {}
    animations = [
      { prop = AnimProp.translate, from = [-stripeW, 0], to = [0, 0],
        duration = dangerLineScrollTime, play = true, loop = true }
      childFadeOutAnim
    ]
    children = array(stripesTotal, stripeImg)
  }
}

let vignetteOutOfMap = {
  size = flex()
  children = [
    mkDangerLine(true)
    mkDangerLine(false)
  ]
}

let hudVignette = @() {
  watch = needVignetteOutOfMap
  key = needVignetteOutOfMap
  size = const [sw(100), sh(100)]
  children = needVignetteOutOfMap.get() ? vignetteOutOfMap : null
}

return hudVignette
