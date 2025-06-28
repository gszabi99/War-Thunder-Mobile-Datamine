from "%globalsDarg/darg_library.nut" import *
let { get_mission_time } = require("mission")
let { getScaledFont } = require("%globalsDarg/fontScale.nut")
let { touchButtonSize, borderWidth, btnBgColor, imageColor, imageDisabledColor,
  borderColor, borderColorPushed, borderNoAmmoColor, textColor
} = require("%rGui/hud/hudTouchButtonStyle.nut")
let { mkItemWithCooldownText } = require("%rGui/hud/cooldownComps.nut")
let { unitType } = require("%rGui/hudState.nut")


let svgNullable = @(image, size) ((image ?? "") == "") ? null
  : Picture($"{image}:{size}:{size}:P")

let countHeightUnderActionItem = (0.4 * touchButtonSize).tointeger()
let abShortcutImageOvr = { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = [pw(50), ph(-50)] }

let isAvailableActionItem = @(actionItem) (actionItem?.available ?? true)
  && ((actionItem?.count ?? 0) != 0 || actionItem?.control)

function mkActionItemProgress(actionItem, isAvailable) {
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
    size = flex()
    children = {
      size = flex()
      rendObj = ROBJ_PROGRESS_CIRCULAR
      fgColor = !isAvailable ? btnBgColor.noAmmo
        : (actionItem?.broken ?? false) ? btnBgColor.broken
        : btnBgColor.ready
      bgColor = btnBgColor.empty
      fValue = 1.0
      key = $"action_bg_{id}_{endTime}_{time}_{isAvailable}"
      animations = [
        { prop = AnimProp.fValue, from = cooldown, to = 1.0, duration = cooldownDuration, play = true
          onFinish = @() isAvailable ? anim_start(trigger) : null
        }
      ]
    }

    transform = {}
    animations = [{ prop = AnimProp.scale, duration = 0.2,
      from = [1.0, 1.0], to = [1.2, 1.2], easing = CosineFull, trigger }]
  }
  return mkItemWithCooldownText(id, item, flex(), hasCooldown, endTime)
}

let mkActionItemProgressByWatches = @(actionItem, isAvailable) @()
  actionItem.get() == null ? { watch = actionItem }
    : {
        watch = [actionItem, isAvailable]
        size = flex()
        children = mkActionItemProgress(actionItem.get(), isAvailable.get())
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
  image = svgNullable(getImage(unitType.value), size)
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
      fillColor = btnBgColor.empty
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
