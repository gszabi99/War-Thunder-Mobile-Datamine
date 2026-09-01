from "%globalsDarg/darg_library.nut" import *
from "math" import round
from "mission" import get_mission_time
from "%globalScripts/controls/shortcutActions.nut" import toggleShortcut
from "%rGui/controls/shortcutSimpleComps.nut" import mkGamepadHotkey, mkGamepadShortcutImage
from "%rGui/hud/buttons/hudButtonsPkg.nut" import defShortcutOvr
from "%rGui/hud/cooldownComps.nut" import mkItemWithCooldownText
from "%rGui/hud/hudTouchButtonStyle.nut" import touchButtonSize, btnBgStyle, borderColor, borderColorPushed, borderWidth


let defImageSize = (0.75 * touchButtonSize).tointeger()

let mkSquareButtonEditView = @(img){
  size = [touchButtonSize, touchButtonSize]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    @() {
      size = FLEX
      rendObj = ROBJ_BOX
      borderColor = borderColor
      borderWidth
    }
    {
      rendObj = ROBJ_IMAGE
      size = [defImageSize, defImageSize]
      image = Picture($"{img}:{defImageSize}:{defImageSize}:P")
      keepAspect = KEEP_ASPECT_FIT
    }
  ]
}

function mkSimpleSquareButton(shortcutId, img, scale) {
  let stateFlags = Watched(0)
  let bgSize = scaleEven(touchButtonSize, scale)
  let imgSize = scaleEven(defImageSize, scale)
  let borderW = round(borderWidth * scale)
  return @() {
      behavior = Behaviors.Button
      cameraControl = true
      size = [bgSize, bgSize]
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      onClick = @() toggleShortcut(shortcutId)
      onElemState = @(v) stateFlags.set(v)
      hotkeys = mkGamepadHotkey(shortcutId)
      children = [
        @() {
          watch = [stateFlags, btnBgStyle]
          size = FLEX
          rendObj = ROBJ_BOX
          borderColor = (stateFlags.get() & S_ACTIVE) != 0 ? borderColorPushed : borderColor
          borderWidth = borderW
          fillColor = btnBgStyle.get().empty
        }
        {
          rendObj = ROBJ_IMAGE
          size = [imgSize, imgSize]
          image = Picture($"{img}:{imgSize}:{imgSize}:P")
          keepAspect = true
        }
        mkGamepadShortcutImage(shortcutId, defShortcutOvr, scale)
      ]
    }
}

function mkSquareButtonBg(actionItem, isPrimaryStyle, btnStyle, buttonBgSize = touchButtonSize, onFinishExt = null) {
  let misTime = get_mission_time()
  let { available = true, cooldownEndTime = 0, cooldownTime = 1, id = null } = actionItem
  let hasCooldown = available && cooldownEndTime > misTime
  let cooldownLeft = hasCooldown ? (cooldownEndTime - misTime) : 0
  let cooldown = hasCooldown ? (1 - (cooldownLeft / max(cooldownTime, 1))) : 1
  let { empty, ready, broken, noAmmo } = btnStyle
  let trigger = $"action_cd_finish_{id}"
  let item = {
    size = [buttonBgSize, buttonBgSize]
    rendObj = ROBJ_PROGRESS_CIRCULAR
    image = isPrimaryStyle
      ? Picture($"ui/gameuiskin#hud_movement_stop2_bg_loading.svg:{buttonBgSize}:{buttonBgSize}:P")
      : Picture($"ui/gameuiskin#hud_movement_stop2_bg.svg:{buttonBgSize}:{buttonBgSize}:P")
    fgColor = !available ? noAmmo
      : (actionItem?.broken ?? false) ? broken
      : ready
    bgColor = empty
    fValue = isPrimaryStyle ? 0 : 1.0
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
  return mkItemWithCooldownText(id, item, [buttonBgSize, buttonBgSize], hasCooldown, cooldownEndTime)
}

return {
  mkSimpleSquareButton
  mkSquareButtonEditView
  mkSquareButtonBg
}