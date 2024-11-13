from "%globalsDarg/darg_library.nut" import *
let { sqrt } = require("math")
let { get_mission_time } = require("mission")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { playSound } = require("sound_wt")
let { TouchAreaOutButton, TouchScreenButton } = require("wt.behaviors")
let { getScaledFont } = require("%globalsDarg/fontScale.nut")
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
let { Cannon0, MGun0, hasCanon0, hasMGun0, AddGun, hasAddGun,
  TurretsVisible, TurretsReloading, TurretsEmpty
} = require("%rGui/hud/airState.nut")
let { markWeapKeyHold, unmarkWeapKeyHold, userHoldWeapInside
} = require("%rGui/hud/currentWeaponsStates.nut")
let { mkBtnZone, lockButtonIcon, canLock, defShortcutOvr}  = require("hudButtonsPkg.nut")
let { lowerAircraftCamera } = require("camera_control")
let { playHapticPattern } = require("hapticVibration")
let { getOptValue, OPT_HAPTIC_INTENSITY_ON_SHOOT } = require("%rGui/options/guiOptions.nut")
let { HAPT_SHOOT_ITEM } = require("%rGui/hud/hudHaptic.nut")

let bigButtonSize = hdpxi(150)
let bigButtonImgSize = (0.65 * bigButtonSize + 0.5).tointeger()
let buttonSize = hdpxi(120)
let airButtonSize = hdpxi(113)
let buttonImgSize = (0.65 * buttonSize + 0.5).tointeger()
let buttonAirImgSize = (0.65 * airButtonSize + 0.5).tointeger()
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

let mkCircleBg = @(size) {
  size = [size, size]
  rendObj = ROBJ_PROGRESS_CIRCULAR
  image = Picture($"ui/gameuiskin#hud_bg_round_bg.svg:{size}:{size}:P")
  fValue = 1.0
  transform = {}
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
  return mkCircleBg(size).__update({
    key = $"action_bg_{id}_{cooldownEndTime}"
    fgColor = !isActionAvailable(actionItem) ? noAmmo
      : (actionItem?.broken ?? false) ? broken
      : ready
    bgColor = empty
    animations
  })
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
  return mkCircleBg(size).__update({
    key = $"action_bg_{id}_{endTime}"
    fgColor = isAvailable ? ready : noAmmo
    bgColor = empty
    animations
  })
}

function mkCircleBgWeapon(size, id, isAvailable) {
  let { empty, ready, noAmmo } = btnBgColor
  return mkCircleBg(size).__update({
    key = $"action_bg_{id}"
    fgColor = isAvailable ? ready : noAmmo
    bgColor = empty
  })
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

let mkBorderPlane = @(size, isAvailable, stateFlags, scale = 1) @() {
  watch = stateFlags
  size = [size, size]
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = hdpx(3 * scale)
  fillColor = 0
  commands = [
    [VECTOR_ELLIPSE, 50, 50, 50, 50],
  ]
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

let circleBtnPlaneEditViewCtor = @(size, imgSize) @(image) {
  size = [size, size]
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = hdpx(3)
  fillColor = 0
  commands = [
    [VECTOR_ELLIPSE, 50, 50, 50, 50],
  ]
  color = borderColor
  children = [
    mkBtnBg(size, btnBgColor.empty)
    mkBtnImage(imgSize, image)
  ]
}

let mkCircleBtnEditView = circleBtnEditViewCtor(buttonSize, buttonImgSize)
let mkCircleBtnPlaneEditView = circleBtnPlaneEditViewCtor(airButtonSize, buttonAirImgSize)
let mkBigCircleBtnEditView = circleBtnEditViewCtor(bigButtonSize, bigButtonImgSize)
let mkBigCirclePlaneBtnEditView = circleBtnPlaneEditViewCtor(bigButtonSize, bigButtonImgSize)


let countTextFont = fontVeryTinyShaded

let mkCountTextRight = @(text, color, scale = 1) {
  rendObj = ROBJ_TEXT
  vplace = ALIGN_BOTTOM
  pos = [pw(80), ph(-90)]
  color
  text
}.__update(getScaledFont(countTextFont, scale))

let mkCountTextLeft = @(text, color, scale = 1) {
  rendObj = ROBJ_TEXT
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  pos = [pw(-80), ph(-90)]
  color
  text
}.__update(getScaledFont(countTextFont, scale))

function mkCountTextLeftUpperlist(btnSize, scale, count) {
  let font = getScaledFont(countTextFont, scale)
  let { fontSize } = font
  let gap = fontSize / 5
  let step = fontSize + gap
  let offset = fontSize * 3 / 4
  return array(count)
    .map(function(_, i) {
      let y = offset + i * step
      let yExt = btnSize / 2 - y + (y - step / 2 > btnSize / 2 ? step : 0)
      let pos = [-sqrt(btnSize * btnSize / 4 - yExt * yExt) - btnSize / 2, -btnSize + y]
      return @(ovr) {
        rendObj = ROBJ_TEXT
        vplace = ALIGN_BOTTOM
        hplace = ALIGN_RIGHT
        pos
      }.__update(font, ovr)
    })
}

function mkWaitForAimIcon(scale) {
  let size = scaleEven(aimImageSize, scale)
  return {
    rendObj = ROBJ_IMAGE
    size = [size, size]
    pos = [0, 0.5 * size]
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_CENTER
    valign = ALIGN_BOTTOM
    image = Picture($"ui/gameuiskin#hud_debuff_rotation.svg:{size}:{size}")
    keepAspect = KEEP_ASPECT_FIT
    animations = wndSwitchAnim
  }
}

let primStateFlags = Watched(0) //same state flags for all primary buttons on the screen
let primGroup = ElemGroup()
function mkCircleTankPrimaryGun(actionItem, scale, key = "btn_weapon_primary", countCtor = mkCountTextLeft) {
  let isDisabled = mkIsControlDisabled("ID_FIRE_GM")
  let bgSize = scaleEven(bigButtonSize, scale)
  let imgSize = scaleEven(bigButtonImgSize, scale)
  return function() {
    let isAvailable = isActionAvailable(actionItem) && !isDisabled.get()
    let { count, countEx, isBulletBelt = false, isContinuous = false } = actionItem
    let isWaitForAim = !(actionItem?.aimReady ?? true)
    let isWaitToShoot = !allowShoot.value && !primaryRocketGun.value
    let color = !isAvailable || isWaitToShoot || (primaryRocketGun.value && isWaitForAim) ? disabledColor : 0xFFFFFFFF
    let needContinuous = isBulletBelt || isContinuous
    let image = weaponTouchIcons?[actionItem.weaponName] ?? "ui/gameuiskin#hud_main_weapon_fire.svg"
    function onTouchBegin() {
      if (isWaitForAim && (isWaitToShoot || primaryRocketGun.value))
        addCommonHint(loc("hints/wait_for_aiming"))
      else if (isActionAvailable(actionItem)) {
        if (needContinuous)
          useShortcutOn("ID_FIRE_GM")
        else
          useShortcut("ID_FIRE_GM")
      }
    }

    let res = needContinuous
      ? mkContinuousButtonParams(onTouchBegin, @() setShortcutOff("ID_FIRE_GM"), "ID_FIRE_GM", primStateFlags)
          .__update({ behavior = TouchAreaOutButton, cameraControl = true })
      : {
          behavior = Behaviors.Button
          onElemState = @(v) primStateFlags(v)
          hotkeys = mkGamepadHotkey("ID_FIRE_GM")
          onClick = onTouchBegin
          cameraControl = true
        }

    return res.__update({ //warning disable: -unwanted-modification
      watch = [allowShoot, primaryRocketGun, isDisabled]
      key
      size = [bgSize, bgSize]
      group = primGroup
      children = [
        mkCircleProgressBg(bgSize, actionItem)
        mkBtnBorder(bgSize, isAvailable, primStateFlags)
        mkBtnImage(imgSize, image, color)
        count < 0 ? null : countCtor(isBulletBelt ? $"{count}/{countEx}" : count, color, scale)
        isWaitForAim ? mkWaitForAimIcon(scale) : null
        mkCircleGlare(bgSize, actionItem?.id)
        mkGamepadShortcutImage("ID_FIRE_GM", defShortcutOvr, scale)
      ]
    })
  }
}

function mkCircleTankMachineGun(actionItemW, scale) {
  let isDisabled = mkIsControlDisabled("ID_FIRE_GM_MACHINE_GUN")
  let stateFlags = Watched(0)
  let bgSize = scaleEven(buttonSize, scale)
  let imgSize = scaleEven(buttonImgSize, scale)
  return function() {
    let actionItem = actionItemW.get()
    if (actionItem == null)
      return { watch = actionItemW }

    let isAvailable = isActionAvailable(actionItem) && !isDisabled.get()
    let isWaitForAim = !(actionItem?.aimReady ?? true)
    let isInDeadZone = actionItem?.inDeadzone ?? false
    let color = !isAvailable || (isWaitForAim && isInDeadZone) ? disabledColor : 0xFFFFFFFF
    let res = mkContinuousButtonParams(
      function onTouchBegin() {
        if (isWaitForAim && (!allowShoot.value || isInDeadZone))
          addCommonHint(loc("hints/wait_for_aiming"))
        else if (isActionAvailable(actionItem))
          useShortcutOn("ID_FIRE_GM_MACHINE_GUN")
      },
      @() setShortcutOff("ID_FIRE_GM_MACHINE_GUN"),
      "ID_FIRE_GM_MACHINE_GUN",
      stateFlags
    )
    return res.__update({
      watch = [actionItemW, allowShoot, primaryRocketGun, isDisabled]
      key = "btn_machinegun"
      size = [bgSize, bgSize]
      behavior = TouchAreaOutButton
      cameraControl = true
      children = [
        mkCircleProgressBg(bgSize, actionItem)
        mkBtnBorder(bgSize, isAvailable, stateFlags)
        mkBtnImage(imgSize, "ui/gameuiskin#hud_aircraft_machine_gun.svg", color)
        actionItem.count < 0 ? null : mkCountTextLeft(actionItem.count, color, scale)
        isWaitForAim ? mkWaitForAimIcon(scale) : null
        mkGamepadShortcutImage("ID_FIRE_GM_MACHINE_GUN", defShortcutOvr, scale)
      ]
    })
  }
}

let mkCircleTankSecondaryGun = @(shortcutId, img = null) function(actionItem, scale) {
  let bgSize = scaleEven(buttonSize, scale)
  let imgSize = scaleEven(buttonImgSize, scale)
  return function() {
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
      behavior = Behaviors.Button
      cameraControl = true
      key = "btn_weapon_secondary"
      size = [bgSize, bgSize]
      children = [
        mkCircleProgressBg(bgSize, actionItem)
        mkBtnBorder(bgSize, isAvailable, stateFlags)
        mkBtnImage(imgSize, image,  color)
        actionItem.count < 0 ? null : mkCountTextLeft(actionItem.count, color, scale)
        isWaitForAim ? mkWaitForAimIcon(scale) : null
        mkGamepadShortcutImage(shortcutId, defShortcutOvr, scale)
      ]
    })
  }
}

let weaponryItemStateFlags = {}

function getWeapStateFlags(key) {
  if (key not in weaponryItemStateFlags)
    weaponryItemStateFlags[key] <- Watched(0)
  return weaponryItemStateFlags[key]
}

let lowerCamera = @() lowerAircraftCamera(true)

let mkCircleWeaponryItemCtor = @(shortcutId, weapon, hasWeapon, img, hasCameraControl, canLowerCamera) function(scale) {
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
    let vibrationMult = getOptValue(OPT_HAPTIC_INTENSITY_ON_SHOOT)
    playHapticPattern(HAPT_SHOOT_ITEM, vibrationMult)
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
  res.behavior <- [TouchAreaOutButton]
  if (hasCameraControl)
    res.cameraControl <- true

  let bgSize = scaleEven(airButtonSize, scale)
  let imgSize = scaleEven(buttonImgSize, scale)
  let radiusX = scaleEven(zoneRadiusX, scale)
  let radiusY = scaleEven(zoneRadiusY, scale)
  return @() !hasWeapon.get() ? { watch = weapon, key = shortcutId }
    : res.__update({
      watch = [isDisabled, isAvailable]
      size = [bgSize, bgSize]
      zoneRadiusX = radiusX
      zoneRadiusY = radiusY
      onTouchInsideChange = @(isInside) userHoldWeapInside.mutate(@(v) v[shortcutId] <- isInside)
      onTouchInterrupt = onStopTouch
      onTouchBegin
      onTouchEnd = onButtonReleaseWhileActiveZone
      children = [
        @() {
          watch = weapon
          size = flex()
          children = mkCircleProgressBgWeapon(bgSize, shortcutId, weapon.get(), isAvailable.get())
        }
        mkBorderPlane(bgSize, isAvailable.get(), stateFlags, scale)
        mkBtnZone(shortcutId, radiusX, radiusY)
        mkBtnImage(imgSize, img)
        @() {
          watch = [weapon, isAvailable]
        }.__update(weapon.get().count < 0 ? {}
          : mkCountTextLeft(weapon.get().count, isAvailable.get() ? 0xFFFFFFFF : disabledColor, scale))
        mkCircleGlare(bgSize, shortcutId)
        mkGamepadShortcutImage(shortcutId, defShortcutOvr, scale)
      ]
  })
}

function mkCirclePlaneCourseGuns(btnSizeBase, imgSizeBase, scale) {
  let shortcutId = "ID_FIRE_COURSE_GUNS"
  let stateFlags = Watched(0)
  let btnSize = scaleEven(btnSizeBase, scale)
  let imgSize = scaleEven(imgSizeBase, scale)
  let mkCountTextLeftUpper = mkCountTextLeftUpperlist(btnSize, scale, 3)

  let mGunsDisabled = mkIsControlDisabled("ID_FIRE_MGUNS")
  let cannonsDisabled = mkIsControlDisabled("ID_FIRE_CANNONS")
  let addGunsDisabled = mkIsControlDisabled("ID_FIRE_ADDITIONAL_GUNS")

  let hasAnyWeapon = Computed(@() hasMGun0.get() || hasCanon0.get() || hasAddGun.get())
  let isMgunsAvailable = Computed(@() (hasMGun0.get() && isWeaponAvailable(MGun0.get()) && !mGunsDisabled.get()))
  let isCannonsAvailable = Computed(@() (hasCanon0.get() && isWeaponAvailable(Cannon0.get()) && !cannonsDisabled.get()))
  let isAddGunsAvailable = Computed(@() (hasAddGun.get() && isWeaponAvailable(AddGun.get()) && !addGunsDisabled.get()))
  let isAnyWeaponAvailable = Computed(@() isMgunsAvailable.get() || isCannonsAvailable.get() || isAddGunsAvailable.get())
  let availableWeapon = Computed(@() hasMGun0.get() && !mGunsDisabled.value
      && (MGun0.get().count > 0  || !hasCanon0.get() || cannonsDisabled.value || MGun0.get().endTime < Cannon0.get().endTime)
    ? MGun0.get()
    : Cannon0.get())

  function onTouchBegin() {
    setShortcutOn("ID_FIRE_MGUNS")
    setShortcutOn("ID_FIRE_CANNONS")
    setShortcutOn("ID_FIRE_ADDITIONAL_GUNS")
    updateActionBarDelayed()
  }

  function onTouchEnd() {
    setShortcutOff("ID_FIRE_MGUNS")
    setShortcutOff("ID_FIRE_CANNONS")
    setShortcutOff("ID_FIRE_ADDITIONAL_GUNS")
  }

  let res = mkContinuousButtonParams(onTouchBegin, onTouchEnd, shortcutId, stateFlags)
    .__update({
      behavior = TouchAreaOutButton
      cameraControl = true
    })

  return @() !hasAnyWeapon.get() ? { watch = hasAnyWeapon, key = shortcutId }
    : res.__merge({
        watch = [hasAnyWeapon, isAnyWeaponAvailable]
        size = [btnSize, btnSize]
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        children = [
          @() {
            watch = availableWeapon
            size = flex()
            children = mkCircleProgressBgWeapon(btnSize, "course_gun", availableWeapon.get(), isAnyWeaponAvailable.get())
          }
          mkBorderPlane(btnSize, isAnyWeaponAvailable.get(), stateFlags, scale)
          mkBtnImage(imgSize, "ui/gameuiskin#hud_aircraft_canons.svg", isAnyWeaponAvailable.get() ? 0xFFFFFFFF : disabledColor)
          @() {
            watch = [isCannonsAvailable, isMgunsAvailable, isAddGunsAvailable]
            size = flex()
            valign = ALIGN_CENTER
            halign = ALIGN_CENTER
            children = [
              isCannonsAvailable.get() ? Cannon0 : null,
              isMgunsAvailable.get() ? MGun0 : null,
              isAddGunsAvailable.get() ? AddGun : null,
            ]
              .filter(@(v) v != null)
              .map(@(w, idx) @() mkCountTextLeftUpper[idx]({
                watch = w
                text = w.get().count
                color = w.get().count > 0 ? 0xFFFFFFFF : disabledColor
              }))
          }
          mkCircleGlare(btnSize, "course_gun")
          mkGamepadShortcutImage(shortcutId, defShortcutOvr, scale)
        ]
      })
}

function mkCircleSecondaryGuns(btnSizeBase, imgSizeBase, scale) {
  let shortcutId = "ID_FIRE_MGUNS"
  let stateFlags = Watched(0)
  let btnSize = scaleEven(btnSizeBase, scale)
  let imgSize = scaleEven(imgSizeBase, scale)
  let mkCountTextLeftUpper = mkCountTextLeftUpperlist(btnSize, scale, 2)

  let mGunsDisabled = mkIsControlDisabled("ID_FIRE_MGUNS")
  let addGunsDisabled = mkIsControlDisabled("ID_FIRE_ADDITIONAL_GUNS")

  let hasAnyWeapon = Computed(@() hasMGun0.get() || hasAddGun.get())
  let isMgunsAvailable = Computed(@() (hasMGun0.get() && isWeaponAvailable(MGun0.get()) && !mGunsDisabled.get()))
  let isAddGunsAvailable = Computed(@() (hasAddGun.get() && isWeaponAvailable(AddGun.get()) && !addGunsDisabled.get()))
  let isAnyWeaponAvailable = Computed(@() isMgunsAvailable.get() || isAddGunsAvailable.get())
  let availableWeapon = Computed(@() hasMGun0.get() && !mGunsDisabled.get()
      && (MGun0.get().count > 0 || !hasAddGun.get() || addGunsDisabled.get())
    ? MGun0.get()
    : AddGun.get())

  function onTouchBegin() {
    setShortcutOn("ID_FIRE_MGUNS")
    setShortcutOn("ID_FIRE_ADDITIONAL_GUNS")
    updateActionBarDelayed()
  }

  function onTouchEnd() {
    setShortcutOff("ID_FIRE_MGUNS")
    setShortcutOff("ID_FIRE_ADDITIONAL_GUNS")
  }

  let res = mkContinuousButtonParams(onTouchBegin, onTouchEnd, shortcutId, stateFlags)
    .__update({
      behavior = TouchAreaOutButton
      cameraControl = true
    })

  return @() !hasAnyWeapon.get() ? { watch = hasAnyWeapon, key = shortcutId }
    : res.__merge({
        watch = [hasAnyWeapon, isAnyWeaponAvailable]
        size = [btnSize, btnSize]
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        children = [
          @() {
            watch = availableWeapon
            size = flex()
            children = mkCircleProgressBgWeapon(btnSize, "secondary_gun", availableWeapon.get(), isAnyWeaponAvailable.get())
          }
          mkBorderPlane(btnSize, isAnyWeaponAvailable.get(), stateFlags, scale)
          mkBtnImage(imgSize, "ui/gameuiskin#hud_aircraft_canons.svg", isAnyWeaponAvailable.get() ? 0xFFFFFFFF : disabledColor)
          @() {
            watch = [isMgunsAvailable, isAddGunsAvailable]
            size = flex()
            valign = ALIGN_CENTER
            halign = ALIGN_CENTER
            children = [
              isMgunsAvailable.get() ? MGun0 : null,
              isAddGunsAvailable.get() ? AddGun : null,
            ]
              .filter(@(v) v != null)
              .map(@(w, idx) @() mkCountTextLeftUpper[idx]({
                watch = w
                text = w.get().count
                color = w.get().count > 0 ? 0xFFFFFFFF : disabledColor
              }))
          }
          mkCircleGlare(btnSize, "secondary_gun")
          mkGamepadShortcutImage(shortcutId, defShortcutOvr, scale)
        ]
      })
}

function mkCirclePlaneCourseGunsSingle(shortcutId, weapon, hasWeapon, scale,
  btnSizeBase = buttonSize, btnImgSizeBase = buttonImgSize
) {
  let stateFlags = Watched(0)
  let btnSize = scaleEven(btnSizeBase, scale)
  let btnImgSize = scaleEven(btnImgSizeBase, scale)

  let isDisabled = mkIsControlDisabled(shortcutId)
  let isAvailable = Computed(@() isWeaponAvailable(weapon.get()) && !isDisabled.get())

  function onTouchBegin() {
    setShortcutOn(shortcutId)
    updateActionBarDelayed()
  }
  let onTouchEnd = @() setShortcutOff(shortcutId)

  let res = mkContinuousButtonParams(onTouchBegin, onTouchEnd, shortcutId, stateFlags)
    .__update({
      behavior = TouchAreaOutButton
      cameraControl = true
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
          mkBorderPlane(btnSize, isAvailable.get(), stateFlags, scale)
          mkBtnImage(btnImgSize, "ui/gameuiskin#hud_aircraft_canons.svg", isAvailable.get() ? 0xFFFFFFFF : disabledColor)
          @() {
            watch = [weapon, isAvailable]
          }.__update(weapon.get().count < 0 ? {}
            : mkCountTextLeft(weapon.get().count, isAvailable.get() ? 0xFFFFFFFF : disabledColor, scale))
          mkCircleGlare(btnSize, shortcutId)
          mkGamepadShortcutImage(shortcutId, defShortcutOvr, scale)
        ]
      })
}

function mkCirclePlaneTurretsGuns(btnSizeBase, btnImgSizeBase, scale) {
  let shortcutId = "ID_FIRE_MGUNS"
  let stateFlags = Watched(0)
  let btnSize = scaleEven(btnSizeBase, scale)
  let btnImgSize = scaleEven(btnImgSizeBase, scale)

  let isDisabled = mkIsControlDisabled(shortcutId)
  let isActiveTurretsAvailable = Computed(function() {
    foreach (idx, value in TurretsVisible.get()) {
      if (value && !TurretsReloading.get()[idx] && !TurretsEmpty.get()[idx])
        return true
    }
    return false
  })
  let isAvailable = Computed(@() !isDisabled.get() && isActiveTurretsAvailable.get() && TurretsVisible.get().contains(true))

  function onTouchBegin() {
    setShortcutOn(shortcutId)
    updateActionBarDelayed()
  }
  let onTouchEnd = @() setShortcutOff(shortcutId)

  let res = mkContinuousButtonParams(onTouchBegin, onTouchEnd, shortcutId, stateFlags)
    .__update({
      behavior = TouchAreaOutButton
      cameraControl = true
    })

  return @() res.__merge({
    watch = [isAvailable]
    size = [btnSize, btnSize]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [
      mkCircleBgWeapon(btnSize, shortcutId, isAvailable.get())
      mkBorderPlane(btnSize, isAvailable.get(), stateFlags, scale)
      mkBtnImage(btnImgSize, "ui/gameuiskin#hud_aircraft_machine_gun.svg",
        isAvailable.get() ? 0xFFFFFFFF : disabledColor)
      mkCircleGlare(btnSize, shortcutId)
      mkGamepadShortcutImage(shortcutId, defShortcutOvr, scale)
    ]
  })
}

function mkCircleLockBtn(shortcutId, scale) {
  let stateFlags = Watched(0)
  let isDisabled = mkIsControlDisabled(shortcutId)
  let bgSize = scaleEven(airButtonSize, scale)
  let imgSize = scaleEven(targetTrackingImgSize, scale)
  let offImgSize = scaleEven(targetTrackingOffImgSize, scale)
  return @() {
    watch = isDisabled
    key = shortcutId
    size = [bgSize, bgSize]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    behavior = Behaviors.Button
    cameraControl = true
    onElemState = @(v) stateFlags(v)
    onClick = @() toggleShortcut(shortcutId)
    hotkeys = mkGamepadHotkey(shortcutId)
    children = [
      @() {
        watch = [stateFlags, canLock]
        size = [bgSize, bgSize]
        rendObj = ROBJ_VECTOR_CANVAS
        lineWidth = hdpx(3)
        fillColor = 0
        commands = [
          [VECTOR_ELLIPSE, 50, 50, 50, 50],
        ]
        color = (stateFlags.value & S_ACTIVE) != 0 ? borderColorPushed : canLock.value ? borderColor: borderNoAmmoColor
      }
      lockButtonIcon(imgSize, offImgSize)
      mkCircleGlare(bgSize, "lock")
      isDisabled.get() ? null
        : mkGamepadShortcutImage(shortcutId, defShortcutOvr, scale)
    ]
    transform = {}
    animations = [{ prop = AnimProp.scale, from = [1.0, 1.0], to = [1.2, 1.2], duration = 2.0,  easing = DoubleBlink, trigger = "hint_need_lock_target" }]
  }
}

let mkCircleZoomCtor = @(zoomInIcon = "ui/gameuiskin#hud_tank_binoculars_zoom.svg", zoomOutIcon = "ui/gameuiskin#hud_tank_binoculars.svg" )
  function(scale) {
    let stateFlags = Watched(0)
    let isDisabled = mkIsControlDisabled("ID_ZOOM_TOGGLE")
    let bgSize = scaleEven(buttonSize, scale)
    let imgSize = scaleEven(0.8 * buttonImgSize, scale)
    return @() {
      watch = [canZoom, isInZoom, isDisabled]
      key = "btn_zoom_circle"
      size = [bgSize, bgSize]
      behavior = Behaviors.Button
      cameraControl = true
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
        mkBtnBg(bgSize, btnBgColor.empty)
        mkBtnBorder(bgSize, canZoom.value && !isDisabled.value, stateFlags)
        mkBtnImage(imgSize,
          isInZoom.value ? zoomInIcon : zoomOutIcon,
          isDisabled.value ? disabledColor : 0xFFFFFFFF)
        isDisabled.value ? null
          : mkGamepadShortcutImage("ID_ZOOM_TOGGLE", defShortcutOvr, scale)
      ]
    }
  }

function mkCircleTargetTrackingBtn(scale) {
  let stateFlags = Watched(0)
  let bgSize = scaleEven(buttonSize, scale)
  let imgSize = scaleEven(0.8 * buttonSize, scale)
  let color = Computed(@() isTrackingActive.value ? 0xFFFFFFFF : disabledColor)
  let bgColor = Computed(@() isTrackingActive.value ? btnBgColor.ready : btnBgColor.empty)

  return @() {
    watch = isTrackingActive
    key = "btn_target_tracking_circle"
    size = [bgSize, bgSize]
    behavior = Behaviors.Button
    cameraControl = true
    hotkeys = mkGamepadHotkey("ID_TOGGLE_TARGET_TRACKING")
    onClick = @() toggleShortcut("ID_TOGGLE_TARGET_TRACKING")
    onElemState = @(v) stateFlags(v)
    children = [
      mkBtnBg(bgSize, bgColor.value)
      mkBtnBorder(bgSize, canZoom.value, stateFlags)
      mkBtnImage(imgSize, "ui/gameuiskin#hud_tank_target_tracking.svg", color.value)
      mkGamepadShortcutImage("ID_TOGGLE_TARGET_TRACKING", defShortcutOvr, scale)
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
    behavior = TouchScreenButton
    cameraControl = true
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
function mkCircleFireworkBtn(actionItem, scale) {
  let isDisabled = mkIsControlDisabled("ID_FIREWORK")
  let bgSize = scaleEven(buttonSize, scale)
  let imgSize = scaleEven(buttonImgSize, scale)
  return function() {
    let isAvailable = isActionAvailable(actionItem) && !isDisabled.get()
    let { count } = actionItem
    let color = !isAvailable ? disabledColor : 0xFFFFFFFF
    return {
      watch = isDisabled
      key = fwStateFlags
      size = [bgSize, bgSize]
      behavior = Behaviors.Button
      onElemState = @(v) fwStateFlags(v)
      hotkeys = mkGamepadHotkey("ID_FIREWORK")
      onClick = @() useShortcut("ID_FIREWORK")
      children = [
        mkCircleProgressBg(bgSize, actionItem)
        mkBtnBorder(bgSize, isAvailable, fwStateFlags)
        mkBtnImage(imgSize, "ui/gameuiskin#hud_ammo_fireworks.svg", color)
        count < 0 ? null : mkCountTextLeft(count, color, scale)
        mkCircleGlare(bgSize, actionItem?.id)
        mkGamepadShortcutImage("ID_FIREWORK", defShortcutOvr, scale)
      ]
    }
  }
}

return {
  mkCircleTankPrimaryGun
  mkCircleTankMachineGun
  mkCircleTankSecondaryGun
  mkCircleZoomCtor
  mkCircleLockBtn
  mkSimpleCircleTouchBtn
  mkCountTextRight
  mkCircleTargetTrackingBtn
  mkCircleFireworkBtn
  mkCirclePlaneCourseGuns
  mkCircleSecondaryGuns
  mkCirclePlaneCourseGunsSingle
  mkCirclePlaneTurretsGuns
  mkCircleWeaponryItemCtor

  mkCircleBtnEditView
  mkCircleBtnPlaneEditView
  mkBigCircleBtnEditView
  mkBigCirclePlaneBtnEditView

  mkBorderPlane
  mkBtnImage
  mkCountTextLeft
  mkCircleProgressBgWeapon
  mkCircleGlare
  mkCircleBg

  circleBtnPlaneEditViewCtor

  buttonSize
  buttonImgSize
  bigButtonSize
  bigButtonImgSize
  airButtonSize
  buttonAirImgSize
}