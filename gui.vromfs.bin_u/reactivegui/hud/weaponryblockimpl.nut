from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { touchButtonSize } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { visibleWeaponsMap, currentHoldWeaponName, isChainedWeapons } = require("%rGui/hud/currentWeaponsStates.nut")
let weaponsButtonsConfig = require("%rGui/hud/weaponsButtonsConfig.nut")
let { scopeSize } = require("%rGui/hud/commonSight.nut")

let halfScopeHeight = scopeSize[1] / 2

let chainImgSize = (0.5 * touchButtonSize).tointeger()
let chainHaloSize = 0.1
let chainBgImgSize = [
  (touchButtonSize * (2.4 + chainHaloSize)).tointeger(),
  (touchButtonSize * (1.0 + chainHaloSize)).tointeger()]
let chainImageOn = Picture($"ui/gameuiskin#hud_chain_on.svg:{chainImgSize}:{chainImgSize}:P")
let chainImageOff = Picture($"ui/gameuiskin#hud_chain_off.svg:{chainImgSize}:{chainImgSize}:P")
let chainImageBg = Picture($"ui/gameuiskin#hud_chain_bg.svg:{chainBgImgSize[0]}:{chainBgImgSize[1]}:P")

function mkChainedWeapons(actionCtor, visibleIds) {
  let actionItems = []
  let buttonsConfig = []

  foreach (id in visibleIds) {
    actionItems.append(visibleWeaponsMap.value?[id])
    buttonsConfig.append(weaponsButtonsConfig?[id])
  }

  let numButtonsChained = buttonsConfig.len()
  if (numButtonsChained == 0)
    return null

  return @() {
    watch = isChainedWeapons
    size = [touchButtonSize * 2, touchButtonSize * 2]
    children = numButtonsChained == 1
      ? actionCtor(buttonsConfig[0], actionItems[0])
      : [
          actionCtor(buttonsConfig[0], actionItems[0])

          {
            pos = [- touchButtonSize * 0.25, touchButtonSize * 0.45]
            rendObj = ROBJ_IMAGE
            image = chainImageBg
            opacity = isChainedWeapons.value ? 0.3 : 0.0
            transform = { rotate = 45 }
            size = chainBgImgSize
          }

          {
            pos = [touchButtonSize * 0.75, touchButtonSize * 0.75]
            behavior = Behaviors.TouchScreenButton
            onTouchBegin = @() isChainedWeapons(!isChainedWeapons.value)
            rendObj = ROBJ_IMAGE
            opacity = 0.5
            image = isChainedWeapons.value ? chainImageOn : chainImageOff
            size = [chainImgSize, chainImgSize]
          }

          actionCtor(buttonsConfig[1], actionItems[1],
            { pos = [touchButtonSize, touchButtonSize] })
        ]
  }
}

let mkSimpleChainIcon = @(ovr = {}) {
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_IMAGE
      image = chainImageOn
      size = [chainImgSize, chainImgSize]
    }
  ]
}.__update(ovr)

let weaponHintText = Watched(null)
let clearWeaponText = @() weaponHintText(null)
currentHoldWeaponName.subscribe(function(v) {
  weaponHintText(v)
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
  children = weaponHintText.value == null ? null
    : mkWeaponNameText(weaponHintText.value)
}

return {
  currentWeaponNameText
  mkSimpleChainIcon
  mkChainedWeapons
}
