from "%globalsDarg/darg_library.nut" import *
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { isInMpSession } = require("%appGlobals/clientState/clientState.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")


let onlineBattlesCountForSession = hardPersistWatched("onlineBattleCountState.onlineBattlesCountForSession", {})

isInMpSession.subscribe(@(v) !v ? null
  : onlineBattlesCountForSession.set(onlineBattlesCountForSession.get().__merge({
      [curCampaign.get()] = (onlineBattlesCountForSession.get()?[curCampaign.get()] ?? 0) + 1
    })))

isLoggedIn.subscribe(@(v) v ? onlineBattlesCountForSession.set({}) : null)

return {
  onlineBattlesCountForSession
}