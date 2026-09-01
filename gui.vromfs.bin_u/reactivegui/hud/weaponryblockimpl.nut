from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout
from "%rGui/hud/commonSight.nut" import scopeSize
from "%rGui/hud/currentWeaponsStates.nut" import currentHoldWeaponName
from "%rGui/style/hudColors.nut" import hudOceanMistColor


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
      color = hudOceanMistColor
      size = FLEX
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
      text
    }.__update(fontTinyShaded)
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
