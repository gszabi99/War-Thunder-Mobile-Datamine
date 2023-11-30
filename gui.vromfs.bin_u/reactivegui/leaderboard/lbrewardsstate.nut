from "%globalsDarg/darg_library.nut" import *
let { userstatRequest, userstatRegisterHandler, userstatDescList
} = require("%rGui/unlocks/userstat.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { curLbCfg } = require("lbState.nut")

let lbRewardsTypes = ["tillPlaces", "tillPercent"]
  .$reduce(@(res, v, idx) res.$rawset(v, idx), {})
let seasonRewards = hardPersistWatched("seasonRewards")

let updateSeasonRewards = @() userstatRequest("GetSeasonRewards")

userstatRegisterHandler("GetSeasonRewards", function(result) {
  if ("error" in result)
    log("GrantRewards result: ", result)
  else {
    log("GrantRewards result success")
    seasonRewards(result?.response)
  }
})

if (userstatDescList.value.len() > 0 && seasonRewards.value == null)
  updateSeasonRewards()
userstatDescList.subscribe(function(v) {
  if (v.len() > 0)
    updateSeasonRewards()
})

let function getSubArray(tbl, id) {
  if (id not in tbl)
    tbl[id] <- []
  return tbl[id]
}

let lbRewards = Computed(function() {
  let res = {}
  let rewardsBase = seasonRewards.value?.current ?? []
  foreach (rewardsBlock in rewardsBase) {
    let { index = 1, modes = [], category = "", rewards = [] } = rewardsBlock
    foreach (modeId in modes) {
      let resModeRewards = getSubArray(res, modeId)
      foreach (rewardCfg in rewards)
        foreach (rType, _ in lbRewardsTypes)
          foreach(place, r in rewardCfg?[rType] ?? {})
            resModeRewards.append({
              season = index
              rType, modeId, category,
              progress = place.tointeger()
              rewards = r?.itemdefids ?? {}
            })
    }
  }
  foreach(modeRewards in res)
    modeRewards.sort(@(a, b) (lbRewardsTypes?[a.rType] ?? 1000) <=> (lbRewardsTypes?[b.rType] ?? 1000)
      || a.progress < 0 <=> b.progress < 0  //progress == -1 is any place
      || a.progress <=> b.progress)
  return res
})

let curLbRewards = Computed(@() lbRewards.value?[curLbCfg.value?.gameMode] ?? [])

let curLbTimeRange = Computed(function() {
  let { gameMode = null } = curLbCfg.value
  if (gameMode == null)
    return null
  foreach(data in seasonRewards.value?.current ?? [])
    if (null != data?.modes.findvalue(@(v) v == gameMode))
      return { start = data?.start, end = data?.end }
  return null
})

return {
  lbRewardsTypes
  lbRewards
  curLbRewards
  hasCurLbRewards = Computed(@() curLbRewards.value.len() > 0)
  curLbTimeRange
}