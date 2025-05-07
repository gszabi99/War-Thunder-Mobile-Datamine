let { Watched, Computed } = require("frp")
let { resetTimeout } = require("dagor.workcycle")
let { serverConfigs } = require("servConfigs.nut")
let { serverTime, isServerTimeValid } = require("%appGlobals/userstats/serverTime.nut")

let seasonsCfg = Computed(@() serverConfigs.get()?.seasons ?? {})
let curSeasons = Watched({})
let nextUpdateTime = Watched({ value = 0 })

let mkSeason = @(idx, isActive, start, end) { idx, isActive, start, end }

function updateSeasons() {
  let seasons = seasonsCfg.get()
  if (seasons.len() == 0)
    return
  if (!isServerTimeValid.get()) {
    curSeasons.set({})
    return
  }

  let cur = {}
  local nextTime = 0
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
          last.end)
        continue
      }
      let loops = (time - last.end) / s.repeat + 1
      let start = last.start + s.repeat * loops
      cur[id] <- mkSeason(s.rangeList.len() - 1 + loops + s.idxOffset,
        start <= time,
        start,
        last.end + s.repeat * loops)
      continue
    }

    for(local i = s.rangeList.len() - 1; i >= 0; i--) {
      let range = s.rangeList[i]
      if (time > range.end) {
        let nextRange = s.rangeList[i + 1]
        cur[id] <- mkSeason(i + 1 + s.idxOffset,
          false,
          nextRange.start,
          nextRange.end)
        break
      }
      if (time >= range.start || i == 0) {
        cur[id] <- mkSeason(i + s.idxOffset,
          time >= range.start,
          range.start,
          range.end)
        break
      }
    }
  }
  curSeasons.set(cur)
  nextUpdateTime.set({ value = nextTime })
}
updateSeasons()
seasonsCfg.subscribe(@(_) updateSeasons())
isServerTimeValid.subscribe(@(_) updateSeasons())

let startTimer = @(time) time <= serverTime.get() ? null
  : resetTimeout(time - serverTime.get(), updateSeasons)
startTimer(nextUpdateTime.get().value)
nextUpdateTime.subscribe(@(v) startTimer(v.value))

return {
  curSeasons
}