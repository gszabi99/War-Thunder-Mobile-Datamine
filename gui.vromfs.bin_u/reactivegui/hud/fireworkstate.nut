from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/clientState/clientState.nut" import isInBattle
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%rGui/hud/actionBar/actionBarState.nut" import actionBarItems
from "%rGui/hud/actionBar/actionType.nut" import AB_FIREWORK
from "types" import Bool


let fwVisibleInBattleRaw = Computed(@() (actionBarItems.get()?[AB_FIREWORK].count ?? 0) > 0)
let fwVisibleInBattle = Computed(@(prev) isInBattle.get()
  && (fwVisibleInBattleRaw.get() || (prev instanceof Bool ? prev : false)))

return {
  fwVisibleInEditor = Computed(@() isInBattle.get()
                        ? (actionBarItems.get()?[AB_FIREWORK].count ?? 0) > 0
                        : (servProfile.get()?.items["firework_kit"].count ?? 0) > 0)
  fwVisibleInBattle
}