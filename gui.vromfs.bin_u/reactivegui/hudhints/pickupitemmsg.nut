from "%globalsDarg/darg_library.nut" import *
from "%rGui/hud/crewState.nut" import crewState
from "%rGui/hud/hudEventManager.nut" import subscribeHudEvent
from "%rGui/hud/tacticalMap/tacticalMapMarkersLayer.nut" import MARKER_TYPE, addMapMarker
from "%rGui/hudHints/hintCtors.nut" import registerHintCreator, defaultHintCtor
from "%rGui/hudHints/mainHintLogState.nut" import addEvent


const CREW_HINT_TYPE = "battleRoyaleCrew"
const MSG_SHOW_TIME = 5.0

let defaultEvent = {
  id = "pickUpDefault"
  hType = "mission"
  text = loc("hints/battleRoyale/pickup/consumables")
  ttl = MSG_SHOW_TIME
}

let eventByReward = {
  crew_skill_percent = {
    id = CREW_HINT_TYPE
    hType = CREW_HINT_TYPE
    ttl = MSG_SHOW_TIME
  }
  air_speed_boost_percent = {
    key = "raceBoost"
    id = "raceBoost"
    hType = "mission"
    ttl = MSG_SHOW_TIME
    locId = "hints/race/pickup/boost"
  }
  artillery = {
    id = "battleRoyaleArtillery"
    key = "battleRoyaleArtillery"
    hType = "mission"
    ttl = MSG_SHOW_TIME
    locId = "hints/battleRoyale/pickup/artillery"
  }
  add_pickup_ammo = {
    id = "pickupAmmo"
    key = "pickupAmmo"
    hType = "mission"
    ttl = MSG_SHOW_TIME
    locId = "hints/battleRoyale/pickup/ammo"
  }
}

let crewSkillPercent = keepref(Computed(@() crewState.get()?.crewSkillPercent ?? 0))

registerHintCreator(CREW_HINT_TYPE, @(_, __) @() {
  watch = crewSkillPercent
  children = defaultHintCtor({
    key = CREW_HINT_TYPE
    text = loc("hints/battleRoyale/pickup/crew", { percent = crewSkillPercent.get() })
  }, null)
})

subscribeHudEvent("onPickupItem", function(data) {
  let rewardKeys = data.filter(@(_, k) eventByReward?[k] != null)
  if (rewardKeys.len() == 0 && data?.reconRadius == null) {
    addEvent(defaultEvent)
    return
  }
  foreach (rewardKey, _ in rewardKeys)
    addEvent(eventByReward[rewardKey])

  let reconRadius = data?.reconRadius
  let reconDuration = data?.reconDuration
  if (reconRadius != null && reconDuration != null)
    addMapMarker(MARKER_TYPE.RECON_AREA, { radius = reconRadius, showSec = reconDuration })
})

subscribeHudEvent("onRadioDetected", function(_data) {
  addEvent({
    id = "radioDetected"
    hType = "mission"
    text = loc("hints/pickup/radioDetected")
    ttl = MSG_SHOW_TIME
  })
})
