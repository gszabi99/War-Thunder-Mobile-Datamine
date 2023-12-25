from "%globalsDarg/darg_library.nut" import *
let { AB_FIREWORK } = require("%rGui/hud/actionBar/actionType.nut")
let { actionBarItems } = require("%rGui/hud/actionBar/actionBarState.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")

return {
  fwVisibleInEditor = Computed(@() isInBattle.value
                        ? (actionBarItems.value?[AB_FIREWORK].count ?? 0) > 0
                        : (servProfile.value?.items["firework_kit"].count ?? 0) > 0)
  fwVisibleInBattle = Computed(@() (actionBarItems.value?[AB_FIREWORK].count ?? 0) > 0)
}