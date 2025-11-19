from "%globalsDarg/darg_library.nut" import *
let { get_mission_time } = require("mission")
let { getScaledFont } = require("%globalsDarg/fontScale.nut")
let { touchButtonSize, borderWidth, btnBgStyle, imageColor, imageDisabledColor,
  borderColor, borderColorPushed, borderNoAmmoColor, textColor
} = require("%rGui/hud/hudTouchButtonStyle.nut")
let { mkItemWithCooldownText } = require("%rGui/hud/cooldownComps.nut")
let { unitType } = require("%rGui/hudState.nut")
let { isHudPrimaryStyle } = require("%rGui/options/options/hudStyleOptions.nut")
let { hudTransparentColor, hudLightBlackColor } = require("%rGui/style/hudColors.nut")


let svgNullable = @(image, size) ((image ?? "") == "") ? null
  : Picture($"{image}:{size}:{size}:P")

let countHeightUnderActionItem = (0.4 * touchButtonSize).tointeger()
let abShortcutImageOvr = { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = [pw(50), ph(-50)] }

let isAvailableActionItem = @(actionItem) (actionItem?.available ?? true)
  && ((actionItem?.count ?? 0) != 0 || actionItem?.control)

function mkActionItemProgress(actionItem, isAvailable, isPrimaryStyle, btnSize) {
  let { cooldownEndTime = 0, cooldownTime = 1, blockedCooldownEndTime = 0, blockedCooldownTime = 1, id = null
  } = actionItem
  let isBlocked = blockedCooldownEndTime > 0 && cooldownEndTime == 0
  let endTime = isBlocked ? blockedCooldownEndTime : cooldownEndTime
  let time = isBlocked ? blockedCooldownTime : cooldownTime
  let cooldownDuration = endTime - get_mission_time()
  let hasCooldown = isAvailable && cooldownDuration > 0
  let cooldown = hasCooldown ? (1 - (cooldownDuration / max(time, 1))) : 1
  let trigger = $"action_cd_finish_{id}"
  let item = {
    size = [btnSize, btnSize]
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#hud_movement_stop2_bg.svg:{btnSize}:{btnSize}:P")
    color = hudLightBlackColor
    children = @() {
      watch = btnBgStyle
      size = flex()
      rendObj = ROBJ_PROGRESS_CIRCULAR
      fgColor = !isAvailable ? btnBgStyle.get().noAmmo
        : (actionItem?.broken ?? false) ? btnBgStyle.get().broken
        : btnBgStyle.get().ready
      bgColor = btnBgStyle.get().empty
      fValue = isPrimaryStyle ? 0 : 1.0
      key = $"action_bg_{id}_{endTime}_{time}_{isAvailable}"
      animations = [
        { prop = AnimProp.fValue, from = cooldown, to = 1.0, duration = cooldownDuration, play = true
          onFinish = @() isAvailable ? anim_start(trigger) : null
        }
      ]
    }.__update(isPrimaryStyle ? { image = Picture($"ui/gameuiskin#hud_movement_stop2_bg_loading.svg:P") } : {})

    transform = {}
    animations = [{ prop = AnimProp.scale, duration = 0.2,
      from = [1.0, 1.0], to = [1.2, 1.2], easing = CosineFull, trigger }]
  }
  return mkItemWithCooldownText(id, item, flex(), hasCooldown, endTime)
}

let mkActionItemProgressByWatches = @(actionItem, isAvailable, btnSize) @()
  actionItem.get() == null ? { watch = actionItem }
    : {
        watch = [actionItem, isAvailable, isHudPrimaryStyle]
        size = flex()
        children = mkActionItemProgress(actionItem.get(), isAvailable.get(), isHudPrimaryStyle.get(), btnSize)
      }

let mkActionItemCount = @(count, scale = 1) {
  size = flex()
  rendObj = ROBJ_TEXT
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  color = textColor
  text = count < 0 ? "" : count
}.__update(getScaledFont(fontTinyShaded, scale))

let mkActionItemImage = @(getImage, isAvailable, size) @() {
  watch = unitType
  rendObj = ROBJ_IMAGE
  size = [size, size]
  image = svgNullable(getImage(unitType.get()), size)
  keepAspect = KEEP_ASPECT_FIT
  color = !isAvailable ? imageDisabledColor : imageColor
}

let mkActionItemBorder = @(borderW, stateFlags, isDisabled) @() {
  watch = [stateFlags, isDisabled]
  size = flex()
  rendObj = ROBJ_BOX
  borderColor = stateFlags.get() & S_ACTIVE ? borderColorPushed
    : isDisabled.get() ? borderNoAmmoColor
    : borderColor
  borderWidth = borderW
}

let mkActionItemEditView = @(image) {
  size = [touchButtonSize, touchButtonSize + countHeightUnderActionItem]
  flow = FLOW_VERTICAL
  children = [
    {
      size = [touchButtonSize, touchButtonSize]
      rendObj = ROBJ_BOX
      fillColor = hudTransparentColor
      borderColor
      borderWidth
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = {
        rendObj = ROBJ_IMAGE
        size = [touchButtonSize, touchButtonSize]
        image = Picture($"{image}:{touchButtonSize}:{touchButtonSize}:P")
        keepAspect = KEEP_ASPECT_FIT
        color = imageColor
      }
    }
    mkActionItemCount(0)
  ]
}

return {
  countHeightUnderActionItem
  abShortcutImageOvr

  isAvailableActionItem
  mkActionItemProgress
  mkActionItemProgressByWatches
  mkActionItemCount
  mkActionItemImage
  mkActionItemBorder

  mkActionItemEditView
}
