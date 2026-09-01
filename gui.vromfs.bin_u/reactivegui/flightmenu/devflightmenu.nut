from "%globalsDarg/darg_library.nut" import *
from "dagor.localize" import doesLocTextExist
from "eventbus" import eventbus_subscribe, eventbus_send
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/permissions.nut" import can_debug_missions
from "%rGui/components/buttonStyles.nut" import COMMON, defButtonHeight
from "%rGui/components/textButton.nut" import textButtonMultiline, buttonsVGap, mergeStyles
from "%rGui/flightMenu/replayMenu.nut" import replayCamerasButtons
from "%rGui/hudState.nut" import isPlayingReplay
import "%rGui/options/optionsScene.nut" as optionsScene


let isShowDevMenu = mkWatched(persist, "isShowDevMenu", false)

let buttonsList = mkWatched(persist, "buttonsList", [])

let needShowDevMenu = Computed(@() isShowDevMenu.get() && can_debug_missions.get())

eventbus_subscribe("FlightMenu_UpdateButtonsList", @(res) buttonsList.set(res.buttons))

let switchShowDevMenu = @() isShowDevMenu.set(!isShowDevMenu.get())

let flightMenuButtonsAction = { 
  Options = optionsScene
}

let getFlightMenuButtonAction = @(buttonName)
 @() eventbus_send("FlightMenu_doButtonAction", { buttonName })

function getFlightButtonText(buttonName) {
  let locId = $"flightmenu/btn{buttonName}"
  return doesLocTextExist(locId) ? loc(locId) : buttonName
}

const replayButtonHeigth = hdpxi(79)
let buttonHeight = Computed(@() isPlayingReplay.get() && isShowDevMenu.get() ? replayButtonHeigth : defButtonHeight)

const replayButtonsVGap = hdpx(15)
let buttonGap = Computed(@() isPlayingReplay.get() && isShowDevMenu.get() ? replayButtonsVGap : buttonsVGap)

let devMenuContent = @(menuBtnWidth) @() {
  watch = [isPlayingReplay, buttonHeight, buttonGap]
  flow = FLOW_VERTICAL
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  gap = buttonGap.get()
  children = [
    @() {
      watch = [buttonsList, buttonHeight, buttonGap]
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap = buttonGap.get()
      children = buttonsList.get().map(@(b) textButtonMultiline(utf8ToUpper(getFlightButtonText(b)),
        flightMenuButtonsAction?[b] ?? getFlightMenuButtonAction(b),
        mergeStyles(COMMON, { ovr = { size = [menuBtnWidth, buttonHeight.get()] } })))
    }
    !isPlayingReplay.get() ? null
      : {
          flow = FLOW_VERTICAL
          halign = ALIGN_CENTER
          gap = buttonGap.get()
          children = replayCamerasButtons.map(@(b) textButtonMultiline(utf8ToUpper(getFlightButtonText(b.name)), b.action,
            mergeStyles(COMMON, { ovr = { size = [menuBtnWidth, buttonHeight.get()] } })))
        }
  ]
}

let openDevMenuButton = @(menuBtnWidth) @() {
  watch = [can_debug_missions, isShowDevMenu, buttonHeight]
  hplace = ALIGN_CENTER
  children = can_debug_missions.get()
    ? textButtonMultiline(isShowDevMenu.get() ? "Close Dev Menu" : "Open Dev Menu", switchShowDevMenu,
        mergeStyles(COMMON, { ovr = { size = [menuBtnWidth, buttonHeight.get()] } }))
    : null
}

return {
  devMenuContent
  openDevMenuButton
  needShowDevMenu
}
