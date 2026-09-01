from "%globalsDarg/darg_library.nut" import *
from "console" import command
from "dagor.clipboard" import set_clipboard_text
from "dagor.debug" import screenlog
from "dagor.workcycle" import defer
from "json" import object_to_json_string
from "%sqstd/underscore.nut" import arrayByRows
from "%appGlobals/clientState/clientState.nut" import canBattleWithoutAddons
from "%appGlobals/currenciesState.nut" import currencyOrder, getDbgCurrencyCount, balance
from "%appGlobals/customSettings.nut" import resetCustomSettings
from "%appGlobals/gameModes/newbieGameModesConfig.nut" import newbieGameModesConfig
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/pServerApi.nut" import reset_profile, reset_profile_with_stats, unlock_all_units,
  add_currency_no_popup, add_premium, reset_scheduled_reward_timers, upgrade_unit, downgrade_unit, registerHandler,
  royal_beta_units_unlock, add_all_skins_for_unit, shift_all_personal_goods_time, check_purchases_debug,
  add_subscription_time, unlock_all_unreleased_units, debug_skip_event_delay
from "%rGui/components/buttonStyles.nut" import defButtonHeight
from "%rGui/components/debugWnd.nut" import closeButton
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/msgBox.nut" import openMsgBox, msgBoxText
from "%rGui/components/scrollbar.nut" import makeVertScroll, makeSideScroll
from "%rGui/components/textButton.nut" import textButtonCommon
from "%rGui/components/textInput.nut" import textInput
from "%rGui/controlsMenu/gpActBtn.nut" import btnBEscUp
from "%rGui/debriefing/debriefingState.nut" import debriefingData
import "%rGui/debugTools/debugGameModesWnd.nut" as debugGameModesWnd
import "%rGui/debugTools/debugOffersWnd.nut" as debugOffersWnd
import "%rGui/debugTools/debugPermissionsWnd.nut" as debugPermissionsWnd
import "%rGui/debugTools/debugUnlocks.nut" as debugUnlocks
from "%rGui/gameModes/gameModeState.nut" import randomBattleMode, forceNewbieModeIdx
from "%rGui/gameModes/newbieOfflineMissions.nut" import startDebugNewbieMission, startLocalMultiplayerMission
import "%rGui/squad/notAvailableForSquadMsg.nut" as notAvailableForSquadMsg
from "%rGui/tutorial/tutorialMissions.nut" import isTutorialMissionsDebug
from "%rGui/unit/hangarUnit.nut" import mainHangarUnitName
from "%rGui/unlocks/unlocks.nut" import resetUserstatAppData, allowOpenUnlock
from "%rGui/updater/updaterState.nut" import removeAddonsForCampaign


const wndWidth = hdpx(1500)
const gap = hdpx(10)

const wndUid = "debugCommandsWnd"
let close = @() removeModalWindow(wndUid)

registerHandler("sceenlogResult", @(res) screenlog(res?.error == null ? "SUCCESS!" : "ERROR"))
let mkBtn = @(label, func) textButtonCommon(label, func, { ovr = { size = const [FLEX, hdpx(100)] }, useFlexText = true })
let withClose = @(action) function() {
  close()
  action()
}

function resetProfileWithStats() {
  reset_profile_with_stats()
  resetUserstatAppData(true)
}

let infoTextOvr = {
  size = FLEX_H
  halign = ALIGN_LEFT,
  preformatted = FMT_KEEP_SPACES | FMT_NO_WRAP
}.__update(fontTiny)

function showSortedTable(tbl) {
  let text = "\n".join(
    tbl.map(@(v, k) { v, k })
      .values()
      .sort(@(a, b) a.k <=> b.k)
      .map(@(v) $"{v.k} = {v.v}"))
  return openMsgBox({
    uid = "debug_show_table"
    text = makeSideScroll(msgBoxText(text, infoTextOvr))
    wndOvr = { size = const [hdpx(1100), hdpx(1000)] }
    buttons = [
      { text = "COPY", cb = @() set_clipboard_text(text) }   
      { id = "ok", styleId = "PRIMARY", isDefault = true }   
    ]
  })
}

let commandsList = [].extend(
  currencyOrder.map(function(c) {
    let amount = getDbgCurrencyCount(c)
    return { label = $"meta.add_{c} {amount}", func = @() add_currency_no_popup(c, amount, "sceenlogResult") }
  }),
  [
    { label = "meta.add_subscription_time vip 3600 sec", func = @() add_subscription_time("vip", 3600, "sceenlogResult") }
    { label = "meta.add_subscription_time premium 3600 sec", func = @() add_subscription_time("premium", 3600, "sceenlogResult") }
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
    { label = "meta.unlock_all_unreleased_units", func = withClose(unlock_all_unreleased_units) }
    { label = "meta.royal_beta_units_unlock", func = withClose(royal_beta_units_unlock) }
    { label = "upgrade_cur_unit", func = withClose(@() upgrade_unit(mainHangarUnitName.get())) }
    { label = "downgrade_cur_unit", func = withClose(@() downgrade_unit(mainHangarUnitName.get())) }
    { label = "meta.reset_custom_settings", func = withClose(resetCustomSettings) }
    { label = "debug.first_battle_tutorial", func = withClose(@() isTutorialMissionsDebug.set(!isTutorialMissionsDebug.get())) }
    { label = "startFirstBattlesOfflineMission",
      func = withClose(@() notAvailableForSquadMsg(startDebugNewbieMission)) }
    { label = "startLocalMultiplayerMission",
      func = withClose(@() notAvailableForSquadMsg(startLocalMultiplayerMission)) }
    { label = "copy_last_debriefing",
      function func() {
        close()
        if (debriefingData.get() == null)
          return dlog("Debriefing data is empty") 
        set_clipboard_text(object_to_json_string(debriefingData.get(), true))
        return dlog("Debriefing data copied to clipboard") 
      }
    }
    { label = "debug_skip_event_delay",
      func = withClose(@() debug_skip_event_delay(curCampaign.get(), "consolePrintResult")) }
    { label = "debug_game_modes", func = withClose(debugGameModesWnd) }
    { label = "debug_offers", func = withClose(debugOffersWnd) }
    { label = "debug_unlocks", func = withClose(debugUnlocks) }
    {
      function customBtn() {
        let list = newbieGameModesConfig?[curCampaign.get()]
        let curMode = list == null ? "not allowed"
          : forceNewbieModeIdx.get() < 0 ? "cur = default"
          : forceNewbieModeIdx.get() >= list.len() ? "cur = not newbie"
          : $"cur = newbie {forceNewbieModeIdx.get()}"
        return {
          watch = [curCampaign, forceNewbieModeIdx]
          size = FLEX_H
          children = mkBtn($"Toggle newbie mode ({curMode})",
            function() {
              if (list == null) {
                dlog("Newbie modes not allowed for campaign: ", curCampaign.get()) 
                return
              }
              forceNewbieModeIdx.set((forceNewbieModeIdx.get() + 2) % (list.len() + 2) - 1)
              dlog("Mode name by main battle button: ", randomBattleMode.get()?.name) 
            })
        }
      }
    }
    { label = "allow_battle_no_addons",
      func = withClose(function() {
        canBattleWithoutAddons.set(!canBattleWithoutAddons.get())
        dlog(canBattleWithoutAddons.get() ? "Allowed" : "Disable") 
      })
    }
    { label = "permissions", func = withClose(debugPermissionsWnd) }
    { label = "check_purchases_debug", func = withClose(@() check_purchases_debug("onDebugCheckPurchases")) }
    { label = "balance_full", func = @() showSortedTable(balance.get()) }
    { label = "balance_not_empty", func = @() showSortedTable(balance.get().filter(@(v) v != 0)) }
    { label = "updater.removeAddons", func = @() removeAddonsForCampaign(["tanks","air","ships"]) }
    { label = "allowOpenUnlock",
      func = withClose(function() {
        allowOpenUnlock.set(!allowOpenUnlock.get())
        dlog($"allowOpenUnlock: {allowOpenUnlock.get()}") 
      })
    }
  ])

function mkCommandsList() {
  let list = commandsList.map(@(c) c?.customBtn ?? mkBtn(c.label, c.func))
  let rows = arrayByRows(list, 2)
  if (rows.top().len() < 2)
    rows.top().resize(2, { size = FLEX })

  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    padding = gap
    gap
    children = rows.map(@(children) {
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      gap
      children
    })
  }
}

let consoleText = Watched("")
let consoleClear = @() consoleText.set("")
function consoleExecute() {
  let cmd = consoleText.get().strip()
  if (cmd == "")
    return
  consoleClear()
  defer(function() {
    screenlog($"> {cmd}")
    command(cmd)
  })
}

let consoleTextInput = {
  size = FLEX_H
  padding = const [0, gap, hdpx(50), gap]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    textInput(consoleText, {
      placeholder = loc("Enter console commands here")
      onReturn = consoleExecute
    })
    textButtonCommon("Enter", consoleExecute, { ovr = { minWidth = hdpx(170), size = [hdpx(170), defButtonHeight] } })
  ]
}

return @() addModalWindow({
  key = wndUid
  size = FLEX
  stopHotkeys = true
  hotkeys = [[btnBEscUp, { action = close, description = loc("Cancel") }]]
  children = {
    size = const [wndWidth + 2 * gap, sh(90)]
    stopMouse = true
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    rendObj = ROBJ_SOLID
    color = Color(30, 30, 30, 240)
    flow = FLOW_VERTICAL
    onDetach = consoleClear
    children = [
      {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        valign = ALIGN_TOP
        padding = gap
        children = [
          {
            rendObj = ROBJ_TEXT
            text = "Debug commands"
          }.__update(fontSmall)
          { size = FLEX }
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
