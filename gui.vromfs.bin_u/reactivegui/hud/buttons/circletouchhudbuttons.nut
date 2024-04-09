from "%globalsDarg/darg_library.nut" import *
let { get_mission_time = @() ::get_mission_time() } = require("mission")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { playSound } = require("sound_wt")
let { btnBgColor, borderColorPushed, borderNoAmmoColor, borderColor,
} = require("%rGui/hud/hudTouchButtonStyle.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { toggleShortcut, setShortcutOn, setShortcutOff } = require("%globalScripts/controls/shortcutActions.nut")
let { updateActionBarDelayed } = require("%rGui/hud/actionBar/actionBarState.nut")
let { canZoom, isInZoom, isTrackingActive } = require("%rGui/hudState.nut")
let { addCommonHint } = require("%rGui/hudHints/commonHintLogState.nut")
let { mkGamepadShortcutImage, mkGamepadHotkey, mkContinuousButtonParams
} = require("%rGui/controls/shortcutSimpleComps.nut")
let { weaponTouchIcons } = require("%appGlobals/weaponPresentation.nut")
let { gradTranspDoubleSideX } = require("%rGui/style/gradients.nut")
let { allowShoot, primaryRocketGun } = require("%rGui/hud/tankState.nut")
let { mkIsControlDisabled } = require("%rGui/controls/disabledControls.nut")
let { Cannon0, MGun0, hasCanon0, hasMGun0 } = require("%rGui/hud/airState.nut")
let { markWeapKeyHold, unmarkWeapKeyHold, userHoldWeapInside
} = require("%rGui/hud/currentWeaponsStates.nut")
let { mkBtnZone, lockButtonIcon, canLock}  = require("hudButtonsPkg.nut")
let { lowerAircraftCamera } = require("camera_control")

let bigButtonSize = hdpxi(150)
let bigButtonImgSize = (0.65 * bigButtonSize + 0.5).tointeger()
let buttonSize = hdpxi(120)
let buttonImgSize = (0.65 * buttonSize + 0.5).tointeger()
let aimImageSize = hdpxi(80)
let disabledColor = 0x4D4D4D4D

let targetTrackingImgSize = hdpxi(76)
let targetTrackingOffImgSize = hdpxi(94)

let zoneRadiusX = 2.5 * buttonSize
let zoneRadiusY = buttonSize

let isActionAvailable = @(actionItem) (actionItem?.available ?? true)
  && (actionItem.count != 0 || actionItem?.control
    || (actionItem?.cooldownEndTime ?? 0) > get_mission_time())

let isWeaponAvailable = @(weapon) weapon.count != 0 || (weapon.endTime ?? 0) > get_mission_time()

function useShortcut(shortcutId) {
  toggleShortcut(shortcutId)
  updateActionBarDelayed()
}

function useShortcutOn(shortcutId) {
  setShortcutOn(shortcutId)
  updateActionBarDelayed()
}
let mkBtnBg = @(size, color) {
  size = [size, size]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#hud_bg_round_bg.svg:{size}:{size}")
  color
}

function mkCircleProgressBg(size, actionItem, onFinishExt = @() playSound("weapon_primary_ready")) {
  let { id = "", available = true, cooldownEndTime = 0, cooldownTime = 1 } = actionItem

  let misTime = get_mission_time()
  let hasCooldown = available && cooldownEndTime > misTime
  let cooldownLeft = hasCooldown ? cooldownEndTime - misTime : 0
  let animations = [
    {
      prop = AnimProp.scale, duration = 0.2,
      from = [1.0, 1.0], to = [1.2, 1.2], easing = CosineFull,
      trigger = $"action_cd_finish_{id}"
    }
  ]
  if (hasCooldown)
    animations.append({
      prop = AnimProp.fValue, duration = cooldownLeft, play = true,
      from = 1.0 - (cooldownLeft / max(cooldownTime, 1.0)), to = 1.0,
      function onFinish() {
        onFinishExt()
        anim_start($"action_cd_finish_{id}")
      }
    })

  let { empty, ready, broken, noAmmo } = btnBgColor
  return {
    key = $"action_bg_{id}_{cooldownEndTime}"
    size = [size, size]
    rendObj = ROBJ_PROGRESS_CIRCULAR
    image = Picture($"ui/gameuiskin#hud_bg_round_bg.svg:{size}:{size}:P")
    fgColor = !isActionAvailable(actionItem) ? noAmmo
      : (actionItem?.broken ?? false) ? broken
      : ready
    bgColor = empty
    fValue = 1.0
    transform = {}
    animations
  }
}

function mkCircleProgressBgWeapon(size, id, weaponData, isAvailable, onFinishExt = @() playSound("weapon_primary_ready")) {
  let { endTime = 0, time = 1 } = weaponData
  let misTime = get_mission_time()
  let hasCooldown = endTime > misTime
  let cooldownLeft = hasCooldown ? endTime - misTime : 0
  let animations = [
    {
      prop = AnimProp.scale, duration = 0.2,
      from = [1.0, 1.0], to = [1.2, 1.2], easing = CosineFull,
      trigger = $"action_cd_finish_{id}"
    }
  ]

  if (hasCooldown)
    animations.append({
      prop = AnimProp.fValue, duration = cooldownLeft, play = true,
      from = 1.0 - (cooldownLeft / max(time, 1.0)), to = 1.0,
      function onFinish() {
        onFinishExt()
        anim_start($"action_cd_finish_{id}")
      }
    })

  let { empty, ready, noAmmo } = btnBgColor
  return {
    key = $"action_bg_{id}_{endTime}"
    size = [size, size]
    rendObj = ROBJ_PROGRESS_CIRCULAR
    image = Picture($"ui/gameuiskin#hud_bg_round_bg.svg:{size}:{size}:P")
    fgColor = isAvailable ? ready : noAmmo
    bgColor = empty
    fValue = 1.0
    transform = {}
    animations
  }
}

let mkBtnBorder = @(size, isAvailable, stateFlags) @() {
  watch = stateFlags
  size = [size, size]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#hud_bg_round_border.svg:{size}:{size}:P")
  color = stateFlags.value & S_ACTIVE ? borderColorPushed
    : !isAvailable ? borderNoAmmoColor
    : borderColor
}

function mkCircleGlare(baseSize, id) {
  let size = (1.15 * baseSize).tointeger()
  let trigger = $"action_cd_finish_{id}"
  return {
    size = [size, size]
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    rendObj = ROBJ_MASK
    image = Picture($"ui/gameuiskin#hud_bg_round_glare_mask.svg:{size}:{size}:P")
    clipChildren = true
    children = {
      size = [0.4 * size, 2 * size]
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      rendObj = ROBJ_IMAGE
      image = gradTranspDoubleSideX
      color = 0x00A0A0A0
      transform = { rotate = 25, translate = [-size, -size] }
      animations = [{
        prop = AnimProp.translate, from = [-size, -size], to = [0.5 * size, 0.5 * size], duration = 0.4,
        delay = 0.05, trigger
      }]
    }

    transform = { scale = [0.0, 0.0] } //zero size mask will not render. So just optimization
    animations = [{ prop = AnimProp.scale, from = [1.0, 1.0], to = [1.0, 1.0], duration = 0.5, trigger }]
  }
}

let mkBtnImage = @(size, image, color = 0xFFFFFFFF) {
  rendObj = ROBJ_IMAGE
  size = [size, size]
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  image = Picture($"{image}:{size}:{size}")
  keepAspect = KEEP_ASPECT_FIT
  color
}

let circleBtnEditViewCtor = @(size, imgSize) @(image) {
  size = [size, size]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#hud_bg_round_border.svg:{size}:{size}:P")
  color = borderColor
  children = [
    mkBtnBg(size, btnBgColor.empty)
    mkBtnImage(imgSize, image)
  ]
}
let mkCircleBtnEditView = circleBtnEditViewCtor(buttonSize, buttonImgSize)
let mkBigCircleBtnEditView = circleBtnEditViewCtor(bigButtonSize, bigButtonImgSize)

let countTextStyle = {
  rendObj = ROBJ_TEXT
  vplace = ALIGN_BOTTOM
  fontFxColor = 0xFF000000
  fontFxFactor = 50
  fontFx = FFT_GLOW
}.__update(fontVeryTiny)

let mkCountTextRight = @(text, color)
  countTextStyle.__merge({
    pos = [pw(80), ph(-90)]
    color
    text
  })

let mkCountTextLeft = @(text, color)
  countTextStyle.__merge({
    hplace = ALIGN_RIGHT
    pos = [pw(-80), ph(-90)]
    color
    text
  })

let waitForAimIcon = {
  rendObj = ROBJ_IMAGE
  size = [aimImageSize, aimImageSize]
  pos = [0, 0.5 * aimImageSize]
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_CENTER
  valign = ALIGN_BOTTOM
  image = Picture($"ui/gameuiskin#hud_debuff_rotation.svg:{aimImageSize}:{aimImageSize}")
  keepAspect = KEEP_ASPECT_FIT
  animations = wndSwitchAnim
}

let defShortcutOvr = { hplace = ALIGN_CENTER, vplace = ALIGN_CENTER, pos = [0, ph(-50)] }

let primStateFlags = Watched(0) //same state flags for all primary buttons on the screen
let primGroup = ElemGroup()
function mkCircleTankPrimaryGun(actionItem, key = "btn_weapon_primary", countCtor = mkCountTextLeft) {
  let isDisabled = mkIsControlDisabled("ID_FIRE_GM")
  return function() {
    let isAvailable = isActionAvailable(actionItem) && !isDisabled.get()
    let { count, countEx, isBulletBelt = false } = actionItem
    let isWaitForAim = !(actionItem?.aimReady ?? true)
    let isWaitToShoot = !allowShoot.value && !primaryRocketGun.value
    let color = !isAvailable || isWaitToShoot || (primaryRocketGun.value && isWaitForAim) ? disabledColor : 0xFFFFFFFF
    let isContinuous = actionItem.isBulletBelt
    let image = weaponTouchIcons?[actionItem.weaponName] ?? "ui/gameuiskin#hud_main_weapon_fire.svg"
    function onTouchBegin() {
      if (isWaitForAim && (isWaitToShoot || primaryRocketGun.value))
        addCommonHint(loc("hints/wait_for_aiming"))
      else if (isActionAvailable(actionItem)) {
        if (isContinuous)
          useShortcutOn("ID_FIRE_GM")
        else
          useShortcut("ID_FIRE_GM")
      }
    }

    let res = isContinuous
      ? mkContinuousButtonParams(onTouchBegin, @() setShortcutOff("ID_FIRE_GM"), "ID_FIRE_GM", primStateFlags)
          .__update({ behavior = Behaviors.TouchAreaOutButton })
      : {
          behavior = Behaviors.Button
          onElemState = @(v) primStateFlags(v)
          hotkeys = mkGamepadHotkey("ID_FIRE_GM")
          onClick = onTouchBegin
        }

    return res.__update({ //warning disable: -unwanted-modification
      watch = [allowShoot, primaryRocketGun, isDisabled]
      key
      size = [bigButtonSize, bigButtonSize]
      group = primGroup
      eventPassThrough = true
      children = [
        mkCircleProgressBg(bigButtonSize, actionItem)
        mkBtnBorder(bigButtonSize, isAvailable, primStateFlags)
        mkBtnImage(bigButtonImgSize, image, color)
        count < 0 ? null : countCtor(isBulletBelt ? $"{count}/{countEx}" : count, color)
        isWaitForAim ? waitForAimIcon : null
        mkCircleGlare(bigButtonSize, actionItem?.id)
        mkGamepadShortcutImage("ID_FIRE_GM", defShortcutOvr)
      ]
    })
  }
}

function mkCircleTankMachineGun(actionItem) {
  let isDisabled = mkIsControlDisabled("ID_FIRE_GM_MACHINE_GUN")
  let stateFlags = Watched(0)
  return function() {
    let isAvailable = isActionAvailable(actionItem) && !isDisabled.get()
    let isWaitForAim = !(actionItem?.aimReady ?? true)
    let isWaitToShoot = !allowShoot.value && !primaryRocketGun.value
    let color = !isAvailable || isWaitToShoot || (primaryRocketGun.value && isWaitForAim) ? disabledColor : 0xFFFFFFFF
    let res = mkContinuousButtonParams(
      function onTouchBegin() {
        if (isWaitForAim && (isWaitToShoot || primaryRocketGun.value))
          addCommonHint(loc("hints/wait_for_aiming"))
        else if (isActionAvailable(actionItem))
          useShortcutOn("ID_FIRE_GM_MACHINE_GUN")
      },
      @() setShortcutOff("ID_FIRE_GM_MACHINE_GUN"),
      "ID_FIRE_GM_MACHINE_GUN",
      stateFlags
    )
    return res.__update({
      watch = [allowShoot, primaryRocketGun, isDisabled]
      key = "btn_machinegun"
      size = [buttonSize, buttonSize]
      behavior = Behaviors.TouchAreaOutButton
      eventPassThrough = true
      children = [
        mkCircleProgressBg(buttonSize, actionItem)
        mkBtnBorder(buttonSize, isAvailable, stateFlags)
        mkBtnImage(buttonImgSize, "ui/gameuiskin#hud_aircraft_machine_gun.svg", color)
        actionItem.count < 0 ? null : mkCountTextLeft(actionItem.count, color)
        isWaitForAim ? waitForAimIcon : null
        mkGamepadShortcutImage("ID_FIRE_GM_MACHINE_GUN", defShortcutOvr)
      ]
    })
  }
}

let mkCircleTankSecondaryGun = @(shortcutId, img = null) @(actionItem) function() {
  let isAvailable = isActionAvailable(actionItem)
  let isWaitForAim = !(actionItem?.aimReady ?? true)
  let isWaitToShoot = !allowShoot.value && !primaryRocketGun.value
  let color = !isAvailable || isWaitToShoot || (primaryRocketGun.value && isWaitForAim) ? disabledColor : 0xFFFFFFFF
  let stateFlags = Watched(0)
  let image = weaponTouchIcons?[actionItem.weaponName] ?? img
  let res = mkContinuousButtonParams(
    function onTouchBegin() {
      if (isWaitForAim && (isWaitToShoot || primaryRocketGun.value))
        addCommonHint(loc("hints/wait_for_aiming"))
      else if (isActionAvailable(actionItem))
        useShortcutOn(shortcutId)
    },
    @() setShortcutOff(shortcutId),
    shortcutId,
    stateFlags
  )

  return res.__update({
    watch = [allowShoot, primaryRocketGun]
    key = "btn_weapon_secondary"
    size = [buttonSize, buttonSize]
    eventPassThrough = true
    children = [
      mkCircleProgressBg(buttonSize, actionItem)
      mkBtnBorder(buttonSize, isAvailable, stateFlags)
      mkBtnImage(buttonImgSize, image,  color)
      actionItem.count < 0 ? null : mkCountTextLeft(actionItem.count, color)
      isWaitForAim ? waitForAimIcon : null
      mkGamepadShortcutImage(shortcutId, defShortcutOvr)
    ]
  })
}

let weaponryItemStateFlags = {}

function getWeapStateFlags(key) {
  if (key not in weaponryItemStateFlags)
    weaponryItemStateFlags[key] <- Watched(0)
  return weaponryItemStateFlags[key]
}

let lowerCamera = @() lowerAircraftCamera(true)

function mkCircleWeaponryItem(shortcutId, weapon, hasWeapon, img, eventPassThrough, canLowerCamera){
  let isDisabled = mkIsControlDisabled(shortcutId)
  let isAvailable = Computed(@() isWeaponAvailable(weapon.get()) && !isDisabled.get())
  let stateFlags = getWeapStateFlags(shortcutId)
  local isTouchPushed = false
  local isHotkeyPushed = false
  function onStopTouch() {
    isTouchPushed = false
    if (canLowerCamera) {
      clearTimer(lowerCamera)
      lowerAircraftCamera(false)
    }
    unmarkWeapKeyHold(shortcutId)
    if (shortcutId in userHoldWeapInside.value)
      userHoldWeapInside.mutate(@(v) v.$rawdelete(shortcutId))
  }

  function onButtonReleaseWhileActiveZone() {
    onStopTouch()
    useShortcut(shortcutId)
  }

  function onButtonPush() {
    if (canLowerCamera)
      resetTimeout(0.3, lowerCamera)
    markWeapKeyHold(shortcutId)
    userHoldWeapInside.mutate(@(v) v[shortcutId] <- true)
  }

  function onTouchBegin() {
    isTouchPushed = true
    onButtonPush()
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

  let res = mkContinuousButtonParams(onStatePush, onStateRelease, shortcutId, stateFlags)
  return @() !hasWeapon.get() ? { watch = weapon, key = shortcutId }
    : res.__update({
      watch = [isDisabled, isAvailable]
      size = [buttonSize, buttonSize]
      behavior = Behaviors.TouchAreaOutButton
      eventPassThrough
      zoneRadiusX
      zoneRadiusY
      onTouchInsideChange = @(isInside) userHoldWeapInside.mutate(@(v) v[shortcutId] <- isInside)
      onTouchInterrupt = onStopTouch
      onTouchBegin
      onTouchEnd = onButtonReleaseWhileActiveZone
      children = [
        @() {
          watch = weapon
          size = flex()
          children = mkCircleProgressBgWeapon(buttonSize, shortcutId, weapon.get(), isAvailable.get())
        }
        mkBtnBorder(buttonSize, isAvailable.get(), stateFlags)
        mkBtnZone(shortcutId, zoneRadiusX, zoneRadiusY)
        mkBtnImage(buttonImgSize, img)
        @() {
          watch = [weapon, isAvailable]
        }.__update(weapon.get().count < 0 ? {}
          : mkCountTextLeft(weapon.get().count, isAvailable.get() ? 0xFFFFFFFF : disabledColor))
        mkCircleGlare(buttonSize, shortcutId)
        mkGamepadShortcutImage(shortcutId, defShortcutOvr)
      ]
  })
}

function mkCirclePlaneCourseGuns() {
  let shortcutId = "ID_FIRE_COURSE_GUNS"
  let stateFlags = Watched(0)

  let mGunsDisabled = mkIsControlDisabled("ID_FIRE_MGUNS")
  let cannonsDisabled = mkIsControlDisabled("ID_FIRE_CANNONS")

  let hasAnyWeapon = Computed(@() hasMGun0.get() || hasCanon0.get())
  let isAnyWeaponAvailable = Computed(@() (isWeaponAvailable(MGun0.get()) && !mGunsDisabled.get())
    || (isWeaponAvailable(Cannon0.get()) && !cannonsDisabled.get()))
  let totalBullets = Computed(@() (hasMGun0.get() ? MGun0.get().count : 0) + (hasCanon0.get() ? Cannon0.get().count : 0))
  let availableWeapon = Computed(@() hasMGun0.get() && !mGunsDisabled.value
      && (MGun0.get().count > 0  || !hasCanon0.get() || cannonsDisabled.value || MGun0.get().endTime < Cannon0.get().endTime)
    ? MGun0.get()
    : Cannon0.get())

  function onTouchBegin() {
    setShortcutOn("ID_FIRE_MGUNS")
    setShortcutOn("ID_FIRE_CANNONS")
    updateActionBarDelayed()
  }

  function onTouchEnd() {
    setShortcutOff("ID_FIRE_MGUNS")
    setShortcutOff("ID_FIRE_CANNONS")
  }

  let res = mkContinuousButtonParams(onTouchBegin, onTouchEnd, shortcutId, stateFlags)
    .__update({
      behavior = Behaviors.TouchAreaOutButton
      eventPassThrough = true
    })

  return @() !hasAnyWeapon.get() ? { watch = hasAnyWeapon, key = shortcutId }
    : res.__merge({
        watch = [hasAnyWeapon, isAnyWeaponAvailable]
        size = [bigButtonSize, bigButtonSize]
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        children = [
          @() {
            watch = availableWeapon
            size = flex()
            children = mkCircleProgressBgWeapon(bigButtonSize, "course_gun", availableWeapon.get(), isAnyWeaponAvailable.get())
          }
          mkBtnBorder(bigButtonSize, isAnyWeaponAvailable.get(), stateFlags)
          mkBtnImage(bigButtonImgSize, "ui/gameuiskin#hud_aircraft_canons.svg", isAnyWeaponAvailable.get() ? 0xFFFFFFFF : disabledColor)
          @() {
            watch = [totalBullets, isAnyWeaponAvailable]
          }.__update(totalBullets.value < 0 ? {}
            : mkCountTextLeft(totalBullets.value, isAnyWeaponAvailable.get() ? 0xFFFFFFFF : disabledColor))
          mkCircleGlare(bigButtonSize, "course_gun")
          mkGamepadShortcutImage(shortcutId, defShortcutOvr)
        ]
      })
}

function mkCirclePlaneCourseGunsSingle(shortcutId, weapon, hasWeapon,
  btnSize = buttonSize, btnImgSize = buttonImgSize
) {
  let stateFlags = Watched(0)

  let isDisabled = mkIsControlDisabled(shortcutId)
  let isAvailable = Computed(@() isWeaponAvailable(weapon.get()) && !isDisabled.get())

  function onTouchBegin() {
    setShortcutOn(shortcutId)
    updateActionBarDelayed()
  }
  let onTouchEnd = @() setShortcutOff(shortcutId)

  let res = mkContinuousButtonParams(onTouchBegin, onTouchEnd, shortcutId, stateFlags)
    .__update({
      behavior = Behaviors.TouchAreaOutButton
      eventPassThrough = true
    })

  return @() !hasWeapon.get() ? { watch = hasWeapon, key = shortcutId }
    : res.__merge({
        watch = [hasWeapon, isAvailable]
        size = [btnSize, btnSize]
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        children = [
          @() {
            watch = weapon
            size = flex()
            children = mkCircleProgressBgWeapon(btnSize, shortcutId, weapon.get(), isAvailable.get())
          }
          mkBtnBorder(btnSize, isAvailable.get(), stateFlags)
          mkBtnImage(btnImgSize, "ui/gameuiskin#hud_aircraft_canons.svg", isAvailable.get() ? 0xFFFFFFFF : disabledColor)
          @() {
            watch = [weapon, isAvailable]
          }.__update(weapon.get().count < 0 ? {}
            : mkCountTextLeft(weapon.get().count, isAvailable.get() ? 0xFFFFFFFF : disabledColor))
          mkCircleGlare(btnSize, shortcutId)
          mkGamepadShortcutImage(shortcutId, defShortcutOvr)
        ]
      })
}

function mkCircleLockBtn(shortcutId){
  let stateFlags = Watched(0)
  return {
    key = shortcutId
    size = [buttonSize, buttonSize]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    behavior = Behaviors.Button
    eventPassThrough = true
    onElemState = @(v) stateFlags(v)
    onClick = @() toggleShortcut(shortcutId)
    hotkeys = mkGamepadHotkey(shortcutId)
    children = [
      @() {
        watch = [stateFlags, canLock]
        size = [buttonSize, buttonSize]
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#hud_bg_round_border.svg:{buttonSize}:{buttonSize}:P")
        color = (stateFlags.value & S_ACTIVE) != 0 ? borderColorPushed : canLock.value ? borderColor: borderNoAmmoColor
      }
      lockButtonIcon(targetTrackingImgSize, targetTrackingOffImgSize)
      mkCircleGlare(buttonSize, "lock")
    ]
  }
}

function mkCircleZoom(zoomInIcon = "ui/gameuiskin#hud_tank_binoculars_zoom.svg", zoomOutIcon = "ui/gameuiskin#hud_tank_binoculars.svg" ) {
  let stateFlags = Watched(0)
  let isDisabled = mkIsControlDisabled("ID_ZOOM_TOGGLE")
  let imgSize = (0.8 * buttonSize).tointeger()
  return @() {
    watch = [canZoom, isInZoom, isDisabled]
    key = "btn_zoom_circle"
    size = [buttonSize, buttonSize]
    behavior = Behaviors.Button
    eventPassThrough = true
    hotkeys = mkGamepadHotkey("ID_ZOOM_TOGGLE")
    function onClick() {
      if (isDisabled.value)
        return
      if (canZoom.value)
        toggleShortcut("ID_ZOOM_TOGGLE")
      else
        addCommonHint(loc("hints/select_enemy_to_aim"))
    }
    onElemState = @(v) stateFlags(v)
    children = [
      mkBtnBg(buttonSize, btnBgColor.empty)
      mkBtnBorder(buttonSize, canZoom.value && !isDisabled.value, stateFlags)
      mkBtnImage(imgSize,
        isInZoom.value ? zoomInIcon : zoomOutIcon,
        isDisabled.value ? disabledColor : 0xFFFFFFFF)
      isDisabled.value ? null
        : mkGamepadShortcutImage("ID_ZOOM_TOGGLE", defShortcutOvr)
    ]
  }
}

function mkCircleTargetTrackingBtn() {
  let stateFlags = Watched(0)
  let imgSize = (0.8 * buttonSize).tointeger()
  let color = Computed(@() isTrackingActive.value ? 0xFFFFFFFF : disabledColor)
  let bgColor = Computed(@() isTrackingActive.value ? btnBgColor.ready : btnBgColor.empty)

  return @() {
    watch = isTrackingActive
    key = "btn_target_tracking_circle"
    size = [bigButtonSize, bigButtonSize]
    behavior = Behaviors.Button
    eventPassThrough = true
    hotkeys = mkGamepadHotkey("ID_TOGGLE_TARGET_TRACKING")
    onClick = @() toggleShortcut("ID_TOGGLE_TARGET_TRACKING")
    onElemState = @(v) stateFlags(v)
    children = [
      mkBtnBg(bigButtonSize, bgColor.value)
      mkBtnBorder(bigButtonSize, canZoom.value, stateFlags)
      mkBtnImage(imgSize, "ui/gameuiskin#hud_tank_target_tracking.svg", color.value)
      mkGamepadShortcutImage("ID_TOGGLE_TARGET_TRACKING", defShortcutOvr)
    ]
  }
}

function mkSimpleCircleTouchBtn(image, shortcutId, ovr = {}) {
  let stateFlags = Watched(0)
  let imgSize = (0.9 * buttonSize).tointeger()
  return @() {
    watch = [canZoom, isInZoom]
    key = "btn_zoom_circle"
    size = [buttonSize, buttonSize]
    behavior = Behaviors.TouchScreenButton
    eventPassThrough = true
    hotkeys = mkGamepadHotkey(shortcutId)
    onTouchBegin = @() useShortcutOn(shortcutId)
    onTouchEnd = @() setShortcutOff(shortcutId)
    onElemState = @(v) stateFlags(v)
    children = [
      mkBtnBg(buttonSize, btnBgColor.empty)
      mkBtnBorder(buttonSize, true, stateFlags)
      mkBtnImage(imgSize, image)
      mkGamepadShortcutImage(shortcutId, defShortcutOvr)
    ]
  }.__update(ovr)
}

let fwStateFlags = Watched(0)
function mkCircleFireworkBtn(actionItem) {
  let isDisabled = mkIsControlDisabled("ID_FIREWORK")
  return function() {
    let isAvailable = isActionAvailable(actionItem) && !isDisabled.get()
    let { count } = actionItem
    let color = !isAvailable ? disabledColor : 0xFFFFFFFF
    return {
      watch = isDisabled
      key = fwStateFlags
      size = [buttonSize, buttonSize]
      behavior = Behaviors.Button
      onElemState = @(v) fwStateFlags(v)
      hotkeys = mkGamepadHotkey("ID_FIREWORK")
      onClick = @() useShortcut("ID_FIREWORK")
      children = [
        mkCircleProgressBg(buttonSize, actionItem)
        mkBtnBorder(buttonSize, isAvailable, fwStateFlags)
        mkBtnImage(buttonImgSize, "ui/gameuiskin#hud_ammo_fireworks.svg", color)
        count < 0 ? null : mkCountTextLeft(count, color)
        mkCircleGlare(buttonSize, actionItem?.id)
        mkGamepadShortcutImage("ID_FIREWORK", defShortcutOvr)
      ]
    }
  }
}

return {
  mkCircleTankPrimaryGun
  mkCircleTankMachineGun
  mkCircleTankSecondaryGun
  mkCircleZoom
  mkCircleLockBtn
  mkSimpleCircleTouchBtn
  mkCountTextRight
  mkCircleTargetTrackingBtn
  mkCircleFireworkBtn
  mkCirclePlaneCourseGuns
  mkCirclePlaneCourseGunsSingle
  mkCircleWeaponryItem

  mkCircleBtnEditView
  mkBigCircleBtnEditView

  buttonSize
  buttonImgSize
  bigButtonSize
  bigButtonImgSize
}