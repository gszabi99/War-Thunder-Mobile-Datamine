from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { hide_unit, show_unit, start_fx_on_unit,
  enable_scene_camera, disable_scene_camera, reset_camera_pos_dir,
} = require("hangar")
let { setTimeout, resetTimeout } = require("dagor.workcycle")
let { sin, cos, asin, PI, ceil } = require("math")
let { registerScene, scenesOrder } = require("%rGui/navState.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { isInMenu } = require("%appGlobals/clientState/clientState.nut")
let { hangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { gradRadial, gradCircCornerOffset } = require("%rGui/style/gradients.nut")
let mkBehindSceneEmitter = require("%rGui/effects/mkBehindSceneEmitter.nut")
let mkSparkStarMoveOut = require("%rGui/effects/mkSparkStarMoveOut.nut")
let { playSound } = require("sound_wt")
let { Point3 } = require("dagor.math")
let { TANK } = require("%appGlobals/unitConst.nut")
let { getUnitType } = require("%appGlobals/unitTags.nut")


let unitToShow = mkWatched(persist, "unit", null)
let hasLvlUpScene = Computed(@() scenesOrder.value.findindex(@(v) v == "levelUpWnd") != null)
let isOpened = Computed(@() isInMenu.value && !hasModalWindows.value
  && unitToShow.value != null && !hasLvlUpScene.value)
let close = @() unitToShow(null)

let BASE_DELAY = 0.2

let aTimeShow = 0.2
let aTimeIncStart = BASE_DELAY + aTimeShow
let aTimeInc = 0.4
let aTimeDecStart = aTimeIncStart + aTimeInc
let aTimeDec = 0.2
let aTimeHideStart = aTimeDecStart + aTimeDec
let aTimeHide = 0.8
let aTimeExplosionOffset = 0.05
let aTimeSideGlowAppear = 0.1
let aTimeSideGlowExplosionHide = 0.2
let aTimeFullEffect = aTimeHideStart + aTimeHide

let midExplRotate1 = 140.0
let midExplRotate2 = -60.0
let sideExplRotate = 100.0

let horizonRadius = hdpx(10000)
let horizonLineSize = [hdpx(600), hdpx(80)]
let horizonLineOffsetX = hdpx(80)

let fxColors = {
  common = 0x006290BF
  premium = 0x00FFAD49
}
let getFxColor = @(unit) unit?.isUpgraded || unit?.isPremium ? fxColors.premium : fxColors.common
let getPurchaseSound = @() unitToShow.value?.isUpgraded || unitToShow.value?.isPremium ? "unit_buy_prem" : "unit_buy"

let startStarsFx = @() mkBehindSceneEmitter({ lifeTime = aTimeFullEffect, count = 50,
  sparkCtor = mkSparkStarMoveOut(getFxColor(unitToShow.value)) })

let opacityAnims = @(delay, appearTime, duration, hideTime, onFinish = null) [
  { prop = AnimProp.opacity, from = 0.0, to = 1.0, easing = InQuad, play = true,
    duration = appearTime, delay }
  { prop = AnimProp.opacity, from = 1.0, to = 1.0, play = true,
    duration, delay = delay + appearTime }
  { prop = AnimProp.opacity, from = 1.0, to = 0.0, easing = InQuad, play = true,
    duration = hideTime, delay = delay + appearTime + duration, onFinish }
]

let horizonAngle = 2.0 * asin(0.5 * (horizonLineSize[0] + horizonLineOffsetX) / horizonRadius)
let angleToFill = sw(100) >= horizonRadius * 2 ? PI : 2.0 * asin(0.5 * sw(100) / horizonRadius)
let count = 2 * ceil((angleToFill / horizonAngle) / 2).tointeger()
let angleStart = horizonAngle * (0.5 - count / 2)

function mkHorizonLine(idx, color, halfColor) {
  let a = angleStart + idx * horizonAngle
  return {
    size = horizonLineSize
    rendObj = ROBJ_9RECT
    image = gradRadial
    texOffs = [gradCircCornerOffset, gradCircCornerOffset]
    screenOffs = array(2, hdpx(120))
    color = 0
    transform = {
      rotate = 180.0 / PI * a
      translate = [horizonRadius * sin(a), horizonRadius * (1.0 - cos(a))]
    }
    animations = [
      //color
      { prop = AnimProp.color, from = 0, to = halfColor, easing = OutQuad, play = true,
        duration = aTimeShow + 0.5 * aTimeInc, delay = BASE_DELAY }
      { prop = AnimProp.color, from = halfColor, to = color, easing = InQuad, play = true,
        duration = 0.5 * aTimeInc, delay = aTimeIncStart + 0.5 * aTimeInc }
      { prop = AnimProp.color, from = color, to = color, play = true,
        duration = 0.5 * aTimeDec, delay = aTimeDecStart }
      { prop = AnimProp.color, from = color, to = 0, easing = InQuad, play = true,
        duration = 0.5 * aTimeDec + 0.5 * aTimeHide, delay = aTimeHideStart - 0.5 * aTimeDec }
      //scale
      { prop = AnimProp.scale, to = [1.3, 1.3], play = true, easing = InOutQuad,
        duration = aTimeShow + aTimeInc, delay = BASE_DELAY }
      { prop = AnimProp.scale, from = [1.3, 1.3], to = [0.15, 0.15], play = true, easing = InQuad,
        duration = aTimeDec + aTimeHide, delay = aTimeHideStart - aTimeDec }
    ]
  }
}

function horizonLines(color) {
  let halfColor = mul_color(color, 0.5)
  return {
    size = flex()
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = array(count).map(@(_, idx) mkHorizonLine(idx, color, halfColor))
  }
}

let midFlare = @(color) {
  size = array(2, hdpx(1500))
  rendObj = ROBJ_IMAGE
  image = Picture("ui/images/effects/misc_expl_glow_a.avif:0:P")
  color
  opacity = 0
  transform = {}
  animations = opacityAnims(BASE_DELAY, aTimeShow, aTimeInc + aTimeDec, aTimeHide, close)
    .append(
      { prop = AnimProp.scale, from = [0.5, 0.5], to = [1.0, 1.0], play = true, easing = InQuad,
        duration = aTimeShow, delay = BASE_DELAY,
        function onFinish() {
          startStarsFx()
          resetTimeout(aTimeInc, show_unit)
        },
      })
}

let midExplosion = @(color, timeOffset = 0.0, rotateTo = midExplRotate1) {
  size = array(2, hdpx(1200))
  rendObj = ROBJ_IMAGE
  image = Picture("ui/images/effects/misc_expl_light_a.avif:0:P")
  color
  opacity = 0
  transform = {}
  animations = opacityAnims(aTimeIncStart + timeOffset, 0.5 * aTimeInc, 0.5 * aTimeInc + 0.5 * aTimeDec, 0.5 * aTimeDec)
    .append(
      { prop = AnimProp.scale, from = [0.0, 0.0], to = [1.0, 1.0], play = true, easing = InQuad,
        duration = aTimeInc, delay = aTimeIncStart + timeOffset, onEnter = @() playSound(getPurchaseSound()) },
      { prop = AnimProp.scale, from = [1.0, 1.0], to = [0.0, 0.0], play = true, easing = OutQuad,
        duration = aTimeDec, delay = aTimeDecStart + timeOffset },
      { prop = AnimProp.rotate, from = 0, to = rotateTo, play = true,
        duration = aTimeInc + aTimeDec, delay = aTimeIncStart + timeOffset })
}

let sideFlare = @(color, scaleTo) {
  size = flex()
  rendObj = ROBJ_IMAGE
  image = Picture("ui/images/effects/misc_expl_glow_a.avif:0:P")
  color
  transform = {}
  animations = [
    { prop = AnimProp.scale, from = [0.0, 0.0], to = [1.0, 1.0], play = true, easing = InQuad,
      duration = aTimeInc, delay = aTimeIncStart },
    { prop = AnimProp.scale, from = [1.0, 1.0], to = [scaleTo, scaleTo], play = true, easing = OutQuad,
      duration = aTimeDec + aTimeHide, delay = aTimeDecStart }
  ]
}

let sideExplosion = @(color) {
  size = [pw(70), ph(70)]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture("ui/images/effects/misc_expl_light_a.avif:0:P")
  color
  transform = {}
  animations = [
    { prop = AnimProp.scale, from = [0.0, 0.0], to = [1.0, 1.0], play = true, easing = InQuad,
      duration = aTimeInc, delay = aTimeIncStart }
    { prop = AnimProp.scale, from = [1.0, 1.0], to = [0.0, 0.0], play = true, easing = OutQuad,
      duration = aTimeSideGlowExplosionHide, delay = aTimeDecStart }
    { prop = AnimProp.rotate, from = 0, to = sideExplRotate, play = true,
      duration = aTimeInc + aTimeSideGlowExplosionHide, delay = aTimeIncStart }
    { prop = AnimProp.opacity, from = 1.0, to = 0.0, play = true, easing = OutQuad,
      duration = aTimeSideGlowExplosionHide, delay = aTimeDecStart }
    { prop = AnimProp.opacity, from = 0.0, to = 0.0, play = true,
      duration = 10000, delay = aTimeDecStart + aTimeSideGlowExplosionHide }
  ]
}

let sideFlareExplosion = @(color, scaleTo, ovr = {}) {
  size = [hdpx(1300), hdpx(500)]
  valign = ALIGN_CENTER
  children = {
    size = array(2, hdpx(500))
    children = [
      sideExplosion(color)
      sideFlare(color, scaleTo)
    ]
  }.__update(ovr)
  opacity = 0
  transform = {}
  animations = opacityAnims(aTimeIncStart, aTimeSideGlowAppear, aTimeInc + aTimeDec - aTimeSideGlowAppear, aTimeHide)
}

let tankOpening = {
  //needed to pass validation tests
  rendObj = ROBJ_SOLID
  color = 0
  key = {}

  function onAttach() {
    hide_unit()
    disable_scene_camera()
    reset_camera_pos_dir()
    start_fx_on_unit("misc_open_tank", Point3(0.25, 0.0, 0.0))
    setTimeout(aTimeShow, show_unit)
    setTimeout(aTimeFullEffect, close)
  }

  function onDetach() {
    enable_scene_camera()
    show_unit()
  }
}

let mkUnitEffectScene = @(color) {
  key = fxColors
  size = flex()

  function onAttach() {
    hide_unit()
    disable_scene_camera()
    reset_camera_pos_dir()
  }
  function onDetach() {
    show_unit()
    enable_scene_camera()
  }
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    horizonLines(color)
    midExplosion(color)
    midExplosion(color, aTimeExplosionOffset, midExplRotate2)
    midFlare(color)
    sideFlareExplosion(color, 0.83, {})
    sideFlareExplosion(color, 1.2, { hplace = ALIGN_RIGHT })
  ]
}

//no need to subscribe and try change color on the go, but need correct color on creation.
let unitEffectScene = @() getUnitType(unitToShow.get()?.name) == TANK ? tankOpening
  : mkUnitEffectScene(getFxColor(unitToShow.value))

registerScene("unitPurchaseEffectScene", unitEffectScene, close, isOpened, true)

register_command(@() unitToShow(hangarUnit.value), "ui.debug.unitPurchaseEffect")

return {
  isPurchEffectVisible = isOpened
  requestOpenUnitPurchEffect = @(unit) unitToShow(unit)
}