from "%globalsDarg/darg_library.nut" import *

let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { doesLocTextExist } = require("dagor.localize")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { can_debug_missions } = require("%appGlobals/permissions.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { textButtonCommon } = require("%rGui/components/textButton.nut")
let optionsScene = require("%rGui/options/optionsScene.nut")
let { replayCamerasButtons } = require("replayMenu.nut")
let { isPlayingReplay } = require("%rGui/hudState.nut")

let isShowDevMenu = mkWatched(persist, "isShowDevMenu", false)

let buttonsList = mkWatched(persist, "buttonsList", [])

let needShowDevMenu = Computed(@() isShowDevMenu.value && can_debug_missions.value)

eventbus_subscribe("FlightMenu_UpdateButtonsList", @(res) buttonsList(res.buttons))

let switchShowDevMenu = @() isShowDevMenu(!isShowDevMenu.value)

let flightMenuButtonsAction = { //for buttons action in darg
  Options = optionsScene
}

let getFlightMenuButtonAction = @(buttonName)
 @() eventbus_send("FlightMenu_doButtonAction", { buttonName })

function getFlightButtonText(buttonName) {
  let locId = $"flightmenu/btn{buttonName}"
  return doesLocTextExist(locId) ? loc(locId) : buttonName
}

let devMenuContent = @() {
  key = buttonsList
  watch = isPlayingReplay
  size = flex()
  flow = FLOW_HORIZONTAL
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  gap = hdpx(30)
  children = [
    @() {
      watch = buttonsList
      size = flex()
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      gap = hdpx(30)
      children = buttonsList.value.map(@(b) textButtonCommon(utf8ToUpper(getFlightButtonText(b)),
        flightMenuButtonsAction?[b] ?? getFlightMenuButtonAction(b)))
    }
    !isPlayingReplay.value ? null
      : {
          size = flex()
          flow = FLOW_VERTICAL
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          gap = hdpx(30)
          children = replayCamerasButtons.map(@(b) textButtonCommon(utf8ToUpper(getFlightButtonText(b.name)), b.action))
        }
  ]
  animations = wndSwitchAnim
}

let openDevMenuButton = @() {
  watch = [can_debug_missions, isShowDevMenu]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  children = can_debug_missions.value
    ? textButtonCommon(isShowDevMenu.value ? "Close Dev Menu" : "Open Dev Menu", switchShowDevMenu,
        { hotkeys = ["^J:RT"] })
    : null
}

return {
  devMenuContent
  openDevMenuButton
  needShowDevMenu
}
