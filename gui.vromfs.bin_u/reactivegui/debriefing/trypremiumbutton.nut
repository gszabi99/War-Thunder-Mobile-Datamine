from "%globalsDarg/darg_library.nut" import *
let { openShopWnd } = require("%rGui/shop/shopState.nut")
let { SC_PREMIUM } = require("%rGui/shop/shopCommon.nut")
let { gradTranspDoubleSideX, gradRadial } = require("%rGui/style/gradients.nut")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { isDebriefingAnimFinished } = require("%rGui/debriefing/debriefingState.nut")

let btnW  = hdpxi(225)
let btnH = hdpxi(200)
let premIconW = hdpxi(140)
let premIconH = hdpxi(97)

let glareAnimDuration = 0.4
let glareRepeatDelay = 2
let startGlareAnim = @() anim_start("glareAnim")
let glareWidth = hdpx(40)
let glareHeight = btnH * 1.25

let glowColor = 0xFF8A5627
let bgColor = 0xFF1A1D1E
let textColor = 0xFFFFFFFF

let isActive = @(sf) (sf & S_ACTIVE) != 0

let btnBg = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = bgColor
}

let btnGlow = {
  size = [btnW * 1.2, btnW * 1.2]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = gradRadial
  color = glowColor
}

let btnIcon = {
  size = [premIconW, premIconH]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  pos = [0, ph(-7)]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#premium_active_big.avif:{premIconW}:{premIconH}:K:P")
  keepAspect = KEEP_ASPECT_FIT
}

let btnText = {
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  pos = [0, ph(26)]
  behavior = Behaviors.TextArea
  rendObj = ROBJ_TEXTAREA
  text = loc("debriefing/tryPremium")
  color = textColor
  fontFx = FFT_GLOW
  fontFxFactor = hdpxi(32)
  fontFxColor = 0xFF000000
}.__update(fontTiny)

let glare = {
  key = "glare"
  rendObj = ROBJ_IMAGE
  size = [glareWidth, glareHeight]
  image = gradTranspDoubleSideX
  color = 0x00A0A0A0
  transform = { translate = [-glareWidth * 3, 0], rotate = 25 }
  vplace = ALIGN_CENTER
  onAttach = @() clearTimer(startGlareAnim)
  animations = [{
    prop = AnimProp.translate, duration = glareAnimDuration, delay = 0.5, play = true,
    to = [btnW + glareWidth * 2, 0],
    trigger = "glareAnim",
    onFinish = @() resetTimeout(glareRepeatDelay, startGlareAnim),
  }]
}

let function tryPremiumButton() {
  let stateFlags = Watched(0)
  return @() {
    watch = [stateFlags, isDebriefingAnimFinished]
    size = [btnW, btnH]

    behavior = Behaviors.Button
    onClick = @() openShopWnd(SC_PREMIUM)
    onElemState = @(v) stateFlags.set(v)
    transform = { scale = isActive(stateFlags.get()) ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = Linear }]
    sound = { click  = "click" }

    rendObj = ROBJ_MASK
    image = Picture($"!ui/gameuiskin#debr_prem_btn_mask.svg:{btnW}:{btnH}:K")
    clipChildren = true

    children = [
      btnBg
      btnGlow
      btnIcon
      btnText
      isDebriefingAnimFinished.get() ? glare : null
    ]
  }
}

return tryPremiumButton
