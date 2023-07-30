from "%scripts/dagui_library.nut" import *
let { ndbWrite } = require("nestdb")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
require("%appGlobals/pServer/pServerApi.nut") //need to start update profile and configs in this VM even before login

serverConfigs.subscribe(@(c) ndbWrite("pserver.config", c))
servProfile.subscribe(@(p) ndbWrite("pserver.profile", p))
