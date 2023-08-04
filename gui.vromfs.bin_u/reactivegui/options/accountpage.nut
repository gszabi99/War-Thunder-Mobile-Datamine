from "%globalsDarg/darg_library.nut" import *
let { send } = require("eventbus")
let { PRIVACY_POLICY_URL } = require("%appGlobals/legal.nut")
let { authTags } = require("%appGlobals/loginState.nut")
let { can_link_to_gaijin_account } = require("%appGlobals/permissions.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%rGui/globals/timeToText.nut")
let { contentWidth } = require("optionsStyle.nut")
let { textButtonCommon, textButtonPrimary, buttonsHGap } = require("%rGui/components/textButton.nut")
let { mkLevelBg, maxLevelStarChar } = require("%rGui/components/levelBlockPkg.nut")
let { isInMenu } = require("%appGlobals/clientState/clientState.nut")
let { myAvatar, myUserId } = require("%appGlobals/profileStates.nut")
let { premiumEndsAt } = require("%rGui/state/profilePremium.nut")
let { playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { premiumTextColor, hoverColor } = require("%rGui/style/stdColors.nut")
let { is_ios } = require("%sqstd/platform.nut")
let { mkTitle } = require("%rGui/decorators/decoratorsPkg.nut")
let { myNameWithFrame, openDecoratorsScene } = require("%rGui/decorators/decoratorState.nut")

let DELETE_PROFILE_URL = "https://support.gaijin.net/hc/en-us/articles/200071071-Account-Deletion-Suspension-"
let LINK_TO_GAIJIN_ACCOUNT_URL = "auto_local auto_login https://wtmobile.com/connect"
let ACTIVATE_PROMO_CODE_URL = "auto_local auto_login https://store.gaijin.net/activate.php"

let canLinkToGaijinAccount = Computed(@() can_link_to_gaijin_account.value
  && (authTags.value.contains("gplogin") || authTags.value.contains("applelogin") || authTags.value.contains("fblogin")))

let avatarSize = hdpx(200)
let levelBlockSize = hdpx(60)
let imgBtnSize = hdpx(50).tointeger()
let borderColor = 0xFF000000
let borderWidth = hdpx(1)
let gap = hdpx(20)

let levelMark = {
  size = array(2, levelBlockSize)
  pos = array(2, (0.5 * levelBlockSize + 0.5).tointeger())
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  children = [
    mkLevelBg()
    @() {
      watch = playerLevelInfo
      rendObj = ROBJ_TEXT
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      text = playerLevelInfo.value.isMaxLevel ? maxLevelStarChar : playerLevelInfo.value.level
      pos = [0, -hdpx(2)]
    }.__update(fontSmall)
  ]
}

let avatar = {
  size = array(2, avatarSize + 2 * borderWidth)
  padding = borderWidth
  rendObj = ROBJ_BOX
  borderWidth
  borderColor = borderColor
  children = [
    @() {
      watch = myAvatar
      size = flex()
      rendObj = ROBJ_IMAGE
      image = Picture($"!ui/images/avatars/{myAvatar.value}.avif")
    }
    levelMark
  ]
}

let pnStateFlags = Watched(0)
let myUserNameBtn = @() {
  behavior = Behaviors.Button
  onClick = openDecoratorsScene
  onElemState = @(s) pnStateFlags(s)
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap
  children = [
    @() {
      watch = myNameWithFrame
      rendObj = ROBJ_TEXT
      text = myNameWithFrame.value ?? ""
    }.__update(fontMedium)
    @() {
      watch = pnStateFlags
      size = array(2, imgBtnSize)
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#menu_edit.svg:{imgBtnSize}:{imgBtnSize}")
      color = pnStateFlags.value & S_HOVER ? hoverColor : 0xFFFFFFFF
      transform = { scale = pnStateFlags.value & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
      transitions = [{ prop = AnimProp.scale, duration = 0.1, easing = InOutQuad }]
    }
  ]
}

let premiumAccountTxt = loc("charServer/entitlement/PremiumAccount")
let mkPremiumTimeLeftText = function() {
  let res = { watch = [ premiumEndsAt ] }
  let timeLeft = max(0, premiumEndsAt.value - serverTime.value)
  if (timeLeft == 0)
    return res.__update({ size = flex() })
  res.watch.append(serverTime)
  return res.__update({
    padding = [hdpx(40), 0, hdpx(25), 0]
    rendObj = ROBJ_TEXT
    text = "".concat(premiumAccountTxt, colon, secondsToHoursLoc(timeLeft))
    color = premiumTextColor
  }, fontTiny)
}

let userInfoBlock = {
  flow = FLOW_HORIZONTAL
  gap
  children = [
    avatar
    {
      flow = FLOW_VERTICAL
      gap
      children = [
        myUserNameBtn
        mkTitle(fontSmall)
        @() {
          watch = myUserId
          rendObj = ROBJ_TEXT
          text = "".concat(loc("options/userId"), colon, myUserId.value)
        }.__update(fontTiny)
      ]
    }
  ]
}

let buttonsWidthStyle = {
  ovr = {
    minWidth = hdpx(500)
  }
}

let logoutMsgBox = @() openMsgBox({
  text = loc("mainmenu/questionChangePlayer")
  buttons = [
    { id = "no", isCancel = true }
    { id = "yes", styleId = "PRIMARY", isDefault = true, cb = @() send("logOutManually", {}) }
  ]
})

let mkButtonRow = @(children) !children.findvalue(@(v) v != null) ? null
  : {
      flow = FLOW_HORIZONTAL
      gap = buttonsHGap
      children
    }

let buttons = @() {
  watch = [canLinkToGaijinAccount, isInMenu]
  flow = FLOW_VERTICAL
  gap = buttonsHGap
  children = [
    !isInMenu.value ? null
      : mkButtonRow([
          textButtonCommon(loc("mainmenu/btnChangePlayer"), logoutMsgBox, buttonsWidthStyle)
          textButtonCommon(loc("options/delete_profile"),
            @() send("openUrl", { baseUrl = DELETE_PROFILE_URL, useExternalBrowser = true }),
            buttonsWidthStyle)
        ])
    mkButtonRow([
      !canLinkToGaijinAccount.value ? null
        : textButtonPrimary(loc("msgbox/btn_linkEmail"),
            @() send("openUrl", { baseUrl = LINK_TO_GAIJIN_ACCOUNT_URL, useExternalBrowser = true }),
            buttonsWidthStyle)
      is_ios ? null
        : textButtonPrimary(loc("mainmenu/btnActivateCode"),
            @() send("openUrl", { baseUrl = ACTIVATE_PROMO_CODE_URL, useExternalBrowser = true }),
            buttonsWidthStyle)
    ])
    mkButtonRow([
      textButtonPrimary(loc("mainmenu/support"),
        @() send("openUrl", { baseUrl = loc("url/support"), useExternalBrowser = true }),
        buttonsWidthStyle)
      textButtonPrimary(loc("options/personalData"), @() send("openUrl", { baseUrl = PRIVACY_POLICY_URL }), buttonsWidthStyle)
    ])
  ]
}

return {
  size = [contentWidth, flex()]
  padding = [0, 0, hdpx(40), 0]
  flow = FLOW_VERTICAL
  children = [
    userInfoBlock
    mkPremiumTimeLeftText
    { size = flex() }
    buttons
  ]
}