from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { PRIVACY_POLICY_URL } = require("%appGlobals/legal.nut")
let { ACTIVATE_PROMO_CODE_URL, LINK_TO_GAIJIN_ACCOUNT_URL } = require("%appGlobals/commonUrl.nut")
let { curLoginType, LT_GOOGLE, LT_APPLE, LT_FACEBOOK } = require("%appGlobals/loginState.nut")
let { can_link_to_gaijin_account } = require("%appGlobals/permissions.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { contentWidth } = require("optionsStyle.nut")
let { textButtonCommon, textButtonPrimary, buttonsHGap } = require("%rGui/components/textButton.nut")
let { mkLevelBg } = require("%rGui/components/levelBlockPkg.nut")
let { starLevelTiny } = require("%rGui/components/starLevel.nut")
let { isInMenu } = require("%appGlobals/clientState/clientState.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { premiumEndsAt } = require("%rGui/state/profilePremium.nut")
let { playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { premiumTextColor, hoverColor } = require("%rGui/style/stdColors.nut")
let { is_ios, is_nswitch } = require("%sqstd/platform.nut")
let { mkTitle } = require("%rGui/decorators/decoratorsPkg.nut")
let { myNameWithFrame, openDecoratorsScene, myAvatarImage, hasUnseenDecorators } = require("%rGui/decorators/decoratorState.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { openSuportWebsite } = require("%rGui/feedback/supportState.nut")

let canLinkToGaijinAccount = Computed(@() can_link_to_gaijin_account.value && !is_nswitch
  && [ LT_GOOGLE, LT_APPLE, LT_FACEBOOK ].contains(curLoginType.value))

let canChangeAccount = Computed(@() isInMenu.value && !is_nswitch)

let canUsePromoCodes = !is_ios && !is_nswitch

let avatarSize = hdpx(200)
let levelBlockSize = hdpx(60)
let imgBtnSize = hdpx(50).tointeger()
let borderColor = 0xFF000000
let borderWidth = hdpx(1)
let gap = hdpx(20)

let starLevelOvr = { pos = [0, ph(40)] }
let levelMark = @() {
  watch = playerLevelInfo
  size = array(2, levelBlockSize)
  pos = array(2, (0.5 * levelBlockSize + 0.5).tointeger())
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    mkLevelBg()
    {
      rendObj = ROBJ_TEXT
      text = playerLevelInfo.value.level - playerLevelInfo.value.starLevel
      pos = [0, -hdpx(2)]
    }.__update(fontSmall)
    starLevelTiny(playerLevelInfo.value.starLevel, starLevelOvr)
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
      watch = myAvatarImage
      size = [avatarSize, avatarSize]
      rendObj = ROBJ_IMAGE
      image =  Picture($"{myAvatarImage.value}:{avatarSize}:{avatarSize}:P")
    }
    levelMark
  ]
}

let pnStateFlags = Watched(0)
let myUserNameBtn = @() {
  watch = hasUnseenDecorators
  behavior = Behaviors.Button
  onClick = openDecoratorsScene
  sound = { click  = "meta_profile_edit" }
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
    !hasUnseenDecorators.value ? null
      : priorityUnseenMark
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
    minWidth = hdpx(550)
  }
}

let logoutMsgBox = @() openMsgBox({
  text = loc("mainmenu/questionChangePlayer")
  buttons = [
    { id = "cancel", isCancel = true }
    { id = "logout", styleId = "PRIMARY", isDefault = true, cb = @() eventbus_send("logOutManually", {}) }
  ]
})

let logoutToDeleteAccountMsgBox = @() openMsgBox({
  text = loc("mainmenu/questionDeleteAcount")
  buttons = [
    { id = "cancel", isCancel = true }
    { id = "delete", text = loc("mainmenu/btnAccountDelete"), styleId = "PRIMARY", isDefault = true, cb = @() eventbus_send("deleteAccount", {}) }
  ]
})

let mkButtonRow = @(children) !children.findvalue(@(v) v != null) ? null
  : {
      flow = FLOW_HORIZONTAL
      gap = buttonsHGap
      children
    }

let buttons = @() {
  watch = [canLinkToGaijinAccount, canChangeAccount]
  flow = FLOW_VERTICAL
  gap = buttonsHGap
  children = [
    !canChangeAccount.value ? null
      : mkButtonRow([
          textButtonCommon(loc("mainmenu/btnChangePlayer"), logoutMsgBox, buttonsWidthStyle)
          textButtonCommon(loc("mainmenu/btnAccountDelete"), logoutToDeleteAccountMsgBox, buttonsWidthStyle)
        ])
    mkButtonRow([
      !canLinkToGaijinAccount.value ? null
        : textButtonPrimary(loc("msgbox/btn_linkEmail"),
            @() eventbus_send("openUrl", { baseUrl = LINK_TO_GAIJIN_ACCOUNT_URL }),
            buttonsWidthStyle)
      !canUsePromoCodes ? null
        : textButtonPrimary(loc("mainmenu/btnActivateCode"),
            @() eventbus_send("openUrl", { baseUrl = ACTIVATE_PROMO_CODE_URL }),
            buttonsWidthStyle)
    ])
    mkButtonRow([
      textButtonPrimary(loc("mainmenu/support"),
        openSuportWebsite,
        buttonsWidthStyle)
      textButtonPrimary(loc("options/personalData"), @() eventbus_send("openUrl", { baseUrl = PRIVACY_POLICY_URL }), buttonsWidthStyle)
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