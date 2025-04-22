from "%globalsDarg/darg_library.nut" import *
let { campaignsLevelInfo } = require("%appGlobals/pServer/campaign.nut")
let { sendAppsFlyerEvent, sendAppsFlyerSavedEvent } = require("%rGui/notifications/logEvents.nut")


let sendEventsOn = {
  [5] = 1,
  [4] = 1,
  [3] = 2,
  [2] = 2
}

let sendSingleEventsOn = [10, 15, 20]

let levels = keepref(Computed(@() campaignsLevelInfo.get().map(@(v) v?.level ?? 0)))
local lastLevels = clone levels.get()

function checkLevels(allLevels) {
  foreach(campaign, level in allLevels) {
    if (level in sendEventsOn && campaign in lastLevels && lastLevels[campaign] < level) {
      let count = allLevels.reduce(@(res, v) v >= level ? res + 1 : res, 0)
      if (count == sendEventsOn[level])
        sendAppsFlyerEvent($"levelUp_{level}_{count}")
    }
    if (sendSingleEventsOn.contains(level)) {
      sendAppsFlyerSavedEvent($"levelUp{level}_{campaign}", $"levelUp{campaign}{level}")
      sendAppsFlyerSavedEvent($"levelUp{level}_any", $"levelUpAny{campaign}{level}")
    }
  }
  lastLevels = clone allLevels
}

levels.subscribe(@(v) checkLevels(v))