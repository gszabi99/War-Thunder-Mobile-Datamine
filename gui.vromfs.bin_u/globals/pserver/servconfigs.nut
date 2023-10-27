let { ndbRead, ndbExists } = require("nestdb")
let { Watched } = require("frp")

 //we only read here, but write only from dagui VM, to avoid write twice
let serverConfigs = Watched(ndbExists("pserver.config") ? ndbRead("pserver.config") : {})

let function updateAllConfigs(newValue) {
  let configs = newValue?.configs
  if (configs != null)
    serverConfigs(freeze(configs))
}
serverConfigs.whiteListMutatorClosure(updateAllConfigs)

return {
  serverConfigs
  updateAllConfigs
}
