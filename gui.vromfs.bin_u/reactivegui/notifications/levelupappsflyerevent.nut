from "%globalsDarg/darg_library.nut" import *
let { campaignsLevelInfo } = require("%appGlobals/pServer/campaign.nut")
let { sendAppsFlyerEvent } = require("%rGui/notifications/logEvents.nut")

// Server supports only those events: "levelUp_5_1", "levelUp_4_1", "levelUp_3_2".
let sendEventsOn = {
  [5] = 1,
  [4] = 1,
  [3] = 2
}

let levels = keepref(Computed(@() campaignsLevelInfo.get().map(@(v) v?.level ?? 0)))
local lastLevels = clone levels.get()

function checkLevels(allLevels) {
  foreach(campaign, level in allLevels)
    if (level in sendEventsOn && campaign in lastLevels && lastLevels[campaign] < level) {
      let count = allLevels.reduce(@(res, v) v >= level ? res + 1 : res, 0)
      if (count == sendEventsOn[level])
        sendAppsFlyerEvent($"levelUp_{level}_{count}")
    }
  lastLevels = clone allLevels
}

levels.subscribe(@(v) checkLevels(v))