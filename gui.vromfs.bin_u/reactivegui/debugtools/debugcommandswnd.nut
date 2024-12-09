from "%globalsDarg/darg_library.nut" import *
let { object_to_json_string } = require("json")
let { command } = require("console")
let { set_clipboard_text } = require("dagor.clipboard")
let { screenlog } = require("dagor.debug")
let { defer } = require("dagor.workcycle")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { reset_profile, reset_profile_with_stats, unlock_all_units, add_currency_no_popup,
  add_premium, reset_scheduled_reward_timers, upgrade_unit, downgrade_unit, registerHandler,
  royal_beta_units_unlock, add_all_skins_for_unit, shift_all_personal_goods_time
} = require("%appGlobals/pServer/pServerApi.nut")
let { resetUserstatAppData } = require("%rGui/unlocks/unlocks.nut")
let { resetCustomSettings } = require("%appGlobals/customSettings.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")
let { closeButton } = require("%rGui/components/debugWnd.nut")
let { textButtonCommon } = require("%rGui/components/textButton.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { textInput } = require("%rGui/components/textInput.nut")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { isTutorialMissionsDebug } = require("%rGui/tutorial/tutorialMissions.nut")
let { debriefingData } = require("%rGui/debriefing/debriefingState.nut")
let debugGameModesWnd = require("debugGameModesWnd.nut")
let { randomBattleMode, forceNewbieModeIdx } = require("%rGui/gameModes/gameModeState.nut")
let { newbieGameModesConfig } = require("%appGlobals/gameModes/newbieGameModesConfig.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let debugOffersWnd = require("debugOffersWnd.nut")
let debugUnlocks = require("debugUnlocks.nut")
let { mainHangarUnitName } = require("%rGui/unit/hangarUnit.nut")
let { startDebugNewbieMission, startLocalMultiplayerMission } = require("%rGui/gameModes/newbieOfflineMissions.nut")
let notAvailableForSquadMsg = require("%rGui/squad/notAvailableForSquadMsg.nut")
let { currencyOrder, getDbgCurrencyCount } = require("%appGlobals/currenciesState.nut")
let { canBattleWithoutAddons } = require("%appGlobals/clientState/clientState.nut")

let wndWidth = sh(130)
let gap = hdpx(10)

let wndUid = "debugCommandsWnd"
let close = @() removeModalWindow(wndUid)

registerHandler("sceenlogResult", @(res) screenlog(res?.error == null ? "SUCCESS!" : "ERROR"))
let mkBtn = @(label, func) textButtonCommon(label, func, { ovr = { size = [flex(), hdpx(100)] } })
let withClose = @(action) function() {
  close()
  action()
}

function resetProfileWithStats() {
  reset_profile_with_stats()
  resetUserstatAppData(true)
}

let commandsList = [].extend(
  currencyOrder.map(function(c) {
    let amount = getDbgCurrencyCount(c)
    return { label = $"meta.add_{c} {amount}", func = @() add_currency_no_popup(c, amount, "sceenlogResult") }
  }),
  [
    { label = "meta.add_premium 3600 sec", func = @() add_premium(3600, "sceenlogResult") }
    { label = "add_all_skins_for_unit", func = withClose(@() add_all_skins_for_unit(mainHangarUnitName.get(),
      mainHangarUnitName.get()?.isUpgraded || mainHangarUnitName.get()?.isPremium
        ? "consolePrintResult"
        : { id = "upgradeUnit", name = mainHangarUnitName.get() })) }
    { label = "meta.reset_profile_with_stats", func = withClose(resetProfileWithStats) }
    { label = "meta.reset_profile_only", func = withClose(reset_profile) }
    { label = "reset_scheduled_reward_timers", func = withClose(reset_scheduled_reward_timers) }
    { label = "shift_personal_goods_1_day", func = withClose(@() shift_all_personal_goods_time(24 * 3600)) }
    { label = "shift_personal_goods_7_days", func = withClose(@() shift_all_personal_goods_time(7 * 24 * 3600)) }
    { label = "meta.unlock_all_units", func = withClose(unlock_all_units) }
    { label = "meta.royal_beta_units_unlock", func = withClose(royal_beta_units_unlock) }
    { label = "upgrade_cur_unit", func = withClose(@() upgrade_unit(mainHangarUnitName.get())) }
    { label = "downgrade_cur_unit", func = withClose(@() downgrade_unit(mainHangarUnitName.get())) }
    { label = "meta.reset_custom_settings", func = withClose(resetCustomSettings) }
    { label = "debug.first_battle_tutorial", func = withClose(@() isTutorialMissionsDebug(!isTutorialMissionsDebug.value)) }
    { label = "startFirstBattlesOfflineMission",
      func = withClose(@() notAvailableForSquadMsg(startDebugNewbieMission)) }
    { label = "startLocalMultiplayerMission",
      func = withClose(@() notAvailableForSquadMsg(startLocalMultiplayerMission)) }
    { label = "copy_last_debriefing",
      function func() {
        close()
        if (debriefingData.value == null)
          return dlog("Debriefing data is empty") //warning disable: -forbidden-function
        set_clipboard_text(object_to_json_string(debriefingData.value, true))
        return dlog("Debriefing data copied to clipboard") //warning disable: -forbidden-function
      }
    }
    { label = "debug_game_modes", func = withClose(debugGameModesWnd) }
    { label = "debug_offers", func = withClose(debugOffersWnd) }
    { label = "debug_unlocks", func = withClose(debugUnlocks) }
    {
      function customBtn() {
        let list = newbieGameModesConfig?[curCampaign.value]
        let curMode = list == null ? "not allowed"
          : forceNewbieModeIdx.value < 0 ? "cur = default"
          : forceNewbieModeIdx.value >= list.len() ? "cur = not newbie"
          : $"cur = newbie {forceNewbieModeIdx.value}"
        return {
          watch = [curCampaign, forceNewbieModeIdx]
          size = [flex(), SIZE_TO_CONTENT]
          children = mkBtn($"Toggle newbie mode ({curMode})",
            function() {
              if (list == null) {
                dlog("Newbie modes not allowed for campaign: ", curCampaign.value) //warning disable: -forbidden-function
                return
              }
              forceNewbieModeIdx((forceNewbieModeIdx.value + 2) % (list.len() + 2) - 1)
              dlog("Mode name by main battle button: ", randomBattleMode.value?.name) //warning disable: -forbidden-function
            })
        }
      }
    }
    { label = "allow_battle_no_addons",
      func = withClose(function() {
        canBattleWithoutAddons.set(!canBattleWithoutAddons.get())
        dlog(canBattleWithoutAddons.get() ? "Allowed" : "Disable") //warning disable: -forbidden-function
      })
    }
  ])

function mkCommandsList() {
  let list = commandsList.map(@(c) c?.customBtn ?? mkBtn(c.label, c.func))
  let rows = arrayByRows(list, 2)
  if (rows.top().len() < 2)
    rows.top().resize(2, { size = flex() })

  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    padding = gap
    gap
    children = rows.map(@(children) {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap
      children
    })
  }
}

let consoleText = Watched("")
let consoleClear = @() consoleText("")
function consoleExecute() {
  let cmd = consoleText.value.strip()
  if (cmd == "")
    return
  consoleClear()
  defer(function() {
    screenlog($"> {cmd}")
    command(cmd)
  })
}

let consoleTextInput = {
  size = [flex(), SIZE_TO_CONTENT]
  padding = [0, gap, hdpx(50), gap]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    textInput(consoleText, {
      placeholder = loc("Enter console commands here")
      onChange = @(value) consoleText(value)
      onReturn = consoleExecute
    })
    textButtonCommon("Enter", consoleExecute,
      { ovr = { minWidth = hdpx(150), size = [hdpx(150), defButtonHeight] } })
  ]
}

return @() addModalWindow({
  key = wndUid
  size = flex()
  stopHotkeys = true
  hotkeys = [[btnBEscUp, { action = close, description = loc("Cancel") }]]
  children = {
    size = [wndWidth + 2 * gap, sh(90)]
    stopMouse = true
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    rendObj = ROBJ_SOLID
    color = Color(30, 30, 30, 240)
    flow = FLOW_VERTICAL
    onDetach = consoleClear
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        valign = ALIGN_TOP
        padding = gap
        children = [
          {
            rendObj = ROBJ_TEXT
            text = "Debug commands"
          }.__update(fontSmall)
          { size = flex() }
          closeButton(close)
        ]
      }
      consoleTextInput
      makeVertScroll(
        mkCommandsList(),
        { rootBase = { behavior = Behaviors.Pannable } })
    ]
  }
})
