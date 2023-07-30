from "%globalsDarg/darg_library.nut" import *
let { openShopWnd } = require("%rGui/shop/shopState.nut")
let { SC_PREMIUM } = require("%rGui/shop/shopCommon.nut")
let { gradRadial } = require("%rGui/style/gradients.nut")

let btnW  = hdpxi(225)
let btnH = hdpxi(200)
let premIconW = hdpxi(140)
let premIconH = hdpxi(97)

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

let function tryPremiumButton() {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size = [btnW, btnH]

    behavior = Behaviors.Button
    onClick = @() openShopWnd(SC_PREMIUM)
    onElemState = @(v) stateFlags(v)
    transform = { scale = isActive(stateFlags.value) ? [0.95, 0.95] : [1, 1] }
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
    ]
  }
}

return tryPremiumButton
