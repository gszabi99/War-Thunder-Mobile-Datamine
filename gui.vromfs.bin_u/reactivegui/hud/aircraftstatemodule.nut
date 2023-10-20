from "%globalsDarg/darg_library.nut" import *
let { borderColor } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { setShortcutOn, setShortcutOff } = require("%globalScripts/controls/shortcutActions.nut")
let { mkGamepadHotkey, mkGamepadShortcutImage } = require("%rGui/controls/shortcutSimpleComps.nut")
let { isInZoom, isVisibleDmgIndicator } = require("%rGui/hudState.nut")
let { updateActionBarDelayed } = require("actionBar/actionBarState.nut")
let damagePanelBacklight = require("components/damagePanelBacklight.nut")

let damagePanelSize = shHud(20)

let xrayDoll = @(stateFlags) {
  size = [damagePanelSize, damagePanelSize]
  children = [
    damagePanelBacklight(stateFlags, damagePanelSize)
    {
      rendObj = ROBJ_XRAYDOLL
      size = flex()
      rotateWithCamera = true
      drawOutlines = false
      drawSilhouette = true
      drawTargetingSightLine = true
      modulateSilhouetteColor = true
    }
  ]
}

let function useShortcutOn(shortcutId) {
  setShortcutOn(shortcutId)
  updateActionBarDelayed()
}
let abShortcutImageOvr = { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = [pw(60), ph(-50)] }

let shortcutId = "ID_SHOW_HERO_MODULES"
let stateFlags = Watched(0)
let isActive = @(sf) (sf & S_ACTIVE) != 0
let doll = @() {
  key = "aircraft_state_button"
  behavior = Behaviors.TouchAreaOutButton
  watch = [ isInZoom, isVisibleDmgIndicator ]
  eventPassThrough = true
  function onElemState(sf) {
    let prevSf = stateFlags.value
    stateFlags(sf)
    let active = isActive(sf) && !isInZoom.value

    if (active != isActive(prevSf))
      if (active)
        useShortcutOn(shortcutId)
      else
        setShortcutOff(shortcutId)
  }
  function onDetach() {
    stateFlags(0)
    setShortcutOff(shortcutId)
  }
  hotkeys = mkGamepadHotkey(shortcutId)
  children = [
    isVisibleDmgIndicator.value ? xrayDoll(isInZoom.value ? null : stateFlags) : null
    mkGamepadShortcutImage(shortcutId, abShortcutImageOvr)
  ]
}

let dollEditView = {
  size = [damagePanelSize, damagePanelSize]
  rendObj = ROBJ_BOX
  borderWidth = hdpx(3)
  borderColor
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text = loc("xray/model")
  }.__update(fontSmall)
}


return {
  doll
  dollEditView
}
