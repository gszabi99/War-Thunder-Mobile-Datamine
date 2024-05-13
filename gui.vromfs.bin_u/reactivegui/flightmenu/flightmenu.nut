from "%globalsDarg/darg_library.nut" import *
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { setInterval, clearTimer } = require("dagor.workcycle")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { battleCampaign } = require("%appGlobals/clientState/missionState.nut")
let { canBailoutFromFlightMenu } = require("%appGlobals/clientState/clientState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { textButtonBright, textButtonPrimary, textButtonCommon, textButtonMultiline, buttonsHGap
} = require("%rGui/components/textButton.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { devMenuContent, openDevMenuButton, needShowDevMenu } = require("%rGui/flightMenu/devFlightMenu.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { mkCustomMsgBoxWnd } = require("%rGui/components/msgBox.nut")
let optionsScene = require("%rGui/options/optionsScene.nut")
let { isGamepad } = require("%appGlobals/activeControls.nut")
let controlsHelpWnd = require("%rGui/controls/help/controlsHelpWnd.nut")
let { COMMON } = require("%rGui/components/buttonStyles.nut")
let { isUnitDelayed, unitType, isUnitAlive } = require("%rGui/hudState.nut")
let { respawnSlots } = require("%rGui/respawn/respawnState.nut")


let spawnInfo = Watched(null)
let aliveOrHasSpawn = Computed(@() (spawnInfo.value?.isAlive ?? false) || (spawnInfo.value?.hasSpawns ?? false))
eventbus_subscribe("localPlayerSpawnInfo", @(s) spawnInfo(s))

let battleResume = @() eventbus_send("FlightMenu_doButtonAction", { buttonName = "Resume" })
let quitMission = @() eventbus_send("quitMission", {})
let leaveVehicle = @() eventbus_send("FlightMenu_doButtonAction", { buttonName = "LeaveTheTank" })

let backBtn = backButton(battleResume,
  { hotkeys = [["^J:Start", loc("btn/continueBattle")]], clickableInfo = loc("btn/continueBattle") })

let menuContent = @(isAlive, campaign) mkCustomMsgBoxWnd(loc("msgbox/leaveBattle/title"),
  loc(isAlive ? "msgbox/leaveBattle/giveUp" : "msgbox/leaveBattle/toPort"),
  [
    textButtonBright(
      utf8ToUpper(loc(isAlive ? "btn/giveUp"
        : campaign == "ships" ? "return_to_port/short"
        : "return_to_hangar/short")),
      quitMission)
    textButtonPrimary(utf8ToUpper(loc("btn/continueBattle")), battleResume,
      { hotkeys = [btnBEscUp] })
  ])

let optionsButton = textButtonCommon(utf8ToUpper(loc("mainmenu/btnOptions")), optionsScene,
  { hotkeys = ["^J:Y"] })
let helpButton = textButtonCommon(utf8ToUpper(loc("flightmenu/btnControlsHelp")), controlsHelpWnd,
  { hotkeys = ["^J:X"] })
let leaveVehicleButton = textButtonMultiline(utf8ToUpper(loc("flightmenu/btnLeaveTheTank")), leaveVehicle,
  COMMON.__merge({ hotkeys = ["^J:LT"] }))

let customButtons = @() {
  watch = isGamepad
  vplace = ALIGN_BOTTOM
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = buttonsHGap
  children = [
    optionsButton
    isGamepad.value ? helpButton : null
  ]
}

let refreshSpawnInfo = @() eventbus_send("getLocalPlayerSpawnInfo", {})

let flightMenu = @() bgShaded.__merge({
  watch = [needShowDevMenu, aliveOrHasSpawn, battleCampaign]
  key = needShowDevMenu
  function onAttach() {
    refreshSpawnInfo()
    setInterval(1.0, refreshSpawnInfo)
  }
  onDetach = @() clearTimer(refreshSpawnInfo)

  size = flex()
  padding = saBordersRv
  children = [
    backBtn
    needShowDevMenu.value ? devMenuContent : menuContent(aliveOrHasSpawn.value, battleCampaign.value)
    customButtons
    @() {
      watch = [isUnitAlive, unitType, isUnitDelayed, respawnSlots, canBailoutFromFlightMenu]
      flow = FLOW_HORIZONTAL
      gap = buttonsHGap
      hplace = ALIGN_RIGHT
      vplace = ALIGN_BOTTOM
      children = [
        isUnitAlive.get() && !isUnitDelayed.get()
            && respawnSlots.get().reduce(@(res, s) res + (s?.isLocked ? 0 : 1), 0) > 1
            && canBailoutFromFlightMenu.get()
          ? leaveVehicleButton
          : null
          openDevMenuButton
      ]
    }
  ]
  animations = wndSwitchAnim
})

return flightMenu
