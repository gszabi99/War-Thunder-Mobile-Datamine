from "%globalsDarg/darg_library.nut" import *
let { playSound } = require("sound_wt")
let { get_mission_time } = require("mission")
let { playHapticPattern } = require("hapticVibration")
let { lowerAircraftCamera } = require("camera_control")
let { TouchScreenStick } = require("wt.behaviors")
let { radToDeg } = require("%sqstd/math_ex.nut")
let { atan2, abs } = require("math")
let { Point2 } = require("dagor.math")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { BombsState, hasBombs } = require("%rGui/hud/airState.nut")
let { defShortcutOvr }  = require("%rGui/hud/buttons/hudButtonsPkg.nut")
let { mkCircleProgressBgWeapon, mkBorderPlane, mkCircleGlare, mkBtnImage, mkCountTextLeft, mkCircleBg,
  circleBtnPlaneEditViewCtor, mkBtnBg
}  = require("%rGui/hud/buttons/circleTouchHudButtons.nut")
let { mkGamepadShortcutImage } = require("%rGui/controls/shortcutSimpleComps.nut")
let { allShortcutsUp } = require("%rGui/controls/shortcutsMap.nut")
let { mkIsControlDisabled } = require("%rGui/controls/disabledControls.nut")
let { getOptValue, OPT_HAPTIC_INTENSITY_ON_SHOOT } = require("%rGui/options/guiOptions.nut")
let { HAPT_SHOOT_ITEM } = require("%rGui/hud/hudHaptic.nut")
let { toggleShortcut, setShortcutOn, setShortcutOff } = require("%globalScripts/controls/shortcutActions.nut")
let { updateActionBarDelayed } = require("%rGui/hud/actionBar/actionBarState.nut")
let { btnBgStyle, imageColor, imageDisabledColor } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { isHudPrimaryStyle } = require("%rGui/options/options/hudStyleOptions.nut")
let { hudWhiteColor, hudSmokyGreyColor, hudVeilGrayColorFade, hudDarkGrayColor, hudLightBlackColor } = require("%rGui/style/hudColors.nut")


let BOMB_STICK_HOLDING = 0x01
let BOMB_STICK_ACTIVE = 0x02
let emptyWithBackground = hudVeilGrayColorFade
let background = hudDarkGrayColor

let touchMargin = sh(2.5).tointeger()
let squareLimitCalcError = hdpx(1)
let buttonSize = hdpxi(120)
let buttonSizeRadius = buttonSize / 2
let buttonImgSize = (0.65 * buttonSize + 0.5).tointeger()
let disabledColor = hudSmokyGreyColor
let HOLDING_ANIM_DURATION = 0.1

let oneBombShortcutId = "ID_BOMBS"
let seriesBombShortcutId = "ID_BOMBS_SERIES"
let oneBombImg = "ui/gameuiskin#hud_bomb.svg"
let seriesBombImg = "ui/gameuiskin#hud_bomb_multiple.svg"
let startAnimTrigger = $"{oneBombShortcutId}_START_TRIGGER"
let endAnimTrigger = $"{oneBombShortcutId}_END_TRIGGER"

let getAngle = @(x, y) radToDeg(atan2(x, y))

let seriesButtonX = hdpx(100)
let seriesButtonY = hdpx(100)
let borderAddAndle = 30
let distanceBetweenButtonsMultiplier = 1.25
let backgroundPadding = hdpx(12)

function useShortcut(shortcutId) {
  toggleShortcut(shortcutId)
  updateActionBarDelayed()
}

function useShortcutOn(shortcutId) {
  setShortcutOn(shortcutId)
  updateActionBarDelayed()
}

function useShortcutOff(shortcutId) {
  setShortcutOff(shortcutId)
  updateActionBarDelayed()
}

function mkCircleProgressHolding(size, id, isSeriesBtnHolding, isOnSeries) {
  let tryStartSalvo = @() anim_start(endAnimTrigger)
  let animations = [
    {
      prop = AnimProp.scale, duration = 0.2,
      from = [1.0, 1.0], to = [1.2, 1.2], easing = CosineFull,
      trigger = endAnimTrigger, function onStart() {
        useShortcutOn(id)
        isSeriesBtnHolding.set(true)
      }
    }
    {
      prop = AnimProp.fValue, duration = HOLDING_ANIM_DURATION, trigger = startAnimTrigger,
      from = 0.0, to = 1.0, onStart = @() resetTimeout(HOLDING_ANIM_DURATION, tryStartSalvo)
    }
  ]
  function subscription(v) {
    if (v)
      anim_start(startAnimTrigger)
    else {
      useShortcutOff(id)
      clearTimer(tryStartSalvo)
      isSeriesBtnHolding.set(false)
    }
  }
  return mkCircleBg(size, {
    watch = [isOnSeries, btnBgStyle, isHudPrimaryStyle]
    key = $"action_bg_{id}"
    fgColor = isOnSeries.get() ? emptyWithBackground : btnBgStyle.get().ready
    bgColor = btnBgStyle.get().empty
    onAttach = @() isOnSeries.subscribe(subscription)
    onDetach = @() isOnSeries.unsubscribe(subscription)
    animations
  })
}

let mkCircleProgressOneBomb = @(isAvailable, isOnOneBomb, isSeriesBtnHolding, hasAmmo, bombStickState, scaledButtonSize)
  function() {
    let isBombStickHolding = bombStickState.get() & BOMB_STICK_HOLDING
    let isReady = isAvailable.get() && (isOnOneBomb.get() || isSeriesBtnHolding.get() || !isBombStickHolding)
    return {
      watch = [BombsState, isAvailable, isOnOneBomb, isSeriesBtnHolding, hasAmmo, bombStickState, btnBgStyle]
      size = flex()
      children = mkCircleProgressBgWeapon(scaledButtonSize, oneBombShortcutId, BombsState.get(),
        isReady,
        @() playSound("weapon_primary_ready"),
        {
          fgColor = isReady ? btnBgStyle.get().ready
            : hasAmmo.get() ? emptyWithBackground
            : btnBgStyle.get().noAmmo
        })
    }
  }

let isActiveState = @(sf) (sf & S_ACTIVE) != 0

function stickControl(scale) {
  let scaledButtonSizeRadius = scaleEven(buttonSizeRadius, scale)
  let scaledButtonSize = scaleEven(buttonSize, scale)
  let scaledButtonImgSize = scaleEven(buttonImgSize, scale)
  let scaledSeriesButtonX = scaleEven(seriesButtonX, scale)
  let scaledSeriesButtonY = scaleEven(seriesButtonY, scale)

  let distanceBetweenButtons = Point2(scaledSeriesButtonX, scaledSeriesButtonY).length()
  let maxDistanceBetweenButtons = distanceBetweenButtons + scaledButtonSizeRadius
  let limitDistance = maxDistanceBetweenButtons * distanceBetweenButtonsMultiplier
  let oneBombSquareLimit = scaledButtonSizeRadius + touchMargin + backgroundPadding + squareLimitCalcError

  let minSeriesDistanceValue = (distanceBetweenButtons - scaledButtonSizeRadius) / limitDistance
  let maxSeriesDistanceValue = maxDistanceBetweenButtons / limitDistance
  let maxOneBombDistanceValue = scaledButtonSizeRadius / limitDistance

  let seriesAngle = getAngle(scaledSeriesButtonX, scaledSeriesButtonY)
  let leftSeriesAngle = seriesAngle - borderAddAndle
  let rightSeriesAngle = seriesAngle + borderAddAndle

  local isTouchPushed = false
  local isHotkeyPushed = false
  let bombStickState = Watched(0)
  let bombPieStickDelta = Watched(Point2(0, 0))
  let stateFlags = Watched(0)
  let isSeriesBtnHolding = Watched(false)
  let isDisabled = mkIsControlDisabled(oneBombShortcutId)
  let hasAmmo = Computed(@() (BombsState.get()?.count ?? 0) != 0)
  let isAvailableByTime = Computed(@() (BombsState.get().endTime ?? 0) > get_mission_time())
  let isAvailable = Computed(@() (hasAmmo.get() || isAvailableByTime.get()) && !isDisabled.get())
  let isOnSeries = Computed(function() {
    if (!(bombStickState.get() & BOMB_STICK_ACTIVE))
      return false
    let delta = bombPieStickDelta.get()
    let dist = delta.length()
    if (dist < minSeriesDistanceValue || dist > maxSeriesDistanceValue)
      return false
    let { x, y } = delta
    let angle = getAngle(-x, y)
    return angle >= leftSeriesAngle && angle <= rightSeriesAngle
  })
  let isOnOneBomb = Computed(function() {
    if (isOnSeries.get())
      return false
    let delta = bombPieStickDelta.get()
    if (bombStickState.get() & BOMB_STICK_ACTIVE)
      return delta.length() <= maxOneBombDistanceValue
    let { x, y } = delta
    return abs(x * limitDistance) <= oneBombSquareLimit && abs(y * limitDistance) <= oneBombSquareLimit
  })

  let mkBombCounter = @() { watch = [BombsState, isAvailable] }.__update(BombsState.get().count < 0 ? {}
    : mkCountTextLeft(BombsState.get().count, isAvailable.get() ? hudWhiteColor : disabledColor, scale))

  function onAppearBombPieStick() {
    bombStickState.set(bombStickState.get() | BOMB_STICK_ACTIVE)
    lowerAircraftCamera(true)
  }
  function onButtonPush() {
    bombStickState.set(bombStickState.get() | BOMB_STICK_HOLDING)
    isTouchPushed = true
    resetTimeout(0.3, onAppearBombPieStick)
    let vibrationMult = getOptValue(OPT_HAPTIC_INTENSITY_ON_SHOOT)
    playHapticPattern(HAPT_SHOOT_ITEM, vibrationMult)
  }
  function onTouchStop() {
    bombStickState.set(0)
    isTouchPushed = false
    clearTimer(onAppearBombPieStick)
    lowerAircraftCamera(false)
  }
  function onButtonReleaseWhileActiveZone() {
    if (isOnOneBomb.get() && !isSeriesBtnHolding.get())
      useShortcut(oneBombShortcutId)
    else
      useShortcutOff(seriesBombShortcutId)
    isSeriesBtnHolding.set(false)
    stateFlags.set(0)
    onTouchStop()
  }
  function onStatePush() {
    if (isTouchPushed)
      return
    isHotkeyPushed = true
    onButtonPush()
  }
  function onStateRelease() {
    if (!isHotkeyPushed)
      return
    isHotkeyPushed = false
    onButtonReleaseWhileActiveZone()
  }

  return @() !hasBombs.get() ? { watch = BombsState, key = oneBombShortcutId }
    : {
        key = oneBombShortcutId
        watch = [isAvailable, hasAmmo, bombStickState]
        behavior = TouchScreenStick
        size = [scaledButtonSize, scaledButtonSize]

        useCenteringOnTouchBegin = false

        onChange = @(v) bombPieStickDelta.set(Point2(v.x, v.y))
        maxValueRadius = limitDistance
        onTouchBegin = onButtonPush
        onTouchEnd = onButtonReleaseWhileActiveZone
        function onElemState(sf) {
          if (isSeriesBtnHolding.get()) {
            stateFlags.set(0)
            return
          }
          let prevSf = stateFlags.get()
          stateFlags.set(sf)
          let active = isActiveState(sf)
          if (active == isActiveState(prevSf))
            return
          if (active)
            onStatePush()
          else
            onStateRelease()
        }
        onAttach = @() bombStickState.set(0)
        function onDetach() {
          bombStickState.set(0)
          if (!isActiveState(stateFlags.get()))
            return
          stateFlags.set(0)
          onStateRelease()
        }
        hotkeys = [allShortcutsUp[oneBombShortcutId]]

        children = [
          !(bombStickState.get() & BOMB_STICK_ACTIVE) || !hasAmmo.get() ? null : {
            key = {}
            size = flex()
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            children = [
              {
                pos = [scaledSeriesButtonX / 2, -scaledSeriesButtonY / 2]
                size = [
                  scaledButtonSize + backgroundPadding,
                  distanceBetweenButtons + scaledButtonSize + backgroundPadding
                ]
                borderRadius = hdpx(1000)
                rendObj = ROBJ_BOX
                fillColor = background
                transform = { rotate = seriesAngle }
              }
              {
                pos = [scaledSeriesButtonX, -scaledSeriesButtonY]
                size = [scaledButtonSize, scaledButtonSize]
                children = [
                  mkBombCounter
                  mkBtnBg(scaledButtonSize, hudLightBlackColor)
                  mkCircleProgressHolding(scaledButtonSize, seriesBombShortcutId, isSeriesBtnHolding, isOnSeries)
                  mkBorderPlane(scaledButtonSize, isAvailable.get(), stateFlags, scale)
                  mkBtnImage(scaledButtonImgSize, seriesBombImg, isAvailable.get() && hasAmmo.get() ? imageColor : imageDisabledColor)
                  mkCircleGlare(scaledButtonSize, seriesBombShortcutId)
                ]
              }
            ]
            animations = wndSwitchAnim
          }
          {
            size = [scaledButtonSize, scaledButtonSize]
            hplace = ALIGN_CENTER
            vplace = ALIGN_CENTER
            color = hudWhiteColor
            children = [
              mkBtnBg(scaledButtonSize, hudLightBlackColor)
              mkCircleProgressOneBomb(isAvailable, isOnOneBomb, isSeriesBtnHolding, hasAmmo, bombStickState, scaledButtonSize)
              mkBorderPlane(scaledButtonSize, isAvailable.get(), stateFlags, scale)
              mkBtnImage(scaledButtonImgSize, oneBombImg, isAvailable.get() && hasAmmo.get() ? imageColor : imageDisabledColor)
              mkBombCounter
              mkCircleGlare(scaledButtonSize, oneBombShortcutId)
              mkGamepadShortcutImage(oneBombShortcutId, defShortcutOvr, scale)
            ]
          }
        ]
      }
}

return {
  bombPieStickBlockCtor = stickControl
  bombPieStickView = circleBtnPlaneEditViewCtor(buttonSize, buttonImgSize)(oneBombImg)
}
