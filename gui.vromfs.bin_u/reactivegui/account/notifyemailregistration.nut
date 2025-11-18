from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { resetTimeout } = require("dagor.workcycle")
let { get_local_custom_settings_blk } = require("blkGetters")
let { isGuestLogin, renewGuestRegistrationTags, needVerifyEmail, openVerifyEmail
} = require("%rGui/account/emailRegistrationState.nut")
let { openMsgBox, closeMsgBox } = require("%rGui/components/msgBox.nut")
let { isInMenuNoModals } = require("%rGui/mainMenu/mainMenuState.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { getCampaignStatsId } = require("%appGlobals/pServer/campaign.nut")
let { register_command } = require("console")
let { playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")

let GUEST_MSG_UID = "guestEmailRegistration"
let VERIFY_MSG_UID = "verifyEmail"
let ONLINE_BATTLES_TO_VERIFY = 10
let NOTIFY_PERIOD = 604800 

let isGuestMsgShowed = hardPersistWatched("isGuestMsgShowed", false)
let hasEnoughOnlineBattles = Computed(@()
  servProfile.get()?.sharedStatsByCampaign.findindex(@(s) (s?.battles ?? 0) > ONLINE_BATTLES_TO_VERIFY) != null)
let battlesTotal = Computed(@()
  servProfile.get()?.sharedStatsByCampaign
    .reduce(
      function(res, campaign) {
        let statsId = getCampaignStatsId(campaign)
        res[statsId] <- max(res?[statsId] ?? 0, (campaign?.battles ?? 0) + (campaign?.offlineBattles ?? 0))
        return res
      },
      {})
    .reduce(@(a, b) a + b))

let needShowGuestMsg = keepref(Computed(@() !isGuestMsgShowed.get()
  && isInMenuNoModals.get()
  && isGuestLogin.get()
  && ((playerLevelInfo.get()?.level ?? 0) > 1 || battlesTotal.get() > 2)))
let isVerifyMsgShowed = hardPersistWatched("isVerifyMsgShowed", false)

let isVerifyMsgTimerPassed = hardPersistWatched("isVerifyMsgTimerPassed", false)
let lastVerifyMsgTime = Watched(0)
function setVerifyMsgTimerPassed() {isVerifyMsgTimerPassed.set(true)}
lastVerifyMsgTime.subscribe(function(value) {
  if (serverTime.get() > value + NOTIFY_PERIOD)
    setVerifyMsgTimerPassed()
  else
    resetTimeout(value + NOTIFY_PERIOD - serverTime.get(), setVerifyMsgTimerPassed)
})
function loadVerifyMsgTime() { lastVerifyMsgTime.set(get_local_custom_settings_blk()?[VERIFY_MSG_UID] ?? 0) }
if (isLoggedIn.get())
  loadVerifyMsgTime()
isLoggedIn.subscribe(@(v) v ? loadVerifyMsgTime(): null)

let needShowVerifyMsg = keepref(Computed(@() !isVerifyMsgShowed.get()
  && isInMenuNoModals.get()
  && needVerifyEmail.get()
  && hasEnoughOnlineBattles.get()
  && isVerifyMsgTimerPassed.get()
  ))

function openGuestMsg() {
  if (!needShowGuestMsg.get())
    return
  renewGuestRegistrationTags()
  openMsgBox({
    uid = GUEST_MSG_UID
    text = "".concat(loc("msg/needRegistrationForProgress"), "\n", loc("mainmenu/desc/link_to_gaijin_account"))
    buttons = [
      { id = "later", isCancel = true, cb = @() isGuestMsgShowed.set(true) }
      {
        id = "linkEmail"
        styleId = "PRIMARY"
        isDefault = true
        function cb() {
          isGuestMsgShowed.set(true)
          eventbus_send("fMsgBox.onClick.openGuestEmailRegistration", {})
        }
      }
    ]
  })
}

let openGuestMsgDelayed = @() resetTimeout(0.5, openGuestMsg)
if (needShowGuestMsg.get())
  openGuestMsgDelayed()
needShowGuestMsg.subscribe(@(_) openGuestMsgDelayed())

isGuestLogin.subscribe(@(v) v ? null : closeMsgBox(GUEST_MSG_UID))

function saveVerifyMsgTime() {
  isVerifyMsgTimerPassed.set(false)
  lastVerifyMsgTime.set(serverTime.get())
  get_local_custom_settings_blk()[VERIFY_MSG_UID] = lastVerifyMsgTime.get()
  eventbus_send("saveProfile", {})
}

function openVerifyMsg() {
  if (!needShowVerifyMsg.get())
    return
  openMsgBox({
    uid = VERIFY_MSG_UID
    text = loc("mainmenu/email_not_verified")
    buttons = [
      { id = "later", isCancel = true,
        function cb() {
          isVerifyMsgShowed.set(true)
          saveVerifyMsgTime()
        }
      }
      { id = "verify", styleId = "PRIMARY", isDefault = true,
        function cb() {
          isVerifyMsgShowed.set(true)
          openVerifyEmail()
          saveVerifyMsgTime()
        }
      }
    ]
  })
}

let openVerifyMsgDelayed = @() resetTimeout(0.5, openVerifyMsg)
if (needShowVerifyMsg.get())
  openVerifyMsgDelayed()
needShowVerifyMsg.subscribe(@(_) openVerifyMsgDelayed())

needVerifyEmail.subscribe(@(v) v ? null : closeMsgBox(VERIFY_MSG_UID))

register_command(@() isGuestMsgShowed.set(false), "debug.reset_guest_msg_showed")
register_command(function() {
  lastVerifyMsgTime.set(0)
  get_local_custom_settings_blk()[VERIFY_MSG_UID] = lastVerifyMsgTime.get()
  eventbus_send("saveProfile", {})
  isVerifyMsgShowed.set(false)
}, "debug.reset_verify_msg_timer")

