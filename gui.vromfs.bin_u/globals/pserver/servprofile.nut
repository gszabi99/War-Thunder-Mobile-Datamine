//checked for explicitness
#no-root-fallback
#explicit-this
let { ndbRead, ndbExists  } = require("nestdb")
let { Watched } = require("frp")

 //we only read here, but write only from dagui VM, to avoid write twice
let servProfile = Watched(ndbExists("pserver.profile") ? ndbRead("pserver.profile") : {})

return servProfile
