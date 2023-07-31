from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { dfAnimBottomLeft, dfAnimBottomRight } = require("%rGui/style/unitDelayAnims.nut")
let { touchButtonSize } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { visibleWeaponsList, currentHoldWeaponName, isChainedWeapons } = require("%rGui/hud/currentWeaponsStates.nut")
let weaponsButtonsConfig = require("%rGui/hud/weaponsButtonsConfig.nut")
let weaponsButtonsView = require("%rGui/hud/weaponsButtonsView.nut")
let { scopeSize } = require("%rGui/hud/commonSight.nut")
let { isInZoom, isUnitDelayed } = require("%rGui/hudState.nut")

let halfScopeHeight = scopeSize[1] / 2
let logerrWithPrefix = @(text) logerr($"[HUD: WeaponButtons] {text}")

let chainImgSize = (0.5 * touchButtonSize).tointeger()
let chainBgImgSize = [(touchButtonSize *2.5).tointeger(), (touchButtonSize * 1.1).tointeger()]
let chainImageOn = Picture($"ui/gameuiskin#hud_chain_on.svg:{chainImgSize}:{chainImgSize}:P")
let chainImageOff = Picture($"ui/gameuiskin#hud_chain_off.svg:{chainImgSize}:{chainImgSize}:P")
let chainImageBg = Picture($"ui/gameuiskin#hud_chain_bg.svg:{chainBgImgSize[0]}:{chainBgImgSize[1]}:P")

let weaponryPlacePosition = [
  { hplace = ALIGN_LEFT, vplace = ALIGN_TOP }                                                //zoom always
  { hplace = ALIGN_CENTER, vplace = ALIGN_TOP }                                              //1
  { hplace = ALIGN_LEFT, vplace = ALIGN_CENTER, pos = [ touchButtonSize, 0] }                //2
  { hplace = ALIGN_CENTER, vplace = ALIGN_BOTTOM }                                           //3
  { hplace = ALIGN_RIGHT, vplace = ALIGN_CENTER, pos = [ -touchButtonSize, 0] }              //4
  { hplace = ALIGN_RIGHT, vplace = ALIGN_TOP }                                               //5
  { hplace = ALIGN_RIGHT, vplace = ALIGN_CENTER, pos = [ touchButtonSize,  0] }              //6
  { hplace = ALIGN_RIGHT, vplace = ALIGN_TOP, pos = [ -touchButtonSize, -touchButtonSize] }  //7
  { hplace = ALIGN_RIGHT, vplace = ALIGN_BOTTOM, pos = [ 0, 0] }                             //8
]

let weaponryLeftAlignPlacePosition = [
  { hplace = ALIGN_CENTER, vplace = ALIGN_TOP, pos = [ 0, -touchButtonSize] }                //zoom always
  { hplace = ALIGN_CENTER, vplace = ALIGN_TOP, pos = [ -touchButtonSize, 0] }                //1
  { hplace = ALIGN_CENTER, vplace = ALIGN_CENTER}                                            //2
  { hplace = ALIGN_RIGHT, vplace = ALIGN_BOTTOM, pos = [ -touchButtonSize, 0] }              //3
  { hplace = ALIGN_RIGHT, vplace = ALIGN_CENTER }                                            //4
  { hplace = ALIGN_LEFT, vplace = ALIGN_BOTTOM, pos = [ touchButtonSize, 0] }                //5
  { hplace = ALIGN_RIGHT, vplace = ALIGN_BOTTOM, pos = [ touchButtonSize, 0] }               //6
  { hplace = ALIGN_RIGHT, vplace = ALIGN_TOP, pos = [ -touchButtonSize, 0] }                 //7
  { hplace = ALIGN_RIGHT, vplace = ALIGN_TOP, pos = [ -touchButtonSize, 2 * touchButtonSize]}//8
]

let mkChainIcon = function(weaponsList, weaponryPositions) {
  local numButtonsChained = 0
  local chainPos = {}
  foreach (info in weaponsList) {
    let { id, viewCfg = null } = info
    let w = viewCfg ?? weaponsButtonsConfig[id]
    if (w?.additionalShortcutId) {
      numButtonsChained++
      if (w?.drawChain)
        chainPos.__update(weaponryPositions[w.weaponPlacePosIdx])
    }
  }
  if (numButtonsChained < 2 || chainPos.len() == 0)
    return null
  let curPos = (chainPos?.pos ?? [0, 0]).map(@(v) v + touchButtonSize * 0.5)
  chainPos.__update({pos = curPos})
  return @(){
    watch = isChainedWeapons
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      isChainedWeapons.value
      ? {
          rendObj = ROBJ_IMAGE
          image = chainImageBg
          opacity = 0.3
          transform = { rotate = 45 }
          size = chainBgImgSize
        }
      : null
      {
        behavior = Behaviors.TouchScreenButton
        onTouchBegin = @() isChainedWeapons(!isChainedWeapons.value)
        rendObj = ROBJ_IMAGE
        opacity = 0.5
        image = isChainedWeapons.value ? chainImageOn : chainImageOff
        size = [chainImgSize, chainImgSize]
      }
    ]
  }.__update(chainPos)
}


let function mkWeaponsButtons(weaponsList, weaponryPositions, isZoomView) {
  let res = []
  local nextIdx = 1
  let occupiedPlacesIdx = {}
  foreach (_, info in weaponsList) {
    let { id, actionItem, viewCfg = null } = info
    let w = viewCfg ?? weaponsButtonsConfig[id]
    local placeIdx = w?.weaponPlacePosIdx ?? nextIdx
    local hasForcePlace = "weaponPlacePosIdx" in w
    if (hasForcePlace && (placeIdx in occupiedPlacesIdx)) {
      placeIdx = nextIdx
      hasForcePlace = false
      logerrWithPrefix($"Two weapons with one weaponPlacePosIdx: {placeIdx}")
      continue
    }

    let bestIdx = hasForcePlace ? placeIdx
      : weaponryPositions.findindex(@(_, idx) idx >= nextIdx && (idx not in occupiedPlacesIdx))
    if (bestIdx == null) {
      logerrWithPrefix("Not all weapons fit in the allotted spaces")
      return res
    }
    nextIdx = hasForcePlace ? nextIdx : bestIdx + 1
    if (hasForcePlace)
      occupiedPlacesIdx[placeIdx] <- true
    if (w?.visibleInZoom && !isZoomView)
      continue
    res.append(weaponsButtonsView?[w.mkButtonFunction](w, actionItem, weaponryPositions[bestIdx]))
  }
  res.append(mkChainIcon(weaponsList, weaponryPositions))
  return res
}

let mkWeaponryBlock = @(placePosition, ovr = {}) @() {
  watch = [ visibleWeaponsList, isInZoom, isUnitDelayed]
  size = [5 * touchButtonSize, 3 * touchButtonSize]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  pos = [0, -shHud(0.4)]
  children = isUnitDelayed.value ? null
    : mkWeaponsButtons(visibleWeaponsList.value, placePosition, isInZoom.value)
  transform = {}
  animations = dfAnimBottomRight
}.__update(ovr)

let rightAlignWeaponryBlock = mkWeaponryBlock(weaponryPlacePosition)
let leftAlignWeaponryBlock = mkWeaponryBlock(weaponryLeftAlignPlacePosition,
  { hplace = ALIGN_LEFT, animations = dfAnimBottomLeft })

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
  leftAlignWeaponryBlock
  rightAlignWeaponryBlock
  currentWeaponNameText
}
