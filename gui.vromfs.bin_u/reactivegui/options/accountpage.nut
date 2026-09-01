from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_send
from "%sqstd/platform.nut" import is_ios, is_nswitch
from "%sqstd/string.nut" import utf8ToUpper
from "%sqstd/underscore.nut" import arrayByRows
from "%appGlobals/clientState/clientState.nut" import isInMenu
from "%appGlobals/commonUrl.nut" import ACTIVATE_PROMO_CODE_URL, LINK_TO_GAIJIN_ACCOUNT_URL
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%appGlobals/config/subsPresentation.nut" import getSubsPresentation, getPremIcon
from "%appGlobals/curCircuitOverride.nut" import getCurCircuitOverride
from "%appGlobals/loginState.nut" import curLoginType, LT_GAIJIN, LT_GOOGLE, LT_APPLE, LT_FACEBOOK, LT_HUAWEI
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/profile.nut" import playerLevelInfo
from "%appGlobals/permissions.nut" import can_link_to_gaijin_account, allow_subscriptions
from "%appGlobals/profileStates.nut" import myUserId, myUserIdStr, myUserName
from "%appGlobals/timeToText.nut" import secondsToHoursLoc
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%rGui/account/emailRegistrationState.nut" import canUpgradeGuestAccountToGaijinID, openGuestEmailRegistration
from "%rGui/account/linkEmailForGaijinLogin.nut" import canLinkEmailForGaijinLogin, openLinkEmailForGaijinLogin
from "%rGui/components/buttonStyles.nut" import defButtonHeight, PRIMARY, COMMON, INACTIVE
from "%rGui/components/clipboard.nut" import copyToClipboard
from "%rGui/components/levelBlockPkg.nut" import mkLevelBg
import "%rGui/components/mkIconBtn.nut" as mkIconBtn
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/components/spinner.nut" import mkSpinnerHideBlock
from "%rGui/components/starLevel.nut" import starLevelTiny
from "%rGui/components/textButton.nut" import buttonsVGap, mkCustomButton, mkButtonTextMultiline, textButtonPurchase,
  mergeStyles
from "%rGui/components/unseenMark.nut" import priorityUnseenMark
from "%rGui/controlsMenu/gpActBtn.nut" import btnAUp
from "%rGui/decorators/decoratorState.nut" import myNameWithFrame, openDecoratorsScene, myAvatarImage,
  hasUnseenDecorators
from "%rGui/decorators/decoratorsPkg.nut" import mkTitle
from "%rGui/feedback/supportWnd.nut" import openSupportTicketWndOrUrl
from "%rGui/shop/goodsPreviewState.nut" import openSubsPreview
from "%rGui/shop/platformGoods.nut" import hasRestorePurchases, restorePurchases, platformPurchaseInProgress
from "%rGui/shop/shopState.nut" import subsByCategory
from "%rGui/state/profilePremium.nut" import havePremium, premiumEndsAt, hasPremiumSubs, hasVip
from "%rGui/style/stdColors.nut" import premiumTextColor





let canLinkAccountForWtCrossPromo = Computed(@() can_link_to_gaijin_account.get() && !is_nswitch
  && [ LT_GAIJIN, LT_GOOGLE, LT_HUAWEI, LT_APPLE, LT_FACEBOOK ].contains(curLoginType.get()))
let needShowCrossPromoWithWT = Computed(@() can_link_to_gaijin_account.get() && !is_nswitch
  && (canLinkAccountForWtCrossPromo.get() || canUpgradeGuestAccountToGaijinID.get()))

let canChangeAccount = Computed(@() isInMenu.get() && !is_nswitch)

let canUsePromoCodes = !is_ios && !is_nswitch

const avatarSize = hdpx(200)
const levelBlockSize = hdpx(60)
const borderColor = 0xFF000000
const borderWidth = hdpx(1)
const gap = hdpx(20)
const lvlInfoWidth = sw(45)
let premIconSize = [avatarSize, (avatarSize / 1.4).tointeger()]

let unitsResearchInfo = @() {
  watch = curCampaign
  size = const [lvlInfoWidth, SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  hplace = ALIGN_LEFT
  pos = const [levelBlockSize + gap, 0]
  text = loc(getCampaignPresentation(curCampaign.get()).playerLevelDescLocId)
}.__update(fontVeryTiny)

let starLevelOvr = { pos = const [0, ph(40)] }
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
    unitsResearchInfo
  ]
}

function mkAvatar() {
  const avatarBtnSize = hdpxi(40)
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
        watch = [myAvatarImage, hasUnseenDecorators]
        size = const [avatarSize, avatarSize]
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
  const userNameBtnSize = hdpxi(40)
  let iconStateFlags = Watched(0)
  return @() {
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
  const idBtnSize = hdpxi(30)
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
    : Picture($"{getSubsPresentation(status).image}:0:P")
  color = 0xFFFFFFFF
  keepAspect = true
}

let mkPremAction = @(status) textButtonPurchase(
  utf8ToUpper(loc($"subscription/{status == "prem_inactive" ? "activate" : "upgrade"}")),
  @() openSubsPreview("vip", "account_page"),
  { hotkeys = [btnAUp], childOvr = fontBoldTinyAccentedShaded })

function mkPremiumDescription() {
  let premStatus = Computed(@() !havePremium.get() ? "prem_inactive"
    : !hasPremiumSubs.get() ? "prem_deprecated"
    : hasVip.get() ? "vip"
    : "prem")
  let hasAction = Computed(@() premStatus.get() != "prem_deprecated"
    && premStatus.get() != "vip"
    && null != subsByCategory.get().findvalue(@(v) v.len() > 0))

  return @() {
    watch = [allow_subscriptions, premStatus, hasAction]
    size = FLEX_H
    children = !allow_subscriptions.get() ? null
      : {
          size = FLEX_H
          rendObj = ROBJ_SOLID
          padding = const [hdpx(10), hdpx(20)]
          color = 0x70000000
          margin = const [hdpx(70), 0, 0, 0]
          flow = FLOW_HORIZONTAL
          valign = ALIGN_CENTER
          gap = {size = FLEX}
          children = [
            mkSubsIcon(premStatus.get())
            mkPremDescText(premStatus.get())
            hasAction.get() ? mkPremAction(premStatus.get()) : null
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
  ovr = { minWidth = hdpx(550) }
}
let multilineButtonOvrStyle = { size = const [hdpx(450), SIZE_TO_CONTENT], lineSpacing = hdpx(-4) }.__update(fontBoldTinyAccentedShaded)

let mkButton = @(locId, cb, style = PRIMARY) mkCustomButton(
  mkButtonTextMultiline(utf8ToUpper(loc(locId)), multilineButtonOvrStyle),
  cb,
  mergeStyles(style, buttonsWidthStyle))

let logoutMsgBox = @() openMsgBox({
  text = loc("mainmenu/questionChangePlayer")
  buttons = [
    { id = "cancel", isCancel = true }
    { id = "logout", styleId = "PRIMARY", isDefault = true, cb = @() eventbus_send("logOutManually", {}) }
  ]
})

function onCrossPromoWithWT() {
  if (canLinkAccountForWtCrossPromo.get())
    eventbus_send("openUrl", { baseUrl = LINK_TO_GAIJIN_ACCOUNT_URL })
  else if (canUpgradeGuestAccountToGaijinID.get())
    openMsgBox({
      text = "".concat(loc("msg/needRegistrationForThis"), "\n", loc("mainmenu/desc/link_to_gaijin_account"))
      buttons = [
        { id = "cancel", isCancel = true }
        { id = "linkEmail", styleId = "PRIMARY", isDefault = true, cb = openGuestEmailRegistration }
      ]
    })
}

let mkButtonRow = @(children) !children.findvalue(@(v) v != null) ? null
  : {
      flow = FLOW_HORIZONTAL
      gap = buttonsVGap
      children
    }

function buttons() {
  let watch = [ canChangeAccount, canLinkEmailForGaijinLogin, canUpgradeGuestAccountToGaijinID,
    needShowCrossPromoWithWT, canLinkAccountForWtCrossPromo ]
  let rows = arrayByRows(
    [
      !canChangeAccount.get() ? null
        : mkButton(loc("mainmenu/btnChangePlayer"), logoutMsgBox, COMMON)
      mkButton(loc("mainmenu/support"), openSupportTicketWndOrUrl)
      canLinkEmailForGaijinLogin.get()
          ? mkButton(loc("upgrade_account_to_gaijin_id", {operatorName = getCurCircuitOverride("operatorName", loc("operator_account_name"))}), openLinkEmailForGaijinLogin)
        : canUpgradeGuestAccountToGaijinID.get()
          ? mkButton(loc("upgrade_account_to_gaijin_id", {operatorName = getCurCircuitOverride("operatorName", loc("operator_account_name"))}), openGuestEmailRegistration)
        : null
      !needShowCrossPromoWithWT.get() ? null
        : mkButton(loc("participate_in_crosspromo_wt"), onCrossPromoWithWT,
            canLinkAccountForWtCrossPromo.get() ? PRIMARY : INACTIVE)
      !canUsePromoCodes ? null
        : mkButton(loc("mainmenu/btnActivateCode"), @() eventbus_send("openUrl", { baseUrl = ACTIVATE_PROMO_CODE_URL }))
      !hasRestorePurchases ? null
        : mkSpinnerHideBlock(Computed(@() platformPurchaseInProgress.get() != null),
            mkButton(loc("restorePurchases"), restorePurchases),
            {
              size = [ buttonsWidthStyle.ovr.minWidth, defButtonHeight ]
              halign = ALIGN_CENTER
              valign = ALIGN_CENTER
            })
    ].filter(@(v) v != null),
    2)

  return {
    watch
    flow = FLOW_VERTICAL
    gap = buttonsVGap
    children = rows.map(mkButtonRow)
  }
}

return {
  size = FLEX_V
  padding = const [0, 0, hdpx(40), 0]
  flow = FLOW_VERTICAL
  children = [
    userInfoBlock
    mkPremiumDescription()
    { size = FLEX }
    buttons
  ]
}