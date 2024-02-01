from "%globalsDarg/darg_library.nut" import *

let { get_mission_time } = require("%globalsDarg/mission.nut")
let { toggleShortcut } = require("%globalScripts/controls/shortcutActions.nut")
let { mkIsControlDisabled } = require("%rGui/controls/disabledControls.nut")
let { updateActionBarDelayed } = require("%rGui/hud/actionBar/actionBarState.nut")
let { touchButtonSize, imageColor, imageDisabledColor, borderWidth, btnBgColor,
  borderColorPushed, borderColor, borderNoAmmoColor, textColor, textDisabledColor
} = require("%rGui/hud/hudTouchButtonStyle.nut")
let { mkGamepadShortcutImage, mkGamepadHotkey } = require("%rGui/controls/shortcutSimpleComps.nut")
let { mkActionBtnGlare } = require("%rGui/hud/weaponsButtonsAnimations.nut")


let cooldownImgSize = (1.42 * touchButtonSize).tointeger()
let rotatedShortcutImageOvr = { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = [0, ph(-70)] }
let fwImageSize = (0.75 * touchButtonSize).tointeger()

function useShortcut(shortcutId) {
  toggleShortcut(shortcutId)
  updateActionBarDelayed()
}

let mkAmmoCount = @(count, isAvailable = true) count < 0 ? null
  : {
      rendObj = ROBJ_TEXT
      vplace = ALIGN_BOTTOM
      fontFxColor = 0xFF000000
      fontFxFactor = 50
      fontFx = FFT_GLOW
      color = isAvailable ? textColor : textDisabledColor
      text = count
    }.__update(fontVeryTiny)

function mkRhombBtnBg(isAvailable, actionItem, onFinishExt = null) {
  let misTime = get_mission_time()
  let { available = true, cooldownEndTime = 0, cooldownTime = 1, id = null } = actionItem
  let hasCooldown = available && cooldownEndTime > misTime
  let cooldownLeft = hasCooldown ? (cooldownEndTime - misTime) : 0
  let cooldown = hasCooldown ? (1 - (cooldownLeft / max(cooldownTime, 1))) : 1
  let { empty, ready, broken, noAmmo } = btnBgColor
  let trigger = $"action_cd_finish_{id}"
  return {
    size = [cooldownImgSize, cooldownImgSize]
    rendObj = ROBJ_PROGRESS_CIRCULAR
    image = Picture($"ui/gameuiskin#hud_weapon_bg.svg:{cooldownImgSize}:{cooldownImgSize}:P")
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

let mkRhombBtnBorder = @(stateFlags, isAvailable) {
  size = flex()
  clipChildren = true
  children = @() {
    watch = stateFlags
    size = flex()
    rendObj = ROBJ_BOX
    borderColor = stateFlags.value & S_ACTIVE ? borderColorPushed
      : !isAvailable ? borderNoAmmoColor
      : borderColor
    borderWidth
  }
  transform = { rotate = 45 }
}

function mkRhombFireworkBtn(actionItem) {
  let stateFlags = Watched(0)
  let isDisabled = mkIsControlDisabled("ID_FIREWORK")
  return @() {
    watch = isDisabled
    key = "btn_firework"
    size = [touchButtonSize, touchButtonSize]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags(v)
    hotkeys = mkGamepadHotkey("ID_FIREWORK")
    onClick = @() useShortcut("ID_FIREWORK")
    children = [
      mkRhombBtnBg(!isDisabled.get(), actionItem)
      mkRhombBtnBorder(stateFlags, !isDisabled.get())
      {
        rendObj = ROBJ_IMAGE
        size = [fwImageSize, fwImageSize]
        image = Picture($"ui/gameuiskin#hud_ammo_fireworks.svg:{fwImageSize}:{fwImageSize}:P")
        keepAspect = true
        color = isDisabled.value ? imageDisabledColor : imageColor
      }
      mkActionBtnGlare(actionItem)
      mkAmmoCount(actionItem.count, !isDisabled.get())
      isDisabled.value ? null
        : mkGamepadShortcutImage("ID_FIREWORK", rotatedShortcutImageOvr)
    ]
  }
}

return {
  mkRhombBtnBg
  mkRhombBtnBorder
  mkAmmoCount

  mkRhombFireworkBtn
}