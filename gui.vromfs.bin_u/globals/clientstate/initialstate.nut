let { get_settings_blk } = require("blkGetters")
let { get_arg_value_by_name, dgs_get_settings } = require("dagor.system")
let { platformId } = require("%sqstd/platform.nut")


let defProjectId = "war_thunder_mobile"

let sBlk = dgs_get_settings()
let projectId = sBlk?[$"{platformId}_project_id"] ?? sBlk?.project_id ?? defProjectId

let setBlk = get_settings_blk()
let disableNetwork = setBlk?.debug.disableNetwork ?? get_arg_value_by_name("disableNetwork") ?? false

let shouldDisableMenu = (disableNetwork && (setBlk?.debug.disableMenu ?? false))
  || (setBlk?.benchmarkMode ?? false)
  || (setBlk?.viewReplay ?? false)

return {
  projectId
  disableNetwork
  shouldDisableMenu
  isOfflineMenu = disableNetwork && !shouldDisableMenu
}
