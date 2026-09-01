from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_subscribe
from "mission" import get_mission_time
from "%appGlobals/timeToText.nut" import secondsToTimeAbbrString
from "%rGui/hudHints/hintCtors.nut" import registerHintCreator
from "%rGui/hudHints/warningHintLogState.nut" import addEvent, removeEvent
from "%rGui/hudState.nut" import inKillZone


const HINT_TYPE = "returnToMapMessage"
const alert = Color(221, 17, 17)

registerHintCreator(HINT_TYPE, @(hint, _) {
  rendObj = ROBJ_TEXT
  pos = [0, -(0.25 * saSize[1])]
  minHeight = hdpx(40)
  color = alert
  behavior = Behaviors.RtPropUpdate
  update = @() {
    text = hint.endTime < get_mission_time()
      ? loc("HUD_RETURN")
      : "".concat(inKillZone.get() ? loc("TXT_LEAVE_ZONE_TIMER") : loc("HUD_RETURN_TIMER"),
                secondsToTimeAbbrString(hint.endTime - get_mission_time()))
  }
}.__update(fontMedium))

eventbus_subscribe("onShowReturnToMapMessage",
  @(data) data.showMessage ? addEvent({ id = HINT_TYPE, hType = HINT_TYPE, endTime = data.endTime })
      : removeEvent({ id = HINT_TYPE }))