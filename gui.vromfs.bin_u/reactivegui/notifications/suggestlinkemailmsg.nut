from "%globalsDarg/darg_library.nut" import *
let { curLoginType, LT_FACEBOOK, authTags } = require("%appGlobals/loginState.nut")
let { openMsgBox, closeMsgBox } = require("%rGui/components/msgBox.nut")
let { resetTimeout } = require("dagor.workcycle")
let { register_command } = require("console")
let { isOutOfBattleAndResults } = require("%appGlobals/clientState/clientState.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { eventbus_send } = require("eventbus")
let { LINK_TO_GAIJIN_ACCOUNT_URL } = require("%appGlobals/commonUrl.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")

const SUGGEST_LINK_ACC = "suggest_link_acc"
let { isTimerPassed, setLastTime } = require("%rGui/globals/mkStoredAlarm.nut")(SUGGEST_LINK_ACC, 604800/*s in one week*/)


let needLinkToGaijinAccount = Computed(@() !authTags.value.contains("email_verified") && curLoginType.value == LT_FACEBOOK )
let isSuggested = hardPersistWatched("suggestLinkFacebook.isSuggested", false)
let needShowMessage = keepref(Computed(@() needLinkToGaijinAccount.value
                                           && !isSuggested.value
                                           && isOutOfBattleAndResults.value
                                           && isTimerPassed.value))
function openMsg() {
  if (!needShowMessage.value)
    return
  openMsgBox({
    uid = SUGGEST_LINK_ACC
    text = loc("mainmenu/facebook_link_email")
    buttons = [
      { id = "later", isCancel = true,
        function cb() {
          isSuggested(true)
          setLastTime(serverTime.value)
        }
      }
      { id = "linkEmail", styleId = "PRIMARY", isDefault = true,
        function cb() {
          isSuggested(true)
          eventbus_send("openUrl", { baseUrl = LINK_TO_GAIJIN_ACCOUNT_URL })
          setLastTime(serverTime.value)
        }
      }
    ]
  })
}

let openMsgDelayed = @() resetTimeout(0.5, openMsg)
if (needShowMessage.value)
  openMsgDelayed()
needShowMessage.subscribe(@(v) v ? openMsgDelayed() : closeMsgBox(SUGGEST_LINK_ACC))

register_command(function() {
  setLastTime(0)
  isSuggested(false)
}, "debug.reset_link_email_timer")
