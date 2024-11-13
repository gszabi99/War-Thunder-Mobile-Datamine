from "%globalsDarg/darg_library.nut" import *
let { playHapticPattern } = require("hapticVibration")
let { lowerAircraftCamera } = require("camera_control")
let { TouchScreenStick } = require("wt.behaviors")
let { radToDeg } = require("%sqstd/math_ex.nut")
let { atan2 } = require("math")
let { Point2 } = require("dagor.math")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { BombsState, hasBombs } = require("%rGui/hud/airState.nut")
let { defShortcutOvr }  = require("%rGui/hud/buttons/hudButtonsPkg.nut")
let { mkCircleProgressBgWeapon, mkBorderPlane, mkCircleGlare, mkBtnImage, mkCountTextLeft, mkCircleBg,
  circleBtnPlaneEditViewCtor
}  = require("%rGui/hud/buttons/circleTouchHudButtons.nut")
let { mkGamepadShortcutImage } = require("%rGui/controls/shortcutSimpleComps.nut")
let { allShortcutsUp } = require("%rGui/controls/shortcutsMap.nut")
let { mkIsControlDisabled } = require("%rGui/controls/disabledControls.nut")
let { getOptValue, OPT_HAPTIC_INTENSITY_ON_SHOOT } = require("%rGui/options/guiOptions.nut")
let { HAPT_SHOOT_ITEM } = require("%rGui/hud/hudHaptic.nut")
let { toggleShortcut } = require("%globalScripts/controls/shortcutActions.nut")
let { updateActionBarDelayed } = require("%rGui/hud/actionBar/actionBarState.nut")
let { btnBgColor } = require("%rGui/hud/hudTouchButtonStyle.nut")


let buttonSize = hdpxi(120)
let buttonSizeRadius = buttonSize / 2
let buttonImgSize = (0.65 * buttonSize + 0.5).tointeger()
let disabledColor = 0x4D4D4D4D
let HOLDING_ANIM_DURATION = 1.0

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

function useShortcut(shortcutId) {
  toggleShortcut(shortcutId)
  updateActionBarDelayed()
}

function mkCircleProgressHolding(size, id, stickDelta, onFinish, seriesAngle, minSeriesDistanceValue, maxSeriesDistanceValue) {
  let tryStartSalvo = @() anim_start(endAnimTrigger)
  let animations = [
    {
      prop = AnimProp.scale, duration = 0.2,
      from = [1.0, 1.0], to = [1.2, 1.2], easing = CosineFull,
      trigger = endAnimTrigger, function onStart() {
        useShortcut(seriesBombShortcutId)
        onFinish()
      }
    }
    {
      prop = AnimProp.fValue, duration = HOLDING_ANIM_DURATION, trigger = startAnimTrigger,
      from = 0.0, to = 1.0, onStart = @() resetTimeout(HOLDING_ANIM_DURATION, tryStartSalvo)
    }
  ]

  let leftSeriesAngle = seriesAngle - borderAddAndle
  let rightSeriesAngle = seriesAngle + borderAddAndle
  let isOnSeries = Computed(function() {
    let delta = stickDelta.get()
    let dist = delta.length()
    if (dist < minSeriesDistanceValue || dist > maxSeriesDistanceValue)
      return false
    let { x, y } = delta
    let angle = getAngle(-x, y)
    return angle >= leftSeriesAngle && angle <= rightSeriesAngle
  })
  isOnSeries.subscribe(@(v) v ? anim_start(startAnimTrigger) : clearTimer(tryStartSalvo))
  return @() mkCircleBg(size).__update({
    watch = isOnSeries
    key = $"action_bg_{id}"
    fgColor = isOnSeries.get() ? btnBgColor.ready : btnBgColor.empty
    bgColor = btnBgColor.empty
    animations
  })
}

let lowerCamera = @() lowerAircraftCamera(true)
let hasAmmo = @(weapon) weapon.count != 0
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
  let minSeriesDistanceValue = (distanceBetweenButtons - scaledButtonSizeRadius) / limitDistance
  let maxSeriesDistanceValue = maxDistanceBetweenButtons / limitDistance
  let maxOneBombDistanceValue = scaledButtonSizeRadius / limitDistance

  let seriesAngle = getAngle(scaledSeriesButtonX, scaledSeriesButtonY)

  local isTouchPushed = false
  local isHotkeyPushed = false
  let isBombPieStickActive = Watched(false)
  let bombPieStickDelta = Watched(Point2(0, 0))
  let stateFlags = Watched(0)
  let afterHolding = Watched(false)
  let isDisabled = mkIsControlDisabled(oneBombShortcutId)
  let isAvailable = Computed(@() hasAmmo(BombsState.get()) && !isDisabled.get())
  let isOnOneBomb = Computed(@() bombPieStickDelta.get().length() <= maxOneBombDistanceValue)

  function onButtonPush() {
    isBombPieStickActive.set(true)
    isTouchPushed = true
    resetTimeout(0.3, lowerCamera)
    let vibrationMult = getOptValue(OPT_HAPTIC_INTENSITY_ON_SHOOT)
    playHapticPattern(HAPT_SHOOT_ITEM, vibrationMult)
  }
  function onTouchStop() {
    isBombPieStickActive.set(false)
    isTouchPushed = false
    clearTimer(lowerCamera)
    lowerAircraftCamera(false)
  }
  function onButtonReleaseWhileActiveZone() {
    if (isOnOneBomb.get() && !afterHolding.get())
      useShortcut(oneBombShortcutId)
    afterHolding.set(false)
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
  function onHoldingSuccess() {
    onTouchStop()
    isHotkeyPushed = false
    afterHolding.set(true)
  }

  isBombPieStickActive.subscribe(@(isActive) isActive ? null : bombPieStickDelta.set(Point2(0, 0)))

  return @() !hasBombs.get() ? { watch = BombsState, key = oneBombShortcutId }
    : {
        key = oneBombShortcutId
        watch = [isAvailable, isBombPieStickActive]
        behavior = TouchScreenStick
        size = [scaledButtonSize, scaledButtonSize]

        useCenteringOnTouchBegin = false

        onChange = @(v) bombPieStickDelta.set(Point2(v.x, v.y))
        maxValueRadius = limitDistance
        onTouchBegin = onButtonPush
        onTouchEnd = onButtonReleaseWhileActiveZone
        function onElemState(sf) {
          if (afterHolding.get()) {
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
        onAttach = @() isBombPieStickActive.set(false)
        function onDetach() {
          isBombPieStickActive.set(false)
          if (!isActiveState(stateFlags.get()))
            return
          stateFlags.set(0)
          onStateRelease()
        }
        hotkeys = [allShortcutsUp[oneBombShortcutId]]

        children = [
          {
            size = flex()
            children = !isBombPieStickActive.get() || !isAvailable.get() ? null
              : {
                  pos = [scaledSeriesButtonX, -scaledSeriesButtonY]
                  size = [scaledButtonSize, scaledButtonSize]
                  hplace = ALIGN_CENTER
                  vplace = ALIGN_CENTER
                  color = 0xFFFFFFFF
                  children = [
                    mkCircleProgressHolding(scaledButtonSize, seriesBombShortcutId, bombPieStickDelta,
                      onHoldingSuccess, seriesAngle, minSeriesDistanceValue, maxSeriesDistanceValue)
                    mkBtnImage(scaledButtonImgSize, seriesBombImg)
                    mkCircleGlare(scaledButtonSize, seriesBombShortcutId)
                  ]
                }
          }
          {
            size = [scaledButtonSize, scaledButtonSize]
            hplace = ALIGN_CENTER
            vplace = ALIGN_CENTER
            color = 0xFFFFFFFF
            children = [
              @() {
                watch = [BombsState, isDisabled, isOnOneBomb, afterHolding]
                size = flex()
                children = mkCircleProgressBgWeapon(scaledButtonSize, oneBombShortcutId, BombsState.get(),
                  !isDisabled.get() && (isOnOneBomb.get() || !hasAmmo(BombsState.get()) || afterHolding.get()))
              }
              mkBorderPlane(scaledButtonSize, isAvailable.get(), stateFlags, scale)
              mkBtnImage(scaledButtonImgSize, oneBombImg)
              @() {
                watch = [BombsState, isAvailable]
              }.__update(BombsState.get().count < 0 ? {}
                : mkCountTextLeft(BombsState.get().count, isAvailable.get() ? 0xFFFFFFFF : disabledColor, scale))
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
