from "%globalsDarg/darg_library.nut" import *
let { playSound } = require("sound_wt")
let { playHapticPattern } = require("hapticVibration")
let { TouchScreenButton } = require("wt.behaviors")
let { activateActionBarAction } = require("hudActionBar")
let { repairAssistAllow } = require("%rGui/hudState.nut")
let { round } = require("math")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { isAvailableActionItem, mkActionItemProgressByWatches, mkActionItemCount,
  countHeightUnderActionItem, mkActionItemBorder, abShortcutImageOvr
} = require("%rGui/hud/buttons/actionButtonComps.nut")
let { touchButtonSize, borderWidth, imageColor, imageDisabledColor
} = require("%rGui/hud/hudTouchButtonStyle.nut")
let { mkActionGlare, mkConsumableSpend } = require("%rGui/hud/weaponsButtonsAnimations.nut")
let { mkGamepadHotkey, mkGamepadShortcutImage } = require("%rGui/controls/shortcutSimpleComps.nut")
let { mkIsControlDisabled } = require("%rGui/controls/disabledControls.nut")
let { HAPT_REPAIR } = require("%rGui/hud/hudHaptic.nut")
let { updateActionBarDelayed, actionBarItems, emptyActionItem, actionItemsInCd
} = require("%rGui/hud/actionBar/actionBarState.nut")
let { AB_TOOLKIT_WITH_MEDICAL, AB_TOOLKIT, AB_MEDICALKIT } = require("%rGui/hud/actionBar/actionType.nut")
let { addCommonHint } = require("%rGui/hudHints/commonHintLogState.nut")


let SPLIT_HOLD_TIME = 0.3
let touchMargin = sh(2.5).tointeger()

let iconByAType = {
  AB_TOOLKIT = "hud_consumable_toolkit.svg"
  AB_MEDICALKIT = "hud_consumable_medicalkit.svg"
}

function calcSizes(scale) {
  let borderW = round(borderWidth * scale)
  let btnSize = scaleEven(touchButtonSize, scale)
  let smallBtnSize = scaleEven(touchButtonSize, scale * 0.75)
  let smallBtnHitSize = scaleEven(touchButtonSize, scale * 1.5) 
  let btnGap = 2 * borderW
  let mainBox = { l = 0, t = 0, r = btnSize, b = btnSize }

  let blX = btnSize / 2 - btnGap / 2 - smallBtnSize
  let blY = -smallBtnSize -btnGap
  let smallBoxL = { l = blX, t = blY, r = blX + smallBtnSize, b = blY + smallBtnSize }
  let brX = blX + smallBtnSize + btnGap
  let smallBoxR = { l = brX , t = blY, r = brX + smallBtnSize, b = blY + smallBtnSize }

  let hlX = btnSize / 2 - btnGap / 2 - smallBtnHitSize
  let hlY = -smallBtnHitSize -btnGap
  let smallHitBoxL = { l = hlX, t = hlY, r = hlX + smallBtnHitSize, b = hlY + smallBtnHitSize }
  let hrX = hlX + smallBtnHitSize + btnGap
  let smallHitBoxR = { l = hrX , t = hlY, r = hrX + smallBtnHitSize, b = hlY + smallBtnHitSize }

  return {
    btnSize
    borderW
    footerHeight = round(countHeightUnderActionItem * scale).tointeger()

    mainBox
    smallBoxL
    smallBoxR
    smallHitBoxL
    smallHitBoxR
  }
}

function getTankActionBarShortcut(actionItem) {
  let shortcutIdx = actionItem?.shortcutIdx ?? -1
  return shortcutIdx < 0 ? "" : $"ID_ACTION_BAR_ITEM_{shortcutIdx + 1}"
}

let getDistance = @(p2, box) max(box.l - p2.x, p2.x - box.r, box.t - p2.y, p2.y - box.b)

let mkBlackBg = @(box, borderW) {
  size = [box.r - box.l + 4 * borderW, box.b - box.t + 4 * borderW]
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  rendObj = ROBJ_SOLID
  color = 0xFF000000
}

function getRepairIcon(assistState, aType) {
  if (aType == AB_TOOLKIT)
    if (assistState == 1)
      return "hud_repair_assist.svg"
    else if (assistState > 1)
      return "hud_cancel_repair_assist.svg"
  return iconByAType?[aType] ?? "hud_consumable_repair.svg"
}

function mkSlaveButton(aType, box, hoverAType, stateFlagsBase, borderW) {
  let stateFlags = Computed(@() hoverAType.get() == aType ? stateFlagsBase.get() : 0)
  let actionItem = Computed(@() actionBarItems.get()?[aType])
  let isAvailable = Computed(@() actionItem.get() != null && isAvailableActionItem(actionItem.get()))
  let isVisible = Computed(@() actionItem.get() != null)
  let size = [box.r - box.l, box.b - box.t]
  let bg = mkBlackBg(box, borderW)
  return @() !isVisible.get() ? { watch = isVisible }
    : {
        watch = [isVisible, repairAssistAllow]
        size
        pos = [box.l, box.t]
        children = [
          bg
          mkActionItemProgressByWatches(actionItem, isAvailable)
          mkActionItemBorder(borderW, stateFlags, Computed(@() !isAvailable.get()))
          @() {
            watch = isAvailable
            rendObj = ROBJ_IMAGE
            size
            image = Picture($"ui/gameuiskin#{getRepairIcon(repairAssistAllow.get(), aType)}:{size[0]}:{size[1]}:P")
            keepAspect = true
            color = !isAvailable.get() ? imageDisabledColor : imageColor
          }
        ]
      }
}

function tankRrepairButtonCtor(scale) {
  let stateFlags = Watched(0)
  let { btnSize, borderW, footerHeight, mainBox, smallBoxL, smallBoxR, smallHitBoxL, smallHitBoxR
  } = calcSizes(scale)
  let actionItem = Computed(@() actionBarItems.get()?[AB_TOOLKIT_WITH_MEDICAL] ?? emptyActionItem)
  let shortcutId = Computed(@() getTankActionBarShortcut(actionItem.get()))
  let isDisabled = mkIsControlDisabled(shortcutId)
  let isAvailable = Computed(@() actionItem.get() != null && !isDisabled.get() && isAvailableActionItem(actionItem.get()))
  let point = Watched(null)
  let isHold = Watched(false)
  let hasMedical = Computed(@() (actionBarItems.get()?[AB_MEDICALKIT].count ?? 0) > 0)
  let hasToolkit = Computed(@() (actionBarItems.get()?[AB_TOOLKIT].count ?? 0) > 0)
  let hasSmallButtons = Computed(@() isHold.get() && hasMedical.get() && hasToolkit.get())
  let btnImage = Computed(@() hasMedical.get() && !hasToolkit.get() ? iconByAType[AB_MEDICALKIT]
    : !hasMedical.get() && hasToolkit.get() ? iconByAType[AB_TOOLKIT]
    : "hud_consumable_repair.svg")
  let blackBg = mkBlackBg(mainBox, borderW)

  let smallButtons = [
    { aType = AB_TOOLKIT, box = smallBoxL, hit = smallHitBoxL }
    { aType = AB_MEDICALKIT, box = smallBoxR, hit = smallHitBoxR }
  ]
  let hoverAType = Computed(function() {
    let p = point.get()
    if (p == null)
      return null
    local bestDistance = getDistance(p, mainBox)
    local res = AB_TOOLKIT_WITH_MEDICAL
    if (hasSmallButtons.get() && bestDistance > 0)
      foreach(cfg in smallButtons) {
        let d = getDistance(p, cfg.hit)
        if (d <= 0)
          return cfg.aType
        if (d < bestDistance) {
          bestDistance = d
          res = cfg.aType
        }
      }
    return bestDistance <= touchMargin ? res : null
  })
  let stateFlagsMain = Computed(@() hoverAType.get() == AB_TOOLKIT_WITH_MEDICAL ? stateFlags.get() : 0)
  let markHold = @() isHold.set(true)
  let function onActionClick(actionType) {
    let action = actionBarItems.get()?[actionType]
    if (action == null)
      return
    if (action.count == 0) {
      addCommonHint(loc("hint/noItemsForRepair"))
      return
    }
    if ((actionItemsInCd.get()?[actionType] ?? false) || !isAvailable.get() || !isAvailableActionItem(action))
      return
    playSound("repair")
    activateActionBarAction(action.shortcutIdx)
    updateActionBarDelayed()
    playHapticPattern(HAPT_REPAIR)
  }

  return @() {
        watch = [actionItem, shortcutId, isAvailable]
        key = "btn_repair_with_medical"
        size = [btnSize, btnSize + footerHeight]
        halign = ALIGN_CENTER
        behavior = TouchScreenButton
        onElemState = @(v) stateFlags.set(v)
        hotkeys = mkGamepadHotkey(shortcutId.get(), @() onActionClick(AB_TOOLKIT_WITH_MEDICAL))
        onTouchBegin = @() resetTimeout(SPLIT_HOLD_TIME, markHold)
        function onTouchEnd() {
          clearTimer(markHold)
          onActionClick(hoverAType.get())
          isHold.set(false)
        }
        onChange = @(p) point.set(p)
        flow = FLOW_VERTICAL
        children = [
          {
            size = [btnSize, btnSize]
            children = [
              @() !hasSmallButtons.get() ? { watch = hasSmallButtons }
                : {
                    watch = hasSmallButtons
                    size = [btnSize, btnSize]
                    children = [ blackBg ]
                      .extend(smallButtons.map(@(c) mkSlaveButton(c.aType, c.box, hoverAType, stateFlags, borderW)))
                  }
              mkActionItemProgressByWatches(actionItem, isAvailable)
              mkActionItemBorder(borderW, stateFlagsMain, Computed(@() !isAvailable.get()))
              @() {
                watch = [isAvailable, btnImage, repairAssistAllow]
                rendObj = ROBJ_IMAGE
                size = [btnSize, btnSize]
                image = Picture($"ui/gameuiskin#{repairAssistAllow.get() == 1
                    ? "hud_repair_assist.svg"
                  : repairAssistAllow.get() > 1
                    ? "hud_cancel_repair_assist.svg"
                  : btnImage.get()}:{btnSize}:{btnSize}:P")
                keepAspect = true
                color = !isAvailable.get() ? imageDisabledColor : imageColor
              }
              mkActionGlare(actionItem.get())
              isDisabled.value ? null : mkGamepadShortcutImage(shortcutId.get(), abShortcutImageOvr, scale)
              mkConsumableSpend("tank_tool_kit_expendable")
              mkConsumableSpend("tank_medical_kit")
            ]
          }
          mkActionItemCount(actionItem.get()?.count ?? 0, scale)
        ]
      }
}

return {
  tankRrepairButtonCtor
}
