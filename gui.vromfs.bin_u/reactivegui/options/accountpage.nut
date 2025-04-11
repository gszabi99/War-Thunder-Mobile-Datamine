from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { ACTIVATE_PROMO_CODE_URL, LINK_TO_GAIJIN_ACCOUNT_URL } = require("%appGlobals/commonUrl.nut")
let { curLoginType, LT_GOOGLE, LT_APPLE, LT_FACEBOOK, LT_HUAWEI } = require("%appGlobals/loginState.nut")
let { can_link_to_gaijin_account } = require("%appGlobals/permissions.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { canLinkEmailForGaijinLogin, openLinkEmailForGaijinLogin } = require("%rGui/account/linkEmailForGaijinLogin.nut")
let { contentWidth } = require("optionsStyle.nut")
let { textButtonCommon, textButtonPrimary, buttonsHGap } = require("%rGui/components/textButton.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { mkLevelBg } = require("%rGui/components/levelBlockPkg.nut")
let { starLevelTiny } = require("%rGui/components/starLevel.nut")
let { isInMenu } = require("%appGlobals/clientState/clientState.nut")
let { myUserId, myUserIdStr, myUserName } = require("%appGlobals/profileStates.nut")
let { premiumEndsAt } = require("%rGui/state/profilePremium.nut")
let { playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { premiumTextColor } = require("%rGui/style/stdColors.nut")
let { is_ios, is_nswitch } = require("%sqstd/platform.nut")
let { mkTitle } = require("%rGui/decorators/decoratorsPkg.nut")
let { myNameWithFrame, openDecoratorsScene, myAvatarImage, hasUnseenDecorators } = require("%rGui/decorators/decoratorState.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { openSupportTicketWndOrUrl } = require("%rGui/feedback/supportWnd.nut")
let { isCampaignWithUnitsResearch, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { copyToClipboard } = require("%rGui/components/clipboard.nut")
let mkIconBtn = require("%rGui/components/mkIconBtn.nut")
let { isGuestLogin, openGuestEmailRegistration } = require("%rGui/account/emailRegistrationState.nut")
let { hasRestorePurchases, restorePurchases, platformPurchaseInProgress } = require("%rGui/shop/platformGoods.nut")

let urlColor = 0xFF17C0FC
let urlHoverColor = 0xFF84E0FA
let urlLineWidth = hdpx(1)

let canLinkToGaijinAccount = Computed(@() can_link_to_gaijin_account.get() && !is_nswitch
  && [ LT_GOOGLE, LT_HUAWEI, LT_APPLE, LT_FACEBOOK ].contains(curLoginType.get()))
let canLinkToGaijinAccountForGuest = Computed(@() can_link_to_gaijin_account.get() && !is_nswitch
  && isGuestLogin.get())

let canChangeAccount = Computed(@() isInMenu.get() && !is_nswitch)

let canUsePromoCodes = !is_ios && !is_nswitch

let avatarSize = hdpx(200)
let levelBlockSize = hdpx(60)
let borderColor = 0xFF000000
let borderWidth = hdpx(1)
let gap = hdpx(20)
let lvlInfoWidth = sw(45)

let unitsResearchInfo = @() {
  watch = curCampaign
  size = [lvlInfoWidth, SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  hplace = ALIGN_LEFT
  pos = [levelBlockSize + gap, 0]
  text = loc(getCampaignPresentation(curCampaign.get()).playerLevelDescLocId)
}.__update(fontVeryTiny)

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
      text = playerLevelInfo.get().level - playerLevelInfo.get().starLevel
      pos = [0, -hdpx(2)]
    }.__update(fontSmall)
    starLevelTiny(playerLevelInfo.get().starLevel, starLevelOvr)
    isCampaignWithUnitsResearch.get() ? unitsResearchInfo : null
  ]
}

function mkAvatar() {
  let avatarBtnSize = hdpxi(40)
  let iconStateFlags = Watched(0)
  return {
    behavior = Behaviors.Button
    onClick = openDecoratorsScene
    onElemState = @(s) iconStateFlags.set(s)
    sound = { click = "meta_profile_edit" }
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
        image =  Picture($"{myAvatarImage.get()}:{avatarSize}:{avatarSize}:P")
        padding = hdpx(10)
        valign = ALIGN_TOP
        children = [
          !hasUnseenDecorators.get() ? null : {
            padding = hdpx(10)
            hplace = ALIGN_LEFT
            children = priorityUnseenMark
          }
          {
            hplace = ALIGN_RIGHT
            children = mkIconBtn("ui/gameuiskin#menu_edit.svg", avatarBtnSize, iconStateFlags)
          }
        ]
      }
      levelMark
    ]
  }
}

function mkUserName() {
  let userNameBtnSize = hdpxi(40)
  let iconStateFlags = Watched(0)
  return @() {
    watch = hasUnseenDecorators
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap
    children = [
      @() {
        watch = myNameWithFrame
        behavior = Behaviors.Button
        onClick = openDecoratorsScene
        sound = { click = "meta_profile_edit" }
        rendObj = ROBJ_TEXT
        text = myNameWithFrame.get() ?? ""
      }.__update(fontMedium)
      @() {
        watch = iconStateFlags
        behavior = Behaviors.Button
        onElemState = @(s) iconStateFlags.set(s)
        onClick = @(evt) copyToClipboard(evt, myUserName.get())
        children = mkIconBtn("ui/gameuiskin#icon_copy.svg", userNameBtnSize, iconStateFlags)
      }
    ]
  }
}

function mkUserId() {
  let idBtnSize = hdpxi(30)
  let iconStateFlags = Watched(0)
  return {
    behavior = Behaviors.Button
    onClick = @(evt) copyToClipboard(evt, myUserIdStr.get())
    onElemState = @(s) iconStateFlags.set(s)
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap
    children = [
      @() {
        watch = myUserId
        rendObj = ROBJ_TEXT
        text = "".concat(loc("options/userId"), colon, myUserId.get())
      }.__update(fontTiny)
      mkIconBtn("ui/gameuiskin#icon_copy.svg", idBtnSize, iconStateFlags)
    ]
  }
}

let premiumAccountTxt = loc("charServer/entitlement/PremiumAccount")
let mkPremiumTimeLeftText = function() {
  let res = { watch = [ premiumEndsAt ] }
  let timeLeft = max(0, premiumEndsAt.get() - serverTime.get())
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
    mkAvatar()
    {
      flow = FLOW_VERTICAL
      gap = hdpx(10)
      children = [
        mkUserName()
        mkTitle(fontSmall)
        mkUserId()
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

function mkLinkBtn(text, onClick) {
  let stateFlags = Watched(0)
  return function() {
    let color = stateFlags.get() & S_HOVER ? urlHoverColor : urlColor
    return {
      watch = stateFlags
      rendObj = ROBJ_TEXT
      text
      color

      behavior = Behaviors.Button
      onElemState = @(sf) stateFlags(sf)
      onClick

      children = {
        size = [flex(), urlLineWidth]
        vplace = ALIGN_BOTTOM
        rendObj = ROBJ_SOLID
        color
      }
    }.__update(fontSmall)
  }
}

let mkButtonRow = @(children) !children.findvalue(@(v) v != null) ? null
  : {
      flow = FLOW_HORIZONTAL
      gap = buttonsHGap
      children
    }

let mkLinksBlock = @(children) !children.findvalue(@(v) v != null) ? null
  : {
      flow = FLOW_VERTICAL
      children
    }

function buttons() {
  let rows = arrayByRows(
    [
      !canChangeAccount.get() ? null
        : textButtonCommon(loc("mainmenu/btnChangePlayer"), logoutMsgBox, buttonsWidthStyle)
      textButtonPrimary(loc("mainmenu/support"), openSupportTicketWndOrUrl, buttonsWidthStyle)
      canLinkToGaijinAccount.get()
        ? textButtonPrimary(loc("msgbox/btn_linkEmail"),
            @() eventbus_send("openUrl", { baseUrl = LINK_TO_GAIJIN_ACCOUNT_URL }),
            buttonsWidthStyle)
        : canLinkToGaijinAccountForGuest.get()
          ? textButtonPrimary(loc("msgbox/btn_linkEmail"),
              openGuestEmailRegistration,
              buttonsWidthStyle)
        : null
      !canUsePromoCodes ? null
        : textButtonPrimary(loc("mainmenu/btnActivateCode"),
            @() eventbus_send("openUrl", { baseUrl = ACTIVATE_PROMO_CODE_URL }),
            buttonsWidthStyle)
      !hasRestorePurchases ? null
        : mkSpinnerHideBlock(Computed(@() platformPurchaseInProgress.get() != null),
            textButtonPrimary(loc("restorePurchases"), restorePurchases, buttonsWidthStyle),
            {
              size = [ buttonsWidthStyle.ovr.minWidth, defButtonHeight ]
              halign = ALIGN_CENTER
              valign = ALIGN_CENTER
            })
    ].filter(@(v) v != null),
    2)

  return {
    watch = [canLinkToGaijinAccount, canLinkEmailForGaijinLogin, canChangeAccount, canLinkToGaijinAccountForGuest]
    flow = FLOW_VERTICAL
    gap = buttonsHGap
    children = rows.map(mkButtonRow)
      .append(mkLinksBlock([
        !canLinkEmailForGaijinLogin.get() ? null
          : mkLinkBtn(loc("link_email_for_alt_auth"), openLinkEmailForGaijinLogin)
      ]))
  }
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