from "blkGetters" import get_settings_blk
from "nestdb" import ndbRead, ndbWrite, ndbExists
from "%appGlobals/clientState/clientState.nut" import isInBattle
let {
  get_slow_subscriber_threshold_usec = @() 10000,
  set_slow_subscriber_threshold_usec = @(_) null
} = require("frp")

const SAVE_ID = "frp.subscriber_threshold"
let threshold = ndbExists(SAVE_ID) ? ndbRead(SAVE_ID)
  : get_settings_blk()?.debug.frpSlowSubscriberThresholdUsec ?? get_slow_subscriber_threshold_usec()
if (!ndbExists(SAVE_ID))
  ndbWrite(SAVE_ID, threshold)

let updateThreshold = @(isInBattleV)
  set_slow_subscriber_threshold_usec(threshold * (isInBattleV ? 1 : 2))
updateThreshold(isInBattle.get())
isInBattle.subscribe(updateThreshold)
