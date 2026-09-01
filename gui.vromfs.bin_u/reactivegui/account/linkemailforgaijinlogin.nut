from "%globalsDarg/darg_library.nut" import *
from "auth_wt" import getPlayerSsoShortTokenAsync, YU2_OK
from "eventbus" import eventbus_send, eventbus_subscribe
from "%sqstd/platform.nut" import is_nswitch
from "%appGlobals/curCircuitOverride.nut" import getCurCircuitOverride
from "%appGlobals/loginState.nut" import authTags, curLoginType, LT_GOOGLE, LT_APPLE, LT_HUAWEI
from "%appGlobals/openForeignMsgBox.nut" import openFMsgBox
from "%appGlobals/permissions.nut" import can_link_email_for_gaijin_login


let logLinkEFGL = log_with_prefix("[LINKEFGL] ")


let lang = loc("current_lang")
let emailLinkUrlsCfg = {
  [LT_GOOGLE] = {
    noEmailTag = "gplogin",
    url = getCurCircuitOverride("gpEmailLinkURL", "https://login.gaijin.net/{lang}/account/link/googleplay?stoken={stoken}") 
  },
  [LT_APPLE] = {
    noEmailTag = "applelogin",
    url = getCurCircuitOverride("appleEmailLinkURL", "https://login.gaijin.net/{lang}/account/link/apple?stoken={stoken}") 
  },
  [LT_HUAWEI] = {
    noEmailTag = "hwlogin",
    url = getCurCircuitOverride("hwEmailLinkURL", "https://login.gaijin.net/{lang}/account/link/huawei?stoken={stoken}") 
  },
  
}

let canLinkEmailForGaijinLogin = Computed(@() can_link_email_for_gaijin_login.get() && !is_nswitch
  && (curLoginType.get() in emailLinkUrlsCfg)
  && authTags.get().contains(emailLinkUrlsCfg[curLoginType.get()].noEmailTag))

let openLinkEmailUrlImpl = @(stoken) curLoginType.get() in emailLinkUrlsCfg
  ? eventbus_send("openUrl", { baseUrl = emailLinkUrlsCfg[curLoginType.get()].url.subst({ lang, stoken }) })
  : null

eventbus_subscribe("onGetStokenToLinkEmailForGaijinLogin", function(msg) {
  let { status, stoken = null } = msg
  if (status != YU2_OK) {
    logLinkEFGL("Error on get SSO token = ", status)
    openFMsgBox({ text = loc("error/serverTemporaryUnavailable") })
    return
  }

  logLinkEFGL("Open link email URL")
  openLinkEmailUrlImpl(stoken)
})

function openLinkEmailForGaijinLogin() {
  if (!canLinkEmailForGaijinLogin.get())
    return
  logLinkEFGL("getPlayerSsoShortTokenAsync")
  getPlayerSsoShortTokenAsync("onGetStokenToLinkEmailForGaijinLogin")
}

return {
  canLinkEmailForGaijinLogin
  openLinkEmailForGaijinLogin
}
