from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_subscribe
from "%rGui/hudHints/warningHintLogState.nut" import addEvent
from "%rGui/hud/crewState.nut" import crewState
from "%rGui/hudHints/hintCtors.nut" import registerHintCreator, defaultHintCtor


let CREW_HINT_TYPE = "battleRoyaleCrew"
let DEFAULT_HINT_TYPE = "battleRoyaleDefault"
let MSG_SHOW_TIME = 5.0

let crewSkillPercent = keepref(Computed(@() crewState.get()?.crewSkillPercent ?? 0))

registerHintCreator(CREW_HINT_TYPE, @(_, __) @() {
  watch = crewSkillPercent
  children = defaultHintCtor({
    key = CREW_HINT_TYPE
    text = loc("hints/battleRoyale/pickup/crew", { percent = crewSkillPercent.get() })
  }, null)
})

eventbus_subscribe("onPickupItem", @(data) ((data?.crew_skill_percent ?? 0) > 0)
  ? addEvent({ id = CREW_HINT_TYPE, hType = CREW_HINT_TYPE, ttl = MSG_SHOW_TIME })
  : addEvent({
      id = DEFAULT_HINT_TYPE
      hType = "mission"
      text = loc("hints/battleRoyale/pickup/consumables")
      ttl = MSG_SHOW_TIME
    })
)
