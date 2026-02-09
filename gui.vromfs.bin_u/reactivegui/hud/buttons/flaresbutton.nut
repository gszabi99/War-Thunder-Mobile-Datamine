from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { get_mission_time } = require("mission")
let { playHapticPattern } = require("hapticVibration")
let { TouchScreenButton } = require("wt.behaviors")
let { PI, cos, sin, abs } = require("%sqstd/math.nut")
let { toggleShortcut } = require("%globalScripts/controls/shortcutActions.nut")
let { mkIsControlDisabled } = require("%rGui/controls/disabledControls.nut")
let { mkGamepadShortcutImage, mkGamepadHotkey } = require("%rGui/controls/shortcutSimpleComps.nut")
let { FlaresState, IsPeriodicFlaresEnabled } = require("%rGui/hud/airState.nut")
let { imageColor, imageDisabledColor } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { hudWhiteColor, hudLightBlackColor, hudSmokyGreyColor, hudDarkGrayColor
} = require("%rGui/style/hudColors.nut")
let { airButtonSize, buttonImgSize, isWeaponAvailable, getWeapStateFlags, mkBtnBg,
  mkCircleProgressBgWeapon, mkBorderPlane, mkBtnImage, mkCountTextLeft, mkCircleGlare
} = require("%rGui/hud/buttons/circleTouchHudButtons.nut")
let { defShortcutOvr }  = require("%rGui/hud/buttons/hudButtonsPkg.nut")
let { markWeapKeyHold, unmarkWeapKeyHold, userHoldWeapInside
} = require("%rGui/hud/currentWeaponsStates.nut")
let { getOptValue, OPT_HAPTIC_INTENSITY_ON_SHOOT } = require("%rGui/options/guiOptions.nut")
let { HAPT_SHOOT_ITEM } = require("%rGui/hud/hudHaptic.nut")


let shortcutId = "ID_COUNTERMEASURES_FLARES"
let periodicShortcutId = "ID_TOGGLE_PERIODIC_FLARES"

let flaresImg = "ui/gameuiskin#hud_ltc.svg"
let disabledColor = hudSmokyGreyColor
let bgColor = hudDarkGrayColor

let EXPAND_HOLD_TIME = 0.3
let btnAngle = -0.33 * PI
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
      size = flex()
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
  let function onActionClick(scId) {
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
        size = flex()
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
