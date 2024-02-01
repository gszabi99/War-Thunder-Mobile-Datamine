from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { resetTimeout } = require("dagor.workcycle")
let { get_common_local_settings_blk } = require("blkGetters")
let { register_command } = require("console")
let { isUhqAllowed, needUhqTextures, setNeedUhqTextures } = require("%rGui/options/options/graphicOptions.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { isInMenuNoModals } = require("%rGui/mainMenu/mainMenuState.nut")
let { isRandomBattleNewbie, randomBattleMode } = require("%rGui/gameModes/gameModeState.nut")
let { openMsgBox, wndHeight } = require("%rGui/components/msgBox.nut")
let hasAddons = require("%appGlobals/updater/hasAddons.nut")
let { commonUhqAddons, getAddonsSizeStr } = require("%appGlobals/updater/addons.nut")
let { addonsToDownload } = require("%rGui/updater/updaterState.nut")


let MSG_UID = "suggestUHQ"
let isSuggested = Watched(get_common_local_settings_blk()?.uhqTexturesSuggested ?? false)
let uhqAddons = Computed(function() {
  let addonsToCheck = clone addonsToDownload.value
  foreach(a, v in hasAddons.value)
    if (v)
      addonsToCheck[a] <- true

  let res = {}
  foreach(a in commonUhqAddons)
    if (hasAddons.value?[a] == false)
      res[a] <- true
  foreach(a, _ in addonsToCheck) {
    let uhq = $"{a}_uhq"
    if (hasAddons.value?[uhq] == false)
      res[uhq] <- true
  }
  return res
})
let needSuggest = Computed(@() isUhqAllowed.value
  && !isSuggested.value
  && uhqAddons.value.len() != 0
  && !needUhqTextures.value
  && isLoggedIn.value
  && (!isRandomBattleNewbie.value && randomBattleMode.value != null)
)
let needShow = keepref(Computed(@() needSuggest.value && isInMenuNoModals.value))

function setSuggested(suggested) {
  isSuggested(suggested)
  get_common_local_settings_blk().uhqTexturesSuggested = suggested
  eventbus_send("saveProfile", {})
}

function openMsg() {
  if (!needShow.value)
    return

  openMsgBox({
    uid = MSG_UID
    wndOvr = { size = [hdpx(1300), wndHeight] }
    text = loc("msg/suggestUhqTextures",
      { size = colorize("@mark", getAddonsSizeStr(uhqAddons.value.keys())) })
    buttons = [
      { text = loc("btnHighQuality"), isCancel = true,
        cb = @() setSuggested(true)
      }
      { text = loc("btnUltraHighQuality"), styleId = "PRIMARY", isDefault = true,
        function cb() {
          setSuggested(true)
          setNeedUhqTextures(true)
        }
      }
    ]
  })
}

let openMsgDelayed = @() resetTimeout(0.5, openMsg)
if (needShow.value)
  openMsgDelayed()
needShow.subscribe(@(_) openMsgDelayed())

register_command(@() setSuggested(false), "debug.reset_uhq_msg_showed")
