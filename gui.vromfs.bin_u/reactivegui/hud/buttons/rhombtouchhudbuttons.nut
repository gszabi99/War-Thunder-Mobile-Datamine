from "%globalsDarg/darg_library.nut" import *
let { round } =  require("math")
let { get_mission_time } = require("mission")
let { playSound } = require("sound_wt")
let { getScaledFont } = require("%globalsDarg/fontScale.nut")
let { toggleShortcut } = require("%globalScripts/controls/shortcutActions.nut")
let { mkIsControlDisabled } = require("%rGui/controls/disabledControls.nut")
let { updateActionBarDelayed, actionBarItems } = require("%rGui/hud/actionBar/actionBarState.nut")
let { touchButtonSize, touchSizeForRhombButton, imageColor, imageDisabledColor, borderWidth, btnBgColor,
  borderColorPushed, borderColor, borderNoAmmoColor, textColor, textDisabledColor,
} = require("%rGui/hud/hudTouchButtonStyle.nut")
let { canZoom, isInZoom, groupIsInAir, group2IsInAir, group3IsInAir, group4IsInAir, isInAntiairMode
} = require("%rGui/hudState.nut")
let { hasAimingModeForWeapon, markWeapKeyHold, unmarkWeapKeyHold } = require("%rGui/hud/currentWeaponsStates.nut")
let { addCommonHint } = require("%rGui/hudHints/commonHintLogState.nut")
let { mkGamepadShortcutImage, mkGamepadHotkey } = require("%rGui/controls/shortcutSimpleComps.nut")
let { mkActionBtnGlare } = require("%rGui/hud/weaponsButtonsAnimations.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")


let cooldownImgSize = (1.42 * touchButtonSize).tointeger()
let rotatedShortcutImageOvr = { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = [0, ph(-70)] }
let defImageSize = (0.75 * touchButtonSize).tointeger()

function useShortcut(shortcutId) {
  toggleShortcut(shortcutId)
  updateActionBarDelayed()
}

let isActionAvailable = @(actionItem) (actionItem?.available ?? true)
  && (actionItem.count != 0 || actionItem?.control
    || (actionItem?.cooldownEndTime ?? 0) > get_mission_time())

let mkAmmoCount = @(count, scale, isAvailable = true) count < 0 ? null
  : {
      rendObj = ROBJ_TEXT
      vplace = ALIGN_BOTTOM
      color = isAvailable ? textColor : textDisabledColor
      text = count
    }.__update(getScaledFont(fontVeryTinyShaded, scale))

function mkRhombBtnBg(isAvailable, actionItem, scale, onFinishExt = null) {
  let misTime = get_mission_time()
  let { available = true, cooldownEndTime = 0, cooldownTime = 1, id = null } = actionItem
  let hasCooldown = available && cooldownEndTime > misTime
  let cooldownLeft = hasCooldown ? (cooldownEndTime - misTime) : 0
  let cooldown = hasCooldown ? (1 - (cooldownLeft / max(cooldownTime, 1))) : 1
  let { empty, ready, broken, noAmmo } = btnBgColor
  let trigger = $"action_cd_finish_{id}"
  let size = scaleEven(cooldownImgSize, scale)
  return {
    size = [size, size]
    rendObj = ROBJ_PROGRESS_CIRCULAR
    image = Picture($"ui/gameuiskin#hud_weapon_bg.svg:{size}:{size}:P")
    fgColor = !isAvailable ? noAmmo
      : (actionItem?.broken ?? false) ? broken
      : ready
    bgColor = empty
    fValue = 1.0
    key = $"action_bg_{id}_{cooldownEndTime}"
    transform = {}
    animations = [
      { prop = AnimProp.fValue, from = cooldown, to = 1.0, duration = cooldownLeft, play = true,
        function onFinish() {
          onFinishExt?()
          if (available)
            anim_start(trigger)
        }
      }
      {
        prop = AnimProp.scale, duration = 0.2,
        from = [1.0, 1.0], to = [1.2, 1.2], easing = CosineFull, trigger
      }
    ]
  }
}

let mkRhombBtnBorder = @(stateFlags, isAvailable, scale) {
  size = flex()
  clipChildren = true
  children = @() {
    watch = stateFlags
    size = flex()
    rendObj = ROBJ_BOX
    borderColor = stateFlags.value & S_ACTIVE ? borderColorPushed
      : !isAvailable ? borderNoAmmoColor
      : borderColor
    borderWidth = round(borderWidth * scale)
  }
  transform = { rotate = 45 }
}

function mkRhombSimpleActionBtn(actionItem, shortcutId, image, scale) {
  let stateFlags = Watched(0)
  let isDisabled = mkIsControlDisabled(shortcutId)
  let btnSize = scaleEven(touchButtonSize, scale)
  let btnTouchSize = scaleEven(touchSizeForRhombButton, scale)
  let imgSize = scaleEven(defImageSize, scale)
  return @() {
    watch = isDisabled
    key = shortcutId
    size = [btnSize, btnSize]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [
      mkRhombBtnBg(!isDisabled.get(), actionItem, scale)
      mkRhombBtnBorder(stateFlags, !isDisabled.get(), scale)
      {
        rendObj = ROBJ_IMAGE
        size = [imgSize, imgSize]
        image = Picture($"{image}:{imgSize}:{imgSize}:P")
        keepAspect = true
        color = isDisabled.value ? imageDisabledColor : imageColor
      }
      mkActionBtnGlare(actionItem, btnSize)
      mkAmmoCount(actionItem.count, scale, !isDisabled.get())
      isDisabled.value ? null
        : mkGamepadShortcutImage(shortcutId, rotatedShortcutImageOvr, scale)
      {
        size = [btnTouchSize, btnTouchSize]
        behavior = Behaviors.Button
        cameraControl = true
        onElemState = @(v) stateFlags(v)
        hotkeys = mkGamepadHotkey(shortcutId)
        onClick = @() useShortcut(shortcutId)
      }
    ]
  }
}

let mkRhombFireworkBtn = @(actionItem, scale)
  mkRhombSimpleActionBtn(actionItem, "ID_FIREWORK", "ui/gameuiskin#hud_ammo_fireworks.svg", scale)

function mkAntiairButton(scale) {
  let actionItem = Computed(@() actionBarItems.get()?.AB_MANUAL_ANTIAIR)
  return @() {
    watch = [actionItem, isInAntiairMode]
    children = actionItem.get() == null ? null
      : mkRhombSimpleActionBtn(actionItem.get(), "ID_SHIP_MANUAL_ANTIAIR_TOGGLE",
          isInAntiairMode.get() ? "ui/gameuiskin#hud_ship_selection.svg"
            : "ui/gameuiskin#hud_ship_air_def_mode.svg",
          scale)
  }
}

function mkDivingLockButton(scale) {
  let actionItem = Computed(@() actionBarItems.get()?.AB_DIVING_LOCK)
  return @() {
    watch = actionItem
    children = actionItem.get() == null ? null
      : mkRhombSimpleActionBtn(actionItem.get().__merge({ count = -1 }), "ID_DIVING_LOCK",
          (actionItem.get()?.active ?? true) ? "ui/gameuiskin#hud_submarine_diving.svg"
            : "ui/gameuiskin#hud_submarine_surfacing.svg"
          scale)
  }
}

function mkRhombZoomButton(scale) {
  let shortcutId = "ID_ZOOM_TOGGLE"
  let stateFlags = Watched(0)
  let isDisabled = mkIsControlDisabled(shortcutId)
  let btnSize = scaleEven(touchButtonSize, scale)
  let btnTouchSize = scaleEven(touchSizeForRhombButton, scale)
  let borderW = round(borderWidth * scale).tointeger()
  return @() {
    watch = [canZoom, isDisabled, hasAimingModeForWeapon, isInZoom]
    key = "btn_zoom"
    size = [btnSize, btnSize]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [
      @() {
        watch = [stateFlags, isDisabled, isInZoom, hasAimingModeForWeapon]
        size = flex()
        rendObj = ROBJ_BOX
        borderColor = (stateFlags.value & S_ACTIVE) != 0 ? borderColorPushed
          : (canZoom.value && !isDisabled.value && (isInZoom.value || hasAimingModeForWeapon.value)) ? borderColor
          : borderNoAmmoColor
        borderWidth = borderW
        fillColor = btnBgColor.empty
        transform = { rotate = 45 }
      }
      {
        rendObj = ROBJ_IMAGE
        size = [btnSize, btnSize]
        image = isInZoom.value ? Picture($"ui/gameuiskin#hud_binoculars_zoom.svg:{btnSize}:{btnSize}:P")
          : Picture($"ui/gameuiskin#hud_binoculars.svg:{btnSize}:{btnSize}:P")
        keepAspect = KEEP_ASPECT_FIT
        color = (canZoom.value && !isDisabled.value && (isInZoom.value || hasAimingModeForWeapon.value))
          ? imageColor
          : imageDisabledColor
      }
      isDisabled.value ? null
        : mkGamepadShortcutImage(shortcutId, rotatedShortcutImageOvr, scale)
      {
        size = [btnTouchSize, btnTouchSize]
        behavior = Behaviors.Button
        cameraControl = true
        hotkeys = mkGamepadHotkey(shortcutId)
        onElemState = @(v) stateFlags(v)
        function onClick() {
          if (isDisabled.value)
            return
          if (canZoom.value && ((hasAimingModeForWeapon.value) ||
              (isInZoom.value && !hasAimingModeForWeapon.value))) {
            toggleShortcut(shortcutId)
            return
          }

          if (!canZoom.value) {
            addCommonHint(loc("hints/select_enemy_to_aim"))
            return
          }

          addCommonHint(loc("hints/aiming_not_available_for_weapon"))
        }
      }
    ]
  }
}

let groupsInAirByIdx = [groupIsInAir, group2IsInAir, group3IsInAir, group4IsInAir]

function mkSupportPlaneBtn(actionType, supportCfg, scale) {
  let actionItem = Computed(@() actionBarItems.get()?[actionType])
  let { image, imageSwitch, groupIdx, shortcutId } = supportCfg
  let stateFlags = Watched(0)
  let isGroupInAir = groupsInAirByIdx?[groupIdx] ?? Watched(false)

  let btnSize = scaleEven(touchButtonSize, scale)
  let btnTouchSize = scaleEven(touchSizeForRhombButton, scale)
  let imgSize = scaleEven(defImageSize, scale)
  let groupImgSize = scaleEven(defImageSize * 1.15, scale)

  return function() {
    let watch = [actionItem, isGroupInAir]
    if (actionItem.get() == null)
      return { watch }
    let isAvailable = isActionAvailable(actionItem.get())
    return {
      watch
      size = [btnSize, btnSize]
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = [
        mkRhombBtnBg(isAvailable, actionItem.get(), scale, @() playSound("weapon_secondary_ready"))
        mkRhombBtnBorder(stateFlags, isAvailable, scale)
        isGroupInAir.get()
          ? {
              rendObj = ROBJ_IMAGE
              size = [groupImgSize, groupImgSize]
              pos = [hdpx(3 * scale), 0]
              image = Picture($"{imageSwitch}:{groupImgSize}:{groupImgSize}:P")
              keepAspect = KEEP_ASPECT_FIT
              color = !isAvailable ? imageDisabledColor : imageColor
            }
          : {
              rendObj = ROBJ_IMAGE
              size = [imgSize, imgSize]
              pos = [0, -hdpx(5 * scale)]
              image = Picture($"{image}:{imgSize}:{imgSize}:P")
              keepAspect = KEEP_ASPECT_FIT
              color = !isAvailable ? imageDisabledColor : imageColor
            }
        isGroupInAir.get() ? null : mkAmmoCount(actionItem.get().count, scale)
        mkActionBtnGlare(actionItem.get(), btnSize)
        mkGamepadShortcutImage(shortcutId, rotatedShortcutImageOvr, scale)
        {
          size = [btnTouchSize, btnTouchSize]
          behavior = Behaviors.Button
          cameraControl = true
          hotkeys = mkGamepadHotkey(shortcutId)
          function onClick() {
            if ((actionItem.get()?.cooldownEndTime ?? 0) > get_mission_time())
              return
            toggleShortcut(shortcutId)
          }
          function onElemState(v) {
            if ((v & S_ACTIVE) && actionItem.get() != null)
              markWeapKeyHold(actionType, loc(getUnitLocId(actionItem.get().weaponName)), true)
            else
              unmarkWeapKeyHold(actionType)
            stateFlags.set(v)
          }
        }
      ]
    }
  }
}

return {
  mkRhombBtnBg
  mkRhombBtnBorder
  mkAmmoCount

  mkRhombSimpleActionBtn

  mkRhombFireworkBtn
  mkRhombZoomButton
  mkSupportPlaneBtn
  mkAntiairButton
  mkDivingLockButton
}