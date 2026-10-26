from "%sqstd/globalState.nut" import hardPersistWatched


let clanServerConfigs = hardPersistWatched("clan.server.config", {}, true)

function updateClanConfigs(newValue) {
  let configs = newValue?.configs
  if (configs != null)
    clanServerConfigs.set(freeze(configs))
}
clanServerConfigs.whiteListMutatorClosure(updateClanConfigs)

return {
  clanServerConfigs
  updateClanConfigs
}
