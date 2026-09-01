from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "dagor.workcycle" import resetTimeout
from "eventbus" import eventbus_send
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/clientState/clientState.nut" import isOutOfBattleAndResults
from "%appGlobals/commonUrl.nut" import LINK_TO_GAIJIN_ACCOUNT_URL
from "%appGlobals/loginState.nut" import curLoginType, LT_FACEBOOK, authTags
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%rGui/components/msgBox.nut" import openMsgBox, closeMsgBox
from "%rGui/contacts/contactLists.nut" import accountLink
from "%rGui/contacts/contactsState.nut" import isContactsReceived
from "%rGui/tutorial/tutorialWnd/tutorialWndState.nut" import activeTutorialId






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
