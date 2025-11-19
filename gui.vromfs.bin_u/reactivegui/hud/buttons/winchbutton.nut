from "%globalsDarg/darg_library.nut" import *
let { AB_WINCH, AB_WINCH_ATTACH, AB_WINCH_DETACH, getActionType
} = require("%rGui/hud/actionBar/actionType.nut")
let { actionBarItems } = require("%rGui/hud/actionBar/actionBarState.nut")
let { toggleShortcut } = require("%globalScripts/controls/shortcutActions.nut")
let { touchButtonSize, imageColor } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { mkGamepadShortcutImage, mkGamepadHotkey } = require("%rGui/controls/shortcutSimpleComps.nut")
let { hudPearlGrayColor, hudLightBlackColor } = require("%rGui/style/hudColors.nut")

let borderWidth = hdpxi(1)
let colorActive = imageColor
let colorInactive = hudPearlGrayColor

let imgSizeBase = (touchButtonSize * 0.8  + 0.5).tointeger()

let winchImages = {
  [AB_WINCH] = "hud_winch.svg",
  [AB_WINCH_ATTACH] = "hud_winch_attach.svg",
  [AB_WINCH_DETACH] = "hud_winch_detach.svg",
}

let winchAction = Computed(@() actionBarItems.get()?[winchImages.findindex(@(_, aType) aType in actionBarItems.get())])

let stateFlags = Watched(0)
function winchButton(scale) {
  let bgSize = scaleEven(touchButtonSize, scale)
  let imgSize = scaleEven(imgSizeBase, scale)
  return function() {
    let res = { watch = [winchAction, stateFlags], key = winchAction }
    if (winchAction.get() == null)
      return res

    let { shortcutIdx, selected, active } = winchAction.get()
    let color = selected || active ? colorActive : colorInactive
    let image = winchImages[getActionType(winchAction.get())]
    let shortcutId = $"ID_ACTION_BAR_ITEM_{shortcutIdx + 1}"

    return res.__update({
      size = [bgSize, bgSize]
      rendObj = ROBJ_BOX
      borderColor = stateFlags.get() & S_ACTIVE ? 0 : color
      fillColor = hudLightBlackColor
      borderWidth
      behavior = Behaviors.Button
      cameraControl = true
      onClick = @() toggleShortcut(shortcutId)
      onElemState = @(v) stateFlags.set(v)
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
