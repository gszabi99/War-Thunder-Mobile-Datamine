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
let { accountLink } = require("%rGui/contacts/contactLists.nut")
let { isContactsReceived } = require("%rGui/contacts/contactsState.nut")
let { activeTutorialId } = require("%rGui/tutorial/tutorialWnd/tutorialWndState.nut")


const SUGGEST_LINK_ACC = "suggest_link_acc"
let { isTimerPassed, setLastTime } = require("%rGui/globals/mkStoredAlarm.nut")(SUGGEST_LINK_ACC, 604800)

let needLinkToGaijinAccount = Computed(@() isContactsReceived.get()
  && accountLink.get() == null
  && !authTags.get().contains("email_verified")
  && curLoginType.get() == LT_FACEBOOK)
let isSuggested = hardPersistWatched("suggestLinkFacebook.isSuggested", false)
let needShowMessage = keepref(Computed(@() needLinkToGaijinAccount.get()
                                           && !isSuggested.get()
                                           && isOutOfBattleAndResults.get()
                                           && isTimerPassed.get()
                                           && activeTutorialId.get() == null))
function openMsg() {
  if (!needShowMessage.get())
    return
  openMsgBox({
    uid = SUGGEST_LINK_ACC
    text = loc("mainmenu/link_to_gaijin_account")
    buttons = [
      { id = "later", isCancel = true,
        function cb() {
          isSuggested.set(true)
          setLastTime(serverTime.get())
        }
      }
      { id = "linkEmail", styleId = "PRIMARY", isDefault = true,
        function cb() {
          isSuggested.set(true)
          eventbus_send("openUrl", { baseUrl = LINK_TO_GAIJIN_ACCOUNT_URL })
          setLastTime(serverTime.get())
        }
      }
    ]
  })
}

let openMsgDelayed = @() resetTimeout(0.5, openMsg)
if (needShowMessage.get())
  openMsgDelayed()
needShowMessage.subscribe(@(v) v ? openMsgDelayed() : closeMsgBox(SUGGEST_LINK_ACC))

register_command(function() {
  setLastTime(0)
  isSuggested.set(false)
}, "debug.reset_link_email_timer")
