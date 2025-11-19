from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { eventbus_send } = require("eventbus")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { ACTIVATE_PROMO_CODE_URL, LINK_TO_GAIJIN_ACCOUNT_URL } = require("%appGlobals/commonUrl.nut")
let { curLoginType, LT_GOOGLE, LT_APPLE, LT_FACEBOOK, LT_HUAWEI } = require("%appGlobals/loginState.nut")
let { can_link_to_gaijin_account, allow_subscriptions } = require("%appGlobals/permissions.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { getSubsPresentation, getPremIcon } = require("%appGlobals/config/subsPresentation.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { canLinkEmailForGaijinLogin, openLinkEmailForGaijinLogin } = require("%rGui/account/linkEmailForGaijinLogin.nut")
let { buttonsVGap, mkCustomButton, mkButtonTextMultiline, textButtonPurchase, mergeStyles } = require("%rGui/components/textButton.nut")
let { defButtonHeight, PRIMARY, COMMON } = require("%rGui/components/buttonStyles.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { mkLevelBg } = require("%rGui/components/levelBlockPkg.nut")
let { starLevelTiny } = require("%rGui/components/starLevel.nut")
let { isInMenu } = require("%appGlobals/clientState/clientState.nut")
let { myUserId, myUserIdStr, myUserName } = require("%appGlobals/profileStates.nut")
let { havePremium, premiumEndsAt, hasPremiumSubs, hasVip } = require("%rGui/state/profilePremium.nut")
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
let { openSubsPreview } = require("%rGui/shop/goodsPreviewState.nut")
let { btnAUp } = require("%rGui/controlsMenu/gpActBtn.nut")


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
let premIconSize = [avatarSize, (avatarSize / 1.4).tointeger()]

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

let premDescByStatus = {
  prem_inactive = loc("subscription/desc/inactive")
  vip = loc("subscription/desc/vip/active")
  prem = loc("subscription/desc/prem/active")
}

let premIconByStatus = {
  prem_inactive = @(_) "subs_inactive.avif"
  prem_deprecated = @(perm) getPremIcon(perm, "prem_deprecated")
}

function mkPremDescText(status) {
  let text = premDescByStatus?[status]
  let timeLeft = Computed(@() havePremium.get() && !hasPremiumSubs.get()
    ? max(0, premiumEndsAt.get() - serverTime.get())
    : 0)

  return @() {
    watch = timeLeft
    children = {
      rendObj = ROBJ_TEXT
      text = text ?? "".concat(loc("charServer/entitlement/PremiumAccount"), colon, secondsToHoursLoc(timeLeft.get()))
      color = premiumTextColor
    }.__update(fontTiny)
  }
}

let mkSubsIcon = @(status) @() {
  watch = allow_subscriptions
  size = premIconSize
  rendObj = ROBJ_IMAGE
  image = status in premIconByStatus
    ? Picture($"ui/gameuiskin#{premIconByStatus[status](allow_subscriptions.get())}:{premIconSize[0]}:{premIconSize[1]}:P")
    : Picture($"{getSubsPresentation(status).icon}:0:P")
  color = 0xFFFFFFFF
  keepAspect = true
}

let mkPremAction = @(status) status == "prem_deprecated" || status == "vip"
  ? null
  : textButtonPurchase(utf8ToUpper(loc($"subscription/{status == "prem_inactive" ? "activate" : "upgrade"}")),
    @() openSubsPreview("vip"),
    { hotkeys = [btnAUp], childOvr = fontTinyAccentedShadedBold })

function mkPremiumDescription() {
  let premStatus = Computed(@() !havePremium.get() ? "prem_inactive"
    : !hasPremiumSubs.get() ? "prem_deprecated"
    : hasVip.get() ? "vip"
    : "prem")

  return @() {
    watch = [allow_subscriptions, premStatus]
    size = FLEX_H
    children = !allow_subscriptions.get() ? null
      : {
          size = FLEX_H
          rendObj = ROBJ_SOLID
          padding = [hdpx(10), hdpx(20)]
          color = 0x70000000
          margin = [hdpx(70), 0, 0, 0]
          flow = FLOW_HORIZONTAL
          valign = ALIGN_CENTER
          gap = {size = flex()}
          children = [
            mkSubsIcon(premStatus.get())
            mkPremDescText(premStatus.get())
            mkPremAction(premStatus.get())
          ]
        }
  }
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

let multilineButtonOvrStyle = { size = const [hdpx(450), SIZE_TO_CONTENT], lineSpacing = hdpx(-4) }.__update(fontTinyAccentedShadedBold)

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
      onElemState = @(sf) stateFlags.set(sf)
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
      gap = buttonsVGap
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
        : mkCustomButton(
            mkButtonTextMultiline(utf8ToUpper(loc("mainmenu/btnChangePlayer")), multilineButtonOvrStyle),
            logoutMsgBox,
            mergeStyles(COMMON, buttonsWidthStyle))
      mkCustomButton(
        mkButtonTextMultiline(utf8ToUpper(loc("mainmenu/support")), multilineButtonOvrStyle),
        openSupportTicketWndOrUrl,
        mergeStyles(PRIMARY, buttonsWidthStyle))
      canLinkToGaijinAccount.get()
        ? mkCustomButton(
            mkButtonTextMultiline(utf8ToUpper(loc("msgbox/btn_linkEmail")), multilineButtonOvrStyle),
            @() eventbus_send("openUrl", { baseUrl = LINK_TO_GAIJIN_ACCOUNT_URL }),
            mergeStyles(PRIMARY, buttonsWidthStyle))
        : canLinkToGaijinAccountForGuest.get()
          ? mkCustomButton(
              mkButtonTextMultiline(utf8ToUpper(loc("msgbox/btn_linkEmail")), multilineButtonOvrStyle),
              openGuestEmailRegistration,
              mergeStyles(PRIMARY, buttonsWidthStyle))
        : null
      !canUsePromoCodes ? null
        : mkCustomButton(
            mkButtonTextMultiline(utf8ToUpper(loc("mainmenu/btnActivateCode")), multilineButtonOvrStyle),
            @() eventbus_send("openUrl", { baseUrl = ACTIVATE_PROMO_CODE_URL }),
            mergeStyles(PRIMARY, buttonsWidthStyle))
      !hasRestorePurchases ? null
        : mkSpinnerHideBlock(Computed(@() platformPurchaseInProgress.get() != null),
            mkCustomButton(
              mkButtonTextMultiline(utf8ToUpper(loc("restorePurchases")), multilineButtonOvrStyle),
              restorePurchases,
              mergeStyles(PRIMARY, buttonsWidthStyle)),
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
    gap = buttonsVGap
    children = rows.map(mkButtonRow)
      .append(mkLinksBlock([
        !canLinkEmailForGaijinLogin.get() ? null
          : mkLinkBtn(loc("link_email_for_alt_auth"), openLinkEmailForGaijinLogin)
      ]))
  }
}

return {
  size = FLEX_V
  padding = const [0, 0, hdpx(40), 0]
  flow = FLOW_VERTICAL
  children = [
    userInfoBlock
    mkPremiumDescription()
    { size = flex() }
    buttons
  ]
}