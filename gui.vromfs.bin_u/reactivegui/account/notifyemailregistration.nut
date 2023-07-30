from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { isGuestLogin, openGuestEmailRegistration, needVerifyEmail, openVerifyEmail
} = require("emailRegistrationState.nut")
let { openMsgBox, closeMsgBox } = require("%rGui/components/msgBox.nut")
let { isInMenuNoModals } = require("%rGui/mainMenu/mainMenuState.nut")
let mkHardWatched = require("%globalScripts/mkHardWatched.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")


let GUEST_MSG_UID = "guestEmailRegistration"
let VERIFY_MSG_UID = "verifyEmail"

let isGuestMsgShowed = mkHardWatched("isGuestMsgShowed", false)
let hasBatttles = Computed(@()
  servProfile.value?.sharedStatsByCampaign.findindex(@(s) (s?.battles ?? 0) > 0) != null)
let needShowGuestMsg = keepref(Computed(@() !isGuestMsgShowed.value
  && isInMenuNoModals.value
  && isGuestLogin.value
  && hasBatttles.value))

let isVerifyMsgShowed = mkHardWatched("isVerifyMsgShowed", false)
let needShowVerifyMsg = keepref(Computed(@() !isVerifyMsgShowed.value
  && isInMenuNoModals.value
  && needVerifyEmail.value
  && hasBatttles.value))


let function openGuestMsg() {
  if (!needShowGuestMsg.value)
    return
  openMsgBox({
    uid = GUEST_MSG_UID
    text = loc("msg/needRegistrationForProgress")
    buttons = [
      { id = "later", isCancel = true, cb = @() isGuestMsgShowed(true) }
      { id = "linkEmail", isPrimary = true, isDefault = true,
        function cb() {
          isGuestMsgShowed(true)
          openGuestEmailRegistration()
        }
      }
    ]
  })
}

let openGuestMsgDelayed = @() resetTimeout(0.5, openGuestMsg)
if (needShowGuestMsg.value)
  openGuestMsgDelayed()
needShowGuestMsg.subscribe(@(_) openGuestMsgDelayed())

isGuestLogin.subscribe(@(v) v ? null : closeMsgBox(GUEST_MSG_UID))


let function openVerifyMsg() {
  if (!needShowVerifyMsg.value)
    return
  openMsgBox({
    uid = VERIFY_MSG_UID
    text = loc("mainmenu/email_not_verified")
    buttons = [
      { id = "later", isCancel = true, cb = @() isVerifyMsgShowed(true) }
      { id = "verify", isPrimary = true, isDefault = true,
        function cb() {
          isVerifyMsgShowed(true)
          openVerifyEmail()
        }
      }
    ]
  })
}

let openVerifyMsgDelayed = @() resetTimeout(0.5, openVerifyMsg)
if (needShowVerifyMsg.value)
  openVerifyMsgDelayed()
needShowVerifyMsg.subscribe(@(_) openVerifyMsgDelayed())

needVerifyEmail.subscribe(@(v) v ? null : closeMsgBox(VERIFY_MSG_UID))
