from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { currentHoldWeaponName } = require("%rGui/hud/currentWeaponsStates.nut")
let { scopeSize } = require("%rGui/hud/commonSight.nut")

let halfScopeHeight = scopeSize[1] / 2

let weaponHintText = Watched(null)
let clearWeaponText = @() weaponHintText.set(null)
currentHoldWeaponName.subscribe(function(v) {
  weaponHintText.set(v)
  resetTimeout(3.0, clearWeaponText)
})

let mkWeaponNameText = @(text) {
  key = text
  children = [
    {
      rendObj = ROBJ_SOLID
      transform = { pivot = [0, 1] }
      color = Color(11, 53, 54, 63)
      size = flex()
      animations = [
        { prop = AnimProp.scale, from = [0.0, 0.0], to = [0.0, 0.0], duration = 0.3, play = true }
        { prop = AnimProp.scale, from = [0.0, 1.0], to = [1.0, 1.0], duration = 0.3, play = true,
          delay = 0.3 }
      ]
    }
    {
      rendObj = ROBJ_TEXTAREA
      margin = hdpx(5)
      behavior = [Behaviors.TextArea]
      fontFxColor = Color(0, 0, 0, 255)
      fontFxFactor = 50
      fontFx = FFT_GLOW
      text
    }.__update(fontTiny)
  ]
  animations = [
    { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.1, play = true }
    { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.1, playFadeOut = true }
  ]
}

let currentWeaponNameText = @() {
  watch = weaponHintText
  pos = [0, halfScopeHeight + hdpx(20)]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = weaponHintText.get() == null ? null
    : mkWeaponNameText(weaponHintText.get())
}

return {
  currentWeaponNameText
}
