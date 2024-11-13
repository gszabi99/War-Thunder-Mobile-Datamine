from "%globalsDarg/darg_library.nut" import *
let { AB_WINCH, AB_WINCH_ATTACH, AB_WINCH_DETACH, getActionType
} = require("%rGui/hud/actionBar/actionType.nut")
let { actionBarItems } = require("%rGui/hud/actionBar/actionBarState.nut")
let { toggleShortcut } = require("%globalScripts/controls/shortcutActions.nut")
let { btnBgColor, touchButtonSize } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { mkGamepadShortcutImage, mkGamepadHotkey } = require("%rGui/controls/shortcutSimpleComps.nut")

let borderWidth = hdpxi(1)
let colorActive = 0xFFDADADA
let colorInactive = 0x806D6D6D

let imgSizeBase = (touchButtonSize * 0.8  + 0.5).tointeger()

let winchImages = {
  [AB_WINCH] = "hud_winch.svg",
  [AB_WINCH_ATTACH] = "hud_winch_attach.svg",
  [AB_WINCH_DETACH] = "hud_winch_detach.svg",
}

let winchAction = Computed(@() actionBarItems.value?[winchImages.findindex(@(_, aType) aType in actionBarItems.value)])

let stateFlags = Watched(0)
function winchButton(scale) {
  let bgSize = scaleEven(touchButtonSize, scale)
  let imgSize = scaleEven(imgSizeBase, scale)
  return function() {
    let res = { watch = [winchAction, stateFlags], key = winchAction }
    if (winchAction.value == null)
      return res

    let { shortcutIdx, selected, active } = winchAction.value
    let color = selected || active ? colorActive : colorInactive
    let image = winchImages[getActionType(winchAction.value)]
    let shortcutId = $"ID_ACTION_BAR_ITEM_{shortcutIdx + 1}"

    return res.__update({
      size = [bgSize, bgSize]
      rendObj = ROBJ_BOX
      borderColor = stateFlags.value & S_ACTIVE ? 0 : color
      fillColor = btnBgColor.empty
      borderWidth
      behavior = Behaviors.Button
      onClick = @() toggleShortcut(shortcutId)
      onElemState = @(v) stateFlags(v)
      hotkeys = mkGamepadHotkey(shortcutId)
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = [
        {
          rendObj = ROBJ_IMAGE
          size = [imgSize, imgSize]
          image = Picture($"ui/gameuiskin#{image}:{imgSize}:{imgSize}")
          keepAspect = KEEP_ASPECT_FIT
          color
        }
        mkGamepadShortcutImage(shortcutId,
          { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = [pw(50), ph(50)] },
          scale)
      ]
    })
  }
}

return winchButton
