from "%sqstd/globalState.nut" import hardPersistWatched


let serverConfigs = hardPersistWatched("pserver.config", {}, true)

function updateAllConfigs(newValue) {
  let configs = newValue?.configs
  if (configs != null)
    serverConfigs.set(freeze(configs))
}
serverConfigs.whiteListMutatorClosure(updateAllConfigs)

return {
  serverConfigs
  updateAllConfigs
}
