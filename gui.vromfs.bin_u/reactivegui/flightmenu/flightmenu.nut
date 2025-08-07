from "%globalsDarg/darg_library.nut" import *
from "%globalScripts/ecs.nut" import *
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { get_game_mode, GM_TRAINING, get_local_mplayer } = require("mission")
let { is_ready_to_die } = require("guiMission")
let { getSpareSlotsMask } = require("guiRespawn")
let { get_current_mission_info_cached } = require("blkGetters")
let { setInterval, clearTimer } = require("dagor.workcycle")
let { btnBEscUp, EMPTY_ACTION, btnB } = require("%rGui/controlsMenu/gpActBtn.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { battleCampaign } = require("%appGlobals/clientState/missionState.nut")
let { canBailoutFromFlightMenu } = require("%appGlobals/clientState/clientState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { campConfigs, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { textButtonBright, textButtonPrimary, textButtonCommon, textButtonMultiline, buttonsVGap, mergeStyles
} = require("%rGui/components/textButton.nut")
let { backButton, backButtonWidth } = require("%rGui/components/backButton.nut")
let { devMenuContent, openDevMenuButton, needShowDevMenu } = require("%rGui/flightMenu/devFlightMenu.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { mkCustomMsgBoxWnd } = require("%rGui/components/msgBox.nut")
let { modalWndBg, modalWndHeaderBg } = require("%rGui/components/modalWnd.nut")
let optionsScene = require("%rGui/options/optionsScene.nut")
let { isGamepad } = require("%appGlobals/activeControls.nut")
let controlsHelpWnd = require("%rGui/controls/help/controlsHelpWnd.nut")
let { COMMON, PRIMARY, defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { isUnitDelayed, isUnitAlive, unitType } = require("%rGui/hudState.nut")
let { respawnSlots, canUseSpare, isBailoutDeserter } = require("%rGui/respawn/respawnState.nut")
let { resetGravityAxesZero } = require("%rGui/hud/aircraftMovementBlock.nut")
let { isAircraftControlByGyro } = require("%rGui/options/options/airControlsOptions.nut")
let { AIR } = require("%appGlobals/unitConst.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")


let LEAVE_BATTLE_MSG_UID = "leaveBattleMsgUID"

let flightMenuWidth = hdpx(600)
let buttonsPadding = hdpx(40)
let menuBtnWidth = flightMenuWidth - 2 * buttonsPadding
let backButtonSize = [backButtonWidth / 2, backButtonWidth / 2]

let deserterLockStart = Watched(0)
let spawnInfo = Watched(null)
let canDeserter = Computed(function() {
  let { isAlive = false, hasSpawns = false } = spawnInfo.get()
  return isAlive
    || isBailoutDeserter.get()
    || (hasSpawns && (null != respawnSlots.get().findvalue(@(s) s.canSpawn && !s.isSpawnBySpare)))
})
register_es("on_change_lastBailoutTime", {
    [["onInit", "onChange"]] = function(_, comp) {
      if (comp.server_player__userId != myUserId.get())
        return
      deserterLockStart.set(comp.deserterLockStart)
      isBailoutDeserter.set(comp.lastBailoutTime > 0.0)
    }
    function onDestroy() {
      deserterLockStart.set(0)
      isBailoutDeserter.set(false)
    }
  },
  {
    comps_track = [
      ["lastBailoutTime", TYPE_FLOAT],
      ["deserterLockStart", TYPE_INT64]
    ],
    comps_ro = [["server_player__userId", TYPE_UINT64]]
  })
eventbus_subscribe("localPlayerSpawnInfo", @(s) spawnInfo(s))

function battleResume() {
  removeModalWindow(LEAVE_BATTLE_MSG_UID)
  eventbus_send("FlightMenu_doButtonAction", { buttonName = "Resume" })
}
let quitMission = @() eventbus_send("quitMission", {})
let leaveVehicle = @() eventbus_send("FlightMenu_doButtonAction", { buttonName = "LeaveTheTank" })

let backBtn = backButton(battleResume,
  {
    hotkeys = [[$"^J:Start | Esc | {btnB}", loc("btn/continueBattle")]],
    clickableInfo = loc("btn/continueBattle"),
    size = backButtonSize
    image = Picture($"ui/gameuiskin#mark_cross_white.svg:{backButtonSize[0]}:{backButtonSize[1]}")
  })

let menuContent = @(isGivingUp, campaign) mkCustomMsgBoxWnd(loc("msgbox/leaveBattle/title"),
  !isGivingUp ? loc("msgbox/leaveBattle/toPort")
    : (deserterLockStart.get() + (campConfigs.get()?.campaignCfg.deserterPenalty.timeLimit ?? 0)) > serverTime.get()
      ? " ".concat(loc("msgbox/leaveBattle/giveUp"), loc("msgbox/leaveBattle/deserterPenalty"))
    : loc("msgbox/leaveBattle/giveUp"),
  [
    isGivingUp ? textButtonCommon(utf8ToUpper(loc("btn/giveUp")), quitMission, { hotkeys = ["^J:LB"] })
      : textButtonBright(utf8ToUpper(loc(getCampaignPresentation(campaign).returnToHangarShortLocId)), quitMission, { hotkeys = ["^J:LB"] })
    textButtonPrimary(utf8ToUpper(loc("btn/continueBattle")), battleResume,
      { hotkeys = [btnBEscUp] })
  ])

function openLeaveBattleMsg() {
  let missionName = get_current_mission_info_cached()?.name ?? ""
  let isTutorial = get_game_mode() == GM_TRAINING && missionName.startswith("tutorial")
  let campaign = Computed(@() battleCampaign.get() == "" ? curCampaign.get() : battleCampaign.get())
  let allSlotsMask = (1 << respawnSlots.get().len()) - 1
  local spareSlotsMask = allSlotsMask & getSpareSlotsMask()
  let currentUnitName = get_local_mplayer()?.aircraftName
  let currentSlotIdx = respawnSlots.get().findindex(@(v) v.name == currentUnitName)
  let currentSlotMask = currentSlotIdx != null ? 1 << currentSlotIdx : 0
  if ((currentSlotMask & spareSlotsMask) == 0)
    spareSlotsMask = (spareSlotsMask | currentSlotMask)
  let isFreeSlotsAvailable = (allSlotsMask & ~spareSlotsMask) != 0
  removeModalWindow(LEAVE_BATTLE_MSG_UID)
  addModalWindow({
    key = LEAVE_BATTLE_MSG_UID
    children = @() {
      watch = [canDeserter, campaign]
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      children = menuContent(canDeserter.get() && !isTutorial && (!is_ready_to_die() || isFreeSlotsAvailable), campaign.get())
    }
    onClick = EMPTY_ACTION
  })
}

let optionsButton = textButtonMultiline(utf8ToUpper(loc("mainmenu/btnOptions")), optionsScene,
  mergeStyles(PRIMARY, { ovr = { size = [menuBtnWidth, defButtonHeight] } }))
let helpButton = textButtonMultiline(utf8ToUpper(loc("flightmenu/btnControlsHelp")), controlsHelpWnd,
  mergeStyles(PRIMARY, { ovr = { size = [menuBtnWidth, defButtonHeight] } }))
let gyroResetButton = textButtonMultiline(utf8ToUpper(loc("mainmenu/btnGyroReset")), resetGravityAxesZero,
  mergeStyles(PRIMARY, { ovr = { size = [menuBtnWidth, defButtonHeight] } }))
let leaveVehicleButton = textButtonMultiline(utf8ToUpper(loc("flightmenu/btnLeaveTheTank")), leaveVehicle,
  mergeStyles(PRIMARY, { ovr = { size = [menuBtnWidth, defButtonHeight] } }))
let leaveBattleButton = textButtonMultiline(utf8ToUpper(loc("msgbox/leaveBattle/btn")), openLeaveBattleMsg,
  mergeStyles(COMMON, { ovr = { size = [menuBtnWidth, defButtonHeight] } }))

let customButtons = @() {
  watch = isGamepad
  flow = FLOW_VERTICAL
  valign = ALIGN_CENTER
  gap = buttonsVGap
  children = [
    optionsButton
    isGamepad.get() ? helpButton : null
  ]
}

let gyroButtons = @() {
  watch = [unitType, isAircraftControlByGyro]
  valign = ALIGN_CENTER
  children = unitType.get() == AIR && isAircraftControlByGyro.get()
    ? gyroResetButton
    : null
}

let refreshSpawnInfo = @() eventbus_send("getLocalPlayerSpawnInfo", {})

let flightMenu = @() bgShaded.__merge({
  watch = [canDeserter, battleCampaign]
  key = needShowDevMenu
  function onAttach() {
    refreshSpawnInfo()
    setInterval(1.0, refreshSpawnInfo)
  }
  onDetach = @() clearTimer(refreshSpawnInfo)
  size = flex()
  padding = saBordersRv
  children = modalWndBg.__merge({
    size = [flightMenuWidth, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = [
      modalWndHeaderBg.__merge({
        size = FLEX_H
        padding = [hdpx(20), buttonsPadding]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = [
          {
            size = FLEX_H
            hplace = ALIGN_RIGHT
            halign = ALIGN_RIGHT
            children = backBtn
          }
          @() {
            watch = needShowDevMenu
            rendObj = ROBJ_TEXT
            text = needShowDevMenu.get() ? "DEV MENU" : utf8ToUpper(loc("mainmenu/menu"))
          }.__update(fontSmallAccented)
        ]
      })
      @() {
        watch = [isUnitAlive, isUnitDelayed, respawnSlots, canBailoutFromFlightMenu, canUseSpare, needShowDevMenu]
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        hplace = ALIGN_CENTER
        padding = buttonsPadding
        gap = buttonsVGap
        children = needShowDevMenu.get() ? [devMenuContent(menuBtnWidth), openDevMenuButton(menuBtnWidth)]
          : [
              isUnitAlive.get() && !isUnitDelayed.get()
                  && canBailoutFromFlightMenu.get()
                  && (respawnSlots.get().len() > 1 || canUseSpare.get())
                ? leaveVehicleButton
                : null
              customButtons
              gyroButtons
              leaveBattleButton
              openDevMenuButton(menuBtnWidth)
            ]
      }
    ]
  })
  animations = wndSwitchAnim
})

return flightMenu
