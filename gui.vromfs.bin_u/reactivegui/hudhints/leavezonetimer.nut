from "%globalsDarg/darg_library.nut" import *
let { inKillZone } = require("%rGui/hudState.nut")
let { registerHintCreator } = require("%rGui/hudHints/hintCtors.nut")
let { addEvent, removeEvent } = require("%rGui/hudHints/warningHintLogState.nut")
let { secondsToTimeAbbrString } = require("%rGui/globals/timeToText.nut")
let eventbus = require("eventbus")

let HINT_TYPE = "returnToMapMessage"
let alert = Color(221, 17, 17)

registerHintCreator(HINT_TYPE, @(hint) {
  vplace = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  color = alert
  behavior = Behaviors.RtPropUpdate
  update = @() {
    text = hint.endTime < ::get_mission_time()
      ? loc("HUD_RETURN")
      : "".concat(inKillZone.value ? loc("TXT_LEAVE_ZONE_TIMER") : loc("HUD_RETURN_TIMER"),
                secondsToTimeAbbrString(hint.endTime - ::get_mission_time()))
  }
}.__update(fontSmallAccented))

eventbus.subscribe("onShowReturnToMapMessage",
  @(data) data.showMessage ? addEvent({ id = HINT_TYPE, hType = HINT_TYPE, endTime = data.endTime })
      : removeEvent({ id = HINT_TYPE }))