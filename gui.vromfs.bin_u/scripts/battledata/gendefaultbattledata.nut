
from "%scripts/dagui_library.nut" import *
let { object_to_json_string } = require("json")
let io = require("io")
let { get_default_battle_data, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { register_command } = require("console")

const WTM_PATH = "../../skyquake/prog/scripts/wtm/"
const DEF_BATTLE_DATA = "globals/data/defaultBattleData"

function saveResult(res, fileName) {
  let fullName = $"{WTM_PATH}{fileName}.nut"
  let file = io.file(fullName, "wt+")
  file.writestring("return ");
  file.writestring(object_to_json_string(res, true))
  file.close()
  console_print($"Saved json to {fullName}")
}

registerHandler("saveDefaultBattleData", function(res) {
  if ("error" in res)
    console_print(res)
  else
    saveResult(res, DEF_BATTLE_DATA)
})

register_command(@() get_default_battle_data("saveDefaultBattleData"), "meta.genDefaultBattleData")
