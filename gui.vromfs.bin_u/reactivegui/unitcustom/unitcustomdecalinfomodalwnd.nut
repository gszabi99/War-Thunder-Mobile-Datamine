from "%globalsDarg/darg_library.nut" import *
let { get_local_custom_settings_blk } = require("blkGetters")
let { register_command } = require("console")
let { eventbus_send } = require("eventbus")
let { openMsgBox } = require("%rGui/components/msgBox.nut")

let isOriginalDecals = "USEROPT_IS_ORIGINAL_DECALS"

function showDecalInfoWnd() {
  let sBlk = get_local_custom_settings_blk()
  let isWndShown = sBlk?[isOriginalDecals] ?? false
  if (isWndShown)
    return

  sBlk[isOriginalDecals] <- true
  eventbus_send("saveProfile", {})

  openMsgBox({
    text = loc("options/desc/hud_show_original_decals", {
      optionName = colorize("@mark", loc("options/hud_show_original_decals"))
      optionValue = colorize("@mark", loc("options/enable"))
    })
    title = loc("unit/customization/modalTitle")
  })

}

register_command(function() {
    get_local_custom_settings_blk()[isOriginalDecals] <- null
    eventbus_send("saveProfile", {})
  }, "debug.reset_show_other_decals")

return {
  showDecalInfoWnd
}
