from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_send
from "%sqstd/platform.nut" import is_ios, is_nswitch
from "%sqstd/string.nut" import utf8ToUpper
from "%sqstd/underscore.nut" import arrayByRows
from "%appGlobals/clientState/clientState.nut" import isInMenu
from "%appGlobals/commonUrl.nut" import ACTIVATE_PROMO_CODE_URL, LINK_TO_GAIJIN_ACCOUNT_URL
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%appGlobals/config/clanPresentation.nut" import mkClanBadge
from "%appGlobals/config/subsPresentation.nut" import getSubsPresentation, getPremIcon
from "%appGlobals/curCircuitOverride.nut" import isExternalOperator, getCurCircuitOverride
from "%appGlobals/loginState.nut" import curLoginType, LT_GAIJIN, LT_GOOGLE, LT_APPLE, LT_FACEBOOK, LT_HUAWEI
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/pServerApi.nut" import clansInProgress
from "%appGlobals/pServer/profile.nut" import playerLevelInfo
from "%appGlobals/permissions.nut" import can_link_to_gaijin_account, allow_subscriptions
from "%appGlobals/profileStates.nut" import myUserName, myUserId, myUserIdStr, myOperatorUserId, myOperatorUserIdStr
from "%appGlobals/timeToText.nut" import secondsToHoursLoc
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%rGui/account/emailRegistrationState.nut" import canUpgradeGuestAccountToGaijinID, openGuestEmailRegistration
from "%rGui/account/linkEmailForGaijinLogin.nut" import canLinkEmailForGaijinLogin, openLinkEmailForGaijinLogin
from "%rGui/clans/clanPermissions.nut" import CLAN_REMOVE, clanGrades, hasClanPermission
from "%rGui/clans/clanState.nut" import leaveClan, removeClan, getClanDisplayName
from "%rGui/clans/components/clanBadge.nut" import mkClanBadgePreview
from "%rGui/clans/currentClanState.nut" import currentClan, currentClanId, myClanGrade
from "%rGui/components/buttonStyles.nut" import defButtonHeight, PRIMARY, COMMON, INACTIVE
from "%rGui/components/clipboard.nut" import copyToClipboard
from "%rGui/components/levelBlockPkg.nut" import mkLevelBg
import "%rGui/components/mkIconBtn.nut" as mkIconBtn
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/components/spinner.nut" import mkSpinnerHideBlock, spinner
from "%rGui/components/starLevel.nut" import starLevelTiny
from "%rGui/components/textButton.nut" import buttonsVGap, mkCustomButton, mkButtonTextMultiline, textButtonPurchase,
  mergeStyles, iconTextButton
from "%rGui/components/unseenMark.nut" import priorityUnseenMark
from "%rGui/controlsMenu/gpActBtn.nut" import btnAUp
from "%rGui/decorators/decoratorState.nut" import myNameWithFrame, openDecoratorsScene, myAvatarImage,
  hasUnseenDecorators
from "%rGui/decorators/decoratorsPkg.nut" import mkTitle
from "%rGui/feedback/supportWnd.nut" import openSupportTicketWndOrUrl
from "%rGui/globals/fontUtils.nut" import getFontToFitWidth
from "%rGui/shop/goodsPreviewState.nut" import openSubsPreview
from "%rGui/shop/platformGoods.nut" import hasRestorePurchases, restorePurchases, platformPurchaseInProgress
from "%rGui/shop/shopState.nut" import subsByCategory
from "%rGui/state/profilePremium.nut" import havePremium, premiumEndsAt, hasPremiumSubs, hasVip
from "%rGui/style/stdColors.nut" import premiumTextColor
from "%rGui/style/gradients.nut" import simpleVerGrad




let canLinkAccountForWtCrossPromo = Computed(@() can_link_to_gaijin_account.get() && !is_nswitch
  && [ LT_GAIJIN, LT_GOOGLE, LT_HUAWEI, LT_APPLE, LT_FACEBOOK ].contains(curLoginType.get()))
let needShowCrossPromoWithWT = Computed(@() can_link_to_gaijin_account.get() && !is_nswitch
  && (canLinkAccountForWtCrossPromo.get() || canUpgradeGuestAccountToGaijinID.get()))

let canChangeAccount = Computed(@() isInMenu.get() && !is_nswitch)

let canRemoveClan = Computed(@() hasClanPermission(CLAN_REMOVE, clanGrades.get(), myClanGrade.get()))
let canUsePromoCodes = !is_ios && !is_nswitch

const avatarSize = hdpx(200)
const levelBlockSize = hdpx(60)
const borderColor = 0xFF000000
const borderWidth = hdpx(1)
const gap = hdpx(20)
const lvlInfoWidth = sw(45)
const infoRowHeight = hdpxi(100)
const infoRowSize = [SIZE_TO_CONTENT, infoRowHeight]
const premIconSize = infoRowHeight
const clanBadgeSize = infoRowHeight
const clanNameWidth = hdpx(440)

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
let levelMarkSize = array(2, levelBlockSize)
let levelMarkPos = array(2, (0.5 * levelBlockSize + 0.5).tointeger())
let levelMarkBg = mkLevelBg()
let levelMark = @() {
  watch = playerLevelInfo
  size = levelMarkSize
  pos = levelMarkPos
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    levelMarkBg
    {
      rendObj = ROBJ_TEXT
      text = playerLevelInfo.get().level - playerLevelInfo.get().starLevel
      pos = const [0, -hdpx(2)]
    }.__update(fontSmall)
    starLevelTiny(playerLevelInfo.get().starLevel, starLevelOvr)
    unitsResearchInfo
  ]
}

function mkAvatar() {
  const avatarBtnSize = hdpxi(40)
  let iconStateFlags = Watched(0)
  let unseenMarkBlock = {
    padding = hdpx(10)
    hplace = ALIGN_LEFT
    children = priorityUnseenMark
  }
  let editIconBlock = {
    hplace = ALIGN_RIGHT
    children = mkIconBtn("ui/gameuiskin#menu_edit.svg", avatarBtnSize, iconStateFlags)
  }
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
          !hasUnseenDecorators.get() ? null : unseenMarkBlock
          editIconBlock
        ]
      }
      levelMark
    ]
  }
}

function mkUserName() {
  const userNameBtnSize = hdpxi(40)
  let iconStateFlags = Watched(0)
  let copyIconBtn = mkIconBtn("ui/gameuiskin#icon_copy.svg", userNameBtnSize, iconStateFlags)
  return @() {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap
    children = [
      @() {
        watch = myNameWithFrame
        behavior = Behaviors.Button
        onClick = openDecoratorsScene
        sound = const { click = "meta_profile_edit" }
        rendObj = ROBJ_TEXT
        text = myNameWithFrame.get() ?? ""
      }.__update(fontMedium)
      @() {
        watch = iconStateFlags
        behavior = Behaviors.Button
        onElemState = @(s) iconStateFlags.set(s)
        onClick = @(evt) copyToClipboard(evt, myUserName.get())
        children = copyIconBtn
      }
    ]
  }
}

function mkUserId() {
  const idBtnSize = hdpxi(30)
  let iconStateFlags = Watched(0)
  let onClick = @(evt) copyToClipboard(evt, isExternalOperator()
    ? $"{myOperatorUserIdStr.get()} ({myUserIdStr.get()})"
    : myUserIdStr.get())
  return {
    behavior = Behaviors.Button
    onClick
    onElemState = @(s) iconStateFlags.set(s)
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap
    children = [
      @() {
        watch = [myUserId, myOperatorUserId]
        rendObj = ROBJ_TEXT
        text = isExternalOperator()
          ? "".concat(getCurCircuitOverride("operatorUserIdLocName", "ID"), colon, myOperatorUserId.get(),
              comma, "GameID", colon, myUserId.get())
          : "".concat(loc("options/userId"), colon, myUserId.get())
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
    ? Picture($"ui/gameuiskin#{premIconByStatus[status](allow_subscriptions.get())}:{premIconSize}:P")
    : Picture($"{getSubsPresentation(status).image}:0:P")
  color = 0xFFFFFFFF
  keepAspect = true
}

let clanBadge = mkClanBadgePreview(Computed(@() mkClanBadge(currentClan.get()?.textFields)), clanBadgeSize)

function clanName() {
  let text = getClanDisplayName(currentClan.get()?.textFields.name ?? "")
  let comp = {
    watch = currentClan
    rendObj = ROBJ_TEXT
    maxWidth = clanNameWidth
    text
    ...fontMedium
  }
  let font = getFontToFitWidth(comp, clanNameWidth, [fontTiny, fontSmall, fontMedium])

  return comp.__update(font)
}

let cardRoot = {
  size = FLEX_H
  rendObj = ROBJ_IMAGE
  image = simpleVerGrad
  padding = const hdpx(20)
  color = 0x70000000
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
}

let defSubCard = @(children) {
  ...cardRoot
  flow = FLOW_HORIZONTAL
  gap = const {size = FLEX}
  children = children
}

let mkConfirmBtn = @(btnText, confirmText, cb) iconTextButton("ui/gameuiskin#icon_exit.svg",
  utf8ToUpper(btnText),
  @() openMsgBox({
    text = confirmText
    buttons = [
      { id = "cancel", isCancel = true, styleId = "PRIMARY" }
      { text = btnText, cb }
    ]
  }),
  mergeStyles(COMMON, {
    iconOvr = {
      size = hdpx(50)
      keepAspect = true
      transform = { rotate = 180 }
    }
    textOvr = fontBoldTinyAccentedShaded
    childOvr = { gap = hdpx(20) }
    useFlexText = true
  }))

let leaveClanBtn = mkConfirmBtn(loc("clans/leaveBtn"), loc("clans/leaveRequest/confirm"),
  @() leaveClan(currentClanId.get()))
let disbandClanBtn = mkConfirmBtn(loc("clans/disbandBtn"), loc("clans/disbandRequest/confirm"),
  @() removeClan(currentClanId.get()))

let mkInfoCard = @(children) {
  ...cardRoot
  flow = FLOW_VERTICAL
  gap = hdpx(50)
  children = children
}

let mkInfoRow = @(children, ovr = {}) {
  size = infoRowSize
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  children
}.__update(ovr)

let mkPremAction = @(status) textButtonPurchase(
  utf8ToUpper(loc($"subscription/{status == "prem_inactive" ? "activate" : "upgrade"}")),
  @() openSubsPreview("vip", "account_page"),
  { hotkeys = [btnAUp], childOvr = fontBoldTinyAccentedShaded })

function mkDescription() {
  let premStatus = Computed(@() !havePremium.get() ? "prem_inactive"
    : !hasPremiumSubs.get() ? "prem_deprecated"
    : hasVip.get() ? "vip"
    : "prem")
  let hasAction = Computed(@() premStatus.get() != "prem_deprecated"
    && premStatus.get() != "vip"
    && null != subsByCategory.get().findvalue(@(v) v.len() > 0))

  return @() {
    watch = [allow_subscriptions, premStatus, hasAction, currentClan, canRemoveClan, clansInProgress]
    size = FLEX_H
    padding = const [hdpx(70), 0, 0, 0]
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    children = [
      !allow_subscriptions.get() ? null
        : currentClan.get() != null
          ? mkInfoCard([
              mkInfoRow([
                mkSubsIcon(premStatus.get())
                mkPremDescText(premStatus.get())
              ], { gap })
              hasAction.get() ? mkPremAction(premStatus.get()) : null
            ])
        : defSubCard([
            mkSubsIcon(premStatus.get())
            mkPremDescText(premStatus.get())
            hasAction.get() ? mkPremAction(premStatus.get()) : null
          ])
      currentClan.get() == null ? null
        : mkInfoCard([
            mkInfoRow([clanBadge, clanName], { gap })
            clansInProgress.get() ? spinner
              : canRemoveClan.get() ? disbandClanBtn
              : leaveClanBtn
          ])
    ]
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
  ovr = { minWidth = hdpx(370) }
}
let multilineButtonOvrStyle = { size = const [hdpx(300), SIZE_TO_CONTENT], lineSpacing = hdpx(-4) }.__update(fontBoldTinyAccentedShaded)

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

let isRestoringPurchases = Computed(@() platformPurchaseInProgress.get() != null)

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
        : mkSpinnerHideBlock(isRestoringPurchases,
            mkButton(loc("restorePurchases"), restorePurchases),
            {
              size = [ buttonsWidthStyle.ovr.minWidth, defButtonHeight ]
              halign = ALIGN_CENTER
              valign = ALIGN_CENTER
            })
    ].filter(@(v) v != null),
    3)

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
    mkDescription()
    { size = FLEX }
    buttons
  ]
}