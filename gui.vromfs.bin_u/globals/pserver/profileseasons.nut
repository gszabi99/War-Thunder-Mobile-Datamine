from "%globalScripts/logs.nut" import *
from "math" import min
from "dagor.workcycle" import resetTimeout, clearTimer
let { Watched, Computed } = require("frp")
let { serverConfigs } = require("servConfigs.nut")
let { serverTime, isServerTimeValid } = require("%appGlobals/userstats/serverTime.nut")

let seasonsCfg = Computed(@() serverConfigs.get()?.seasons ?? {})
let curSeasons = Watched({})

let mkSeason = @(idx, isActive, start, end, unlocks) { idx, isActive, start, end, unlocks }

let mkRewardUnlocks = @(rewards) rewards.map(@(v) {
  campaignLevel = v.unlockCampaignLevel
  unitMRank = v.unlockUnitMRank
})

let getNextTime = @(curNextTime, newTime) newTime <= 0 ? curNextTime
  : curNextTime <= 0 ? newTime
  : min(curNextTime, newTime)

function updateSeasons() {
  let seasons = seasonsCfg.get()
  if (seasons.len() == 0 || !isServerTimeValid.get()) {
    curSeasons.set({})
    return
  }

  let cur = {}
  let time = serverTime.get()
  foreach(id, s in seasons) {
    if ((s?.rangeList.len() ?? 0) == 0)
      continue

    let last = s.rangeList.top()
    if (time > last.end) {
      if (s.repeat <= 0) {
        cur[id] <- mkSeason(s.rangeList.len() - 1 + s.idxOffset,
          false,
          last.start,
          last.end,
          mkRewardUnlocks(s.rewards))
        continue
      }
      let loops = (time - last.end) / s.repeat + 1
      let start = last.start + s.repeat * loops
      cur[id] <- mkSeason(s.rangeList.len() - 1 + loops + s.idxOffset,
        start <= time,
        start,
        last.end + s.repeat * loops,
        mkRewardUnlocks(s.rewards))
      continue
    }

    for(local i = s.rangeList.len() - 1; i >= 0; i--) {
      let range = s.rangeList[i]
      if (time > range.end) {
        let nextRange = s.rangeList[i + 1]
        cur[id] <- mkSeason(i + 1 + s.idxOffset,
          false,
          nextRange.start,
          nextRange.end,
          mkRewardUnlocks(s.rewards))
        break
      }
      if (time >= range.start || i == 0) {
        cur[id] <- mkSeason(i + s.idxOffset,
          time >= range.start,
          range.start,
          range.end,
          mkRewardUnlocks(s.rewards))
        break
      }
    }
  }

  curSeasons.set(cur)

  local nextTime = 0
  foreach (s in cur) {
    nextTime = getNextTime(nextTime, s.start - time)
    nextTime = getNextTime(nextTime, s.end - time + 1)
  }

  if (nextTime <= 0)
    clearTimer(updateSeasons)
  else
    resetTimeout(nextTime, updateSeasons)
}
updateSeasons()
seasonsCfg.subscribe(@(_) updateSeasons())
isServerTimeValid.subscribe(@(_) updateSeasons())

return {
  curSeasons
}