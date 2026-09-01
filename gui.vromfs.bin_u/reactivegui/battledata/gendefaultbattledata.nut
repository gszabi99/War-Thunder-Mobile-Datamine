from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
import "io" as io
from "json" import object_to_json_string
from "%appGlobals/pServer/pServerApi.nut" import get_default_battle_data, registerHandler


const WTM_PATH = "../../skyquake/prog/scripts/wtm/"
const DEF_BATTLE_DATA = "globals/data/defaultBattleData"

function saveResult(res, fileName) {
  let fullName = $"{WTM_PATH}{fileName}.nut"
  let file = io.file(fullName, "wt+")
  file.writestring("return ");
  file.writestring(object_to_json_string(res, true))
  file.close()
  log($"Saved json to {fullName}")
  console_print($"Saved json to {fullName}") 
}

registerHandler("saveDefaultBattleData", function(res) {
  if ("error" in res)
    console_print(res) 
  else
    saveResult(res, DEF_BATTLE_DATA)
})

register_command(@() get_default_battle_data("saveDefaultBattleData"), "meta.genDefaultBattleData")
