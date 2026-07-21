from "%globalsDarg/darg_library.nut" import *
let { abTests } = require("%appGlobals/pServer/campaign.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")


let shouldShowEventMechanics = Computed(function() {
  let minimumPlayedBattles = abTests.get()?.battlesToDisplayEvents.tointeger() ?? 0
  if (minimumPlayedBattles == 0)
    return true

  let playedBattles = (servProfile.get()?.sharedStatsByCampaign ?? {}).reduce(@(res, v) max((v?.battles ?? 0), res), 0)
  return playedBattles >= minimumPlayedBattles
})

return shouldShowEventMechanics