from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/loginState.nut" import isAuthorized
from "%appGlobals/pServer/clanServConfigs.nut" import clanServerConfigs, updateClanConfigs
from "%appGlobals/pServer/pServerApi.nut" import get_static_clans_data
from "%appGlobals/permissions.nut" import allow_clans


let needUpdateClanConfigs = keepref(Computed(@() isAuthorized.get() && allow_clans.get()))

function requestClanConfigs() {
  if (needUpdateClanConfigs.get())
    get_static_clans_data()
  else
    updateClanConfigs({})
}

needUpdateClanConfigs.subscribe(@(_) requestClanConfigs())

if (clanServerConfigs.get().len() == 0)
  requestClanConfigs()
