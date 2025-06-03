from "%globalsDarg/darg_library.nut" import *
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { attrPresets } = require("%rGui/attributes/attrState.nut")

return {
  serverConfigsW = serverConfigs
  servProfileW = servProfile
  attrPresetsW = attrPresets
}
