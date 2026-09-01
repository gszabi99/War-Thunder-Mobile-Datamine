from "%globalsDarg/darg_library.nut" import *
from "dagor.random" import rnd
from "eventbus" import eventbus_subscribe, eventbus_send, send
from "%appGlobals/pServer/campaign.nut" import curCampaign, campaignsList, setCampaign
from "%appGlobals/pServer/pServerApi.nut" import set_unit_to_slot
from "%appGlobals/pServer/profile.nut" import campMyUnits
from "%appGlobals/pServer/slots.nut" import curCampaignSlots
from "%appGlobals/queueState.nut" import isInQueue
from "%appGlobals/timeoutExt.nut" import resetExtTimeout
from "%rGui/gameModes/gameModeState.nut" import debugModes
from "%rGui/options/options/graphicOptions.nut" import graphicOptions
from "%rGui/unit/hangarUnit.nut" import setHangarUnit


function getIndexOrRandom(msg, size) {
  return (msg?.index ?? rnd()) % size
}



function leaveQueueOnTimeout() {
  if (isInQueue.get()) {
    log("autotests: queue timeout reached, leaving queue")
    eventbus_send("leaveQueue", {})
  }
}

function queueToRandomDebugGameMode(msg) {
  let modes = debugModes.get().values().filter(@(m) m?.campaign == curCampaign.get())
  if (modes.len() == 0) {
    log("autotests: queueToRandomDebugGameMode: no modes found")
    return;
  }
  let index = getIndexOrRandom(msg, modes.len())
  let mode = modes[index]
  log($"autotests: queueToRandomDebugGameMode: {mode?.name ?? mode?.gameModeId ?? "<unknown>"}")
  eventbus_send("queueToGameMode", { modeId = mode?.gameModeId })
  resetExtTimeout(30, leaveQueueOnTimeout)
}
eventbus_subscribe("queueToRandomDebugGameMode", queueToRandomDebugGameMode)

function autotestsQuitBattle() {
  log("autotests: autotestsQuitBattle")
  send("quitMission", {})
}
eventbus_subscribe("autotestsQuitBattle", @(_) autotestsQuitBattle())

function selectRandomCampaignHangar(msg) {
  let campaigns = campaignsList.get()
  let index = getIndexOrRandom(msg, campaigns.len())
  let campaign = campaigns[index];
  log($"autotests: selectRandomCampaignHangar: {campaign}")
  setCampaign(campaign)
}

function selectRandomUnitHangar(msg) {
  let units = campMyUnits.get()
  if (units.len() <= 0)
    return;
  let index = getIndexOrRandom(msg, units.len())
  let unit = units.keys()[index]
  log($"autotests: selectRandomUnitHangar: {unit}")
  if (curCampaignSlots.get() != null)
    set_unit_to_slot(unit, 0)
  else
    setHangarUnit(unit)
}

function changeRandomGraphicsOption(msg) {
  let options = graphicOptions.filter(@(opt) opt?.list != null)
  if (options.len() == 0) {
    log("autotests: changeRandomGraphicsOption: no suitable options available")
    return;
  }
  let option = options[msg.index % options.len()]
  let optionList = (option.list instanceof Watched) ? option.list.get() : option.list
  if (optionList.len() > 0) {
    let optionValue = optionList[msg.secondaryIndex % optionList.len()]
    let optionSetter = option?.setValue ?? @(v) option.value.set(v)
    log($"autotests: changeRandomGraphicsOption: {option?.locId} -> {optionValue}")
    optionSetter(optionValue)
  }
}

function randomChangeAction(msg) {
  let actions = msg.isInHangar
  ? [
      selectRandomCampaignHangar
      selectRandomUnitHangar
      changeRandomGraphicsOption
    ]
  : [
      changeRandomGraphicsOption
    ]
  let action = actions[msg.actionType % actions.len()]
  action(msg)
}
eventbus_subscribe("randomChangeAction", randomChangeAction)