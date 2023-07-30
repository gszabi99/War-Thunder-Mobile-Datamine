//checked for explicitness
#no-root-fallback
#explicit-this

from "%scripts/dagui_library.nut" import *
let json = require("json")
let io = require("io")
let { get_default_battle_data } = require("%appGlobals/pServer/pServerApi.nut")
let { register_command } = require("console")

const WTM_PATH = "../../skyquake/prog/scripts/wtm/"
const DEF_BATTLE_DATA = "globals/data/defaultBattleData"

let function saveResult(res, fileName) {
  let fullName = $"{WTM_PATH}{fileName}.nut"
  let file = io.file(fullName, "wt+")
  file.writestring("return ");
  file.writestring(json.to_string(res, true))
  file.close()
  console_print($"Saved json to {fullName}")
}

register_command(@() get_default_battle_data(function(res) {
  if ("error" in res)
    console_print(toString(res))
  else
    saveResult(res, DEF_BATTLE_DATA)
}), "meta.genDefaultBattleData")