from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout, clearTimer
from "hapticVibration" import playHapticPattern
from "mission" import get_mission_time
from "wt.behaviors" import TouchScreenButton
from "%sqstd/math.nut" import PI, cos, sin, abs
from "%globalScripts/controls/shortcutActions.nut" import toggleShortcut
from "%rGui/controls/disabledControls.nut" import mkIsControlDisabled
from "%rGui/controls/shortcutSimpleComps.nut" import mkGamepadShortcutImage, mkGamepadHotkey
from "%rGui/hud/airState.nut" import FlaresState, IsPeriodicFlaresEnabled
from "%rGui/hud/buttons/circleTouchHudButtons.nut" import airButtonSize, buttonImgSize, isWeaponAvailable,
  getWeapStateFlags, mkBtnBg, mkCircleProgressBgWeapon, mkBorderPlane, mkBtnImage, mkCountTextLeft, mkCircleGlare
from "%rGui/hud/buttons/hudButtonsPkg.nut" import defShortcutOvr
from "%rGui/hud/currentWeaponsStates.nut" import markWeapKeyHold, unmarkWeapKeyHold, userHoldWeapInside
from "%rGui/hud/hudHaptic.nut" import HAPT_SHOOT_ITEM
from "%rGui/hud/hudTouchButtonStyle.nut" import imageColor, imageDisabledColor
from "%rGui/options/guiOptions.nut" import getOptValue, OPT_HAPTIC_INTENSITY_ON_SHOOT
from "%rGui/style/hudColors.nut" import hudWhiteColor, hudLightBlackColor, hudSmokyGreyColor, hudDarkGrayColor


const shortcutId = "ID_COUNTERMEASURES_FLARES"
const periodicShortcutId = "ID_TOGGLE_PERIODIC_FLARES"

const flaresImg = "ui/gameuiskin#hud_ltc.svg"
let disabledColor = hudSmokyGreyColor
let bgColor = hudDarkGrayColor

const EXPAND_HOLD_TIME = 0.3
const btnAngle = -0.33 * PI
let distanceBetweenButtons = 0.2 * airButtonSize
let repeatSize = 0.4 * airButtonSize
let touchMargin = sh(2.5).tointeger()

let getDistanceSq = @(p2, pArr) (p2.x - pArr[0]) * (p2.x - pArr[0]) + (p2.y - pArr[1]) * (p2.y - pArr[1])

function calcSizes(scale) {
  let btnSize = scaleEven(airButtonSize, scale)
  let imgSize = scaleEven(buttonImgSize, scale)
  let btnRadius = btnSize / 2
  let buttonsDist = 2 * btnRadius + (distanceBetweenButtons * scale + 0.5).tointeger()
  return {
    btnSize
    btnCenter = [btnSize / 2, btnSize / 2]
    btnCenter2 = [btnSize / 2 + cos(btnAngle) * buttonsDist, btnSize / 2 + sin(btnAngle) * buttonsDist]
    imgSize
    imgRepeatSize = (repeatSize * scale + 0.5).tointeger()
    outRadiusSq = (btnRadius + touchMargin) * (btnRadius + touchMargin)
    bgRadius = (btnRadius * 1.2 + 0.5).tointeger()
  }
}

let mkRepeatImg = @(imgRepeatSize, btnSize) {
  size = [imgRepeatSize, imgRepeatSize]
  pos = [0.2, -0.45].map(@(v) v * (btnSize - imgRepeatSize))
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#refresh.svg:{imgRepeatSize}:{imgRepeatSize}:P")
  keepAspect = KEEP_ASPECT_FIT
  color = imageColor
}

let mkBlackBg = @(bgRadius, c1, c2) {
  size = c1.map(@(v, i) abs(v - c2[i]))
  pos = c1.map(@(v, i) min(v, c2[i]))
  rendObj = ROBJ_VECTOR_CANVAS
  color = bgColor
  lineWidth = bgRadius * 2
  commands = [[ VECTOR_LINE,
    c1[0] < c2[0] ? 0 : 100,
    c1[1] < c2[1] ? 0 : 100,
    c1[0] < c2[0] ? 100 : 0,
    c1[1] < c2[1] ? 100 : 0
  ]]
}

let mkPeriodicFlareBtn = @(btnSize, center, imgSize, imgRepeat, stateFlags, scale) {
  size = [btnSize, btnSize]
  pos = [center[0] - btnSize / 2, center[1] - btnSize / 2]
  children = [
    mkBtnBg(btnSize, hudLightBlackColor)
    @() {
      watch = FlaresState
      size = FLEX
      children = mkCircleProgressBgWeapon(btnSize, shortcutId, FlaresState.get(), true)
    }
    mkBorderPlane(btnSize, true, stateFlags, scale)
    mkBtnImage(imgSize, flaresImg, imageColor)
    imgRepeat
  ]
}

function flaresButtonCtor(scale) {
  let isDisabled = mkIsControlDisabled(shortcutId)
  let isAvailable = Computed(@() isWeaponAvailable(FlaresState.get()) && !isDisabled.get())
  let stateFlags = getWeapStateFlags(shortcutId)
  let point = Watched(null)
  let isHold = Watched(false)
  let isExpanded = Computed(@() isHold.get() && isAvailable.get())

  let { btnSize, btnCenter, imgSize, outRadiusSq, btnCenter2, bgRadius, imgRepeatSize
  } = calcSizes(scale)

  let hoverScId = Computed(function() {
    let p = point.get()
    if (p == null)
      return null
    let dsq1 = getDistanceSq(p, btnCenter)
    if (!isExpanded.get())
      return dsq1 > outRadiusSq ? null : shortcutId
    let dsq2 = getDistanceSq(p, btnCenter2)
    return min(dsq1, dsq2) > outRadiusSq ? null
      : dsq1 < dsq2 ? shortcutId
      : periodicShortcutId
  })
  let stateFlagsMain = Computed(@() hoverScId.get() == shortcutId ? stateFlags.get() : 0)
  let stateFlagsPeriodic = Computed(@() hoverScId.get() == periodicShortcutId ? stateFlags.get() : 0)

  let markHold = @() isHold.set(true)
  function onActionClick(scId) {
    if (scId == null)
      return
    if (IsPeriodicFlaresEnabled.get()) {
      toggleShortcut(periodicShortcutId)
      return
    }
    if (!isAvailable.get() || FlaresState.get().count == 0 || FlaresState.get().endTime > get_mission_time())
      return
    toggleShortcut(scId)
  }

  function onTouchBegin() {
    resetTimeout(EXPAND_HOLD_TIME, markHold)
    markWeapKeyHold(shortcutId)
    userHoldWeapInside.mutate(@(v) v[shortcutId] <- true)
    let vibrationMult = getOptValue(OPT_HAPTIC_INTENSITY_ON_SHOOT)
    playHapticPattern(HAPT_SHOOT_ITEM, vibrationMult)
  }

  function onTouchEnd() {
    unmarkWeapKeyHold(shortcutId)
    if (shortcutId in userHoldWeapInside.get())
      userHoldWeapInside.mutate(@(v) v.$rawdelete(shortcutId))
    onActionClick(hoverScId.get())
    clearTimer(markHold)
    isHold.set(false)
  }

  let imgRepeat = mkRepeatImg(imgRepeatSize, btnSize)

  return @() {
    watch = [isDisabled, isAvailable, IsPeriodicFlaresEnabled]
    size = [btnSize, btnSize]

    behavior = TouchScreenButton
    onElemState = @(v) stateFlags.set(v)
    onTouchBegin
    onTouchEnd
    onChange = @(p) point.set(p)
    hotkeys = mkGamepadHotkey(shortcutId, @() onActionClick(shortcutId))

    children = [
      @() !isExpanded.get() ? { watch = isExpanded }
        : {
            watch = isExpanded
            size = [btnSize, btnSize]
            children = [
              mkBlackBg(bgRadius, btnCenter, btnCenter2)
              mkPeriodicFlareBtn(btnSize, btnCenter2, imgSize, imgRepeat, stateFlagsPeriodic, scale)
            ]
          }
      mkBtnBg(btnSize, hudLightBlackColor)
      @() {
        watch = FlaresState
        size = FLEX
        children = mkCircleProgressBgWeapon(btnSize, shortcutId, FlaresState.get(), isAvailable.get())
      }
      mkBorderPlane(btnSize, isAvailable.get(), stateFlagsMain, scale)
      mkBtnImage(imgSize, flaresImg, isAvailable.get() ? imageColor : imageDisabledColor)
      @() {
        watch = [FlaresState, isAvailable]
      }.__update(FlaresState.get().count < 0 ? {}
        : mkCountTextLeft(FlaresState.get().count, isAvailable.get() ? hudWhiteColor : disabledColor, scale))
      mkCircleGlare(btnSize, shortcutId)
      mkGamepadShortcutImage(shortcutId, defShortcutOvr, scale)
      IsPeriodicFlaresEnabled.get() ? imgRepeat : null
    ]
  }
}

return flaresButtonCtor
