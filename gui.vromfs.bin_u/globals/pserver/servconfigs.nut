let { hardPersistWatched } = require("%sqstd/globalState.nut")

let serverConfigs = hardPersistWatched("pserver.config", {})

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
