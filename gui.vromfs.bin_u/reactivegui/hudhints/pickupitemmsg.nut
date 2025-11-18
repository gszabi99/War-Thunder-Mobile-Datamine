from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_subscribe
from "%rGui/hudHints/mainHintLogState.nut" import addEvent
from "%rGui/hud/crewState.nut" import crewState
from "%rGui/hudHints/hintCtors.nut" import registerHintCreator, defaultHintCtor


let CREW_HINT_TYPE = "battleRoyaleCrew"
let MSG_SHOW_TIME = 5.0

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
}

let crewSkillPercent = keepref(Computed(@() crewState.get()?.crewSkillPercent ?? 0))

registerHintCreator(CREW_HINT_TYPE, @(_, __) @() {
  watch = crewSkillPercent
  children = defaultHintCtor({
    key = CREW_HINT_TYPE
    text = loc("hints/battleRoyale/pickup/crew", { percent = crewSkillPercent.get() })
  }, null)
})

eventbus_subscribe("onPickupItem", function(data) {
  let rewardKeys = data.filter(@(_, k) eventByReward?[k] != null)
  if (rewardKeys.len() == 0) {
    addEvent(defaultEvent)
    return
  }
  foreach (rewardKey, _ in rewardKeys)
    addEvent(eventByReward[rewardKey])
})
