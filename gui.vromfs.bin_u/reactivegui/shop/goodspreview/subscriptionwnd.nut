from "%globalsDarg/darg_library.nut" import *
let mkTextRow = require("%darg/helpers/mkTextRow.nut")
let { register_command } = require("console")
let { ceil } = require("%sqstd/math.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { TIME_DAY_IN_SECONDS_F } = require("%sqstd/time.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { subscriptions } = require("%appGlobals/pServer/campaign.nut")
let { PRIVACY_POLICY_URL, TERMS_OF_SERVICE_URL } = require("%appGlobals/legal.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { getSubsPresentation, getSubsName } = require("%appGlobals/config/subsPresentation.nut")
let { can_upgrade_subscription } = require("%appGlobals/permissions.nut")
let { openedSubsId, closeSubsPreview, openSubsPreview } = require("%rGui/shop/goodsPreviewState.nut")
let { allSubs, subsGroups } = require("%rGui/shop/shopState.nut")
let { activatePlatfromSubscription, changeSubscription, platformPurchaseInProgress, platformSubs
} = require("%rGui/shop/platformGoods.nut")
let { getSubsPeriodString } = require("%rGui/shop/shopCommon.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { modalWndBg, modalWndHeaderBg } = require("%rGui/components/modalWnd.nut")
let { closeWndBtn } = require("%rGui/components/closeWndBtn.nut")
let { textButtonPurchase, mkCustomButton, mergeStyles } = require("%rGui/components/textButton.nut")
let { defButtonMinWidth, defButtonHeight, COMMON } = require("%rGui/components/buttonStyles.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { urlText } = require("%rGui/components/urlText.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { premiumEndsAt, activeInternalSubs } = require("%rGui/state/profilePremium.nut")
let { smallGap, textColor, premiumRowsCfg, vipRowsCfg, mkBonusRow } = require("%rGui/shop/goodsPreview/subscriptionDescComp.nut")


let WND_UID = "subscription_wnd"
let OLD_SUBSCRIPTION_WND_UID = "old_subscription_wnd"

let wndWidth = hdpx(1450)
let descriptionMinHeight = hdpx(500)
let wndGap = hdpx(30)
let descriptionGap = hdpx(5)
let infoGap = hdpx(100)
let urlsGap = hdpx(30)
let buttonBlockWidth = defButtonMinWidth
let groupWidthInc = buttonBlockWidth / 2
let iconSize = [buttonBlockWidth, (buttonBlockWidth / 1.4).tointeger()]
let headerIconSize = [evenPx(100), (evenPx(100) / 1.4).tointeger()]
let descriptionWidth = wndWidth - buttonBlockWidth - 2 * wndGap
let swIconSz = hdpxi(70)

let groupBySubs = subsGroups.reduce(function(res, list, groupId) {
    foreach (s in list)
      res[s] <- groupId
    return res
  },
  {})

let subscription = Computed(@() allSubs.get()?[openedSubsId.get()])
let isSubsActive = Computed(@() (subscriptions.get()?[openedSubsId.get()].isActive ?? false)
  || openedSubsId.get() in activeInternalSubs.get())
let isOpened = keepref(Computed(@() subscription.get() != null))

let subsGroup = Computed(function() {
  let id = openedSubsId.get()
  if (id == null)
    return []
  return (subsGroups?[groupBySubs?[openedSubsId.get()]] ?? [id])
    .filter(@(s) s in allSubs.get())
})
let premiumBonusesCfg = Computed(function() {
  let prem = (serverConfigs.get()?.gameProfile.premiumBonuses ?? {})
    .__merge({noSub = {maxSavedPreset = serverConfigs.get()?.gameProfile.maxSavedPreset ?? 0}})
  if(openedSubsId.get() == "premium")
    return prem
  let premNew = prem
  foreach (k, v in serverConfigs.get()?.gameProfile.vipBonuses ?? {})
    if(premNew?[k])
      premNew[k] <- v
  return premNew
})
let vipBonusesCfg = Computed(@() (serverConfigs.get()?.gameProfile.vipBonuses ?? {})
  .__merge({noSub = {maxSavedPreset = serverConfigs.get()?.gameProfile.maxSavedPreset ?? 0}}))

let mkBonusRows = @(rowsCfg, cfgWatch) @() {
  watch = cfgWatch
  size = [descriptionWidth, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = descriptionGap
  children = rowsCfg.map(@(a) mkBonusRow(a, cfgWatch.get()))
}

let bonusInfoCtors = {
  premium = mkBonusRows(premiumRowsCfg, premiumBonusesCfg)
  vip = mkBonusRows(vipRowsCfg, vipBonusesCfg)
}

let bonusInfoBySubs = {
  vip = ["vip", "premium"]
}

let getInfoList = @(subs) bonusInfoBySubs?[subs] ?? [subs]

function description() {
  if (subsGroup.get().len() == 0)
    return { watch = subsGroup }
  let heights = {}
  let positions = {}
  local maxHeight = 0
  foreach(s in subsGroup.get()) {
    local height = 0
    foreach(ctorId in getInfoList(s)) {
      if (ctorId not in heights) {
        heights[ctorId] <- calc_comp_size(bonusInfoCtors[ctorId])[1]
        positions[ctorId] <- {}
      }
      if (height > 0)
        height += descriptionGap
      positions[ctorId][s] <- height
      height += heights[ctorId]
    }
    maxHeight = max(maxHeight, height)
  }

  return {
    watch = subsGroup
    size = [descriptionWidth, maxHeight]
    children = positions
      .map(@(posBySubs, ctorId) function() {
        let posY = posBySubs?[openedSubsId.get()]
        return posY == null ? { watch = openedSubsId }
          : {
              watch = openedSubsId
              children = {
                key = ctorId
                children = bonusInfoCtors[ctorId]
                transform = { translate = [0, posY] }
                transitions = [{ prop = AnimProp.translate, duration = 0.2, easing = InOutQuad }]
                animations = wndSwitchAnim
              }
            }
      })
      .values()
  }
}

let spinnerBlockOvr = {
  size = [SIZE_TO_CONTENT, defButtonHeight]
  minWidth = defButtonMinWidth
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
}

function getNextFromList(list, cur) {
  let idx = (list.indexof(cur) ?? -1) + 1
  return list?[idx % list.len()]
}

let toggleSubsBtn = @(subs, subsList) mkCustomButton(
  {
    size = [swIconSz, swIconSz]
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#decor_change_icon.svg:{swIconSz}:{swIconSz}:P")
    keepAspect = true
  },
  @() openSubsPreview(getNextFromList(subsList, subs.id)),
  mergeStyles(COMMON, { ovr = { minWidth = defButtonHeight } }))

let btnRow = @(children) {
  size = [flex(), defButtonHeight]
  halign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = wndGap
  children
}

function mkPurchButton(subs, subsList, totalConvertAmount, currencyId, leftTimeLoc, subscriptionsV) {
  let activeIdx = subsList.findindex(@(s) (subscriptionsV?[s].isActive ?? false)
    || s in activeInternalSubs.get())
  let curIdx = subsList.indexof(subs.id)
  let text = activeIdx == null || curIdx == null ? loc("subscription/activate")
    : activeIdx < curIdx ? loc("subscription/upgrade")
    : loc("subscription/changePlan")
  let activateAction = @() activeIdx == null ? activatePlatfromSubscription(subs)
    : changeSubscription(subs.id, subsList[activeIdx])
  let attachSubscription = @(count) (count?.price ?? 0) <= 0 ? removeModalWindow(OLD_SUBSCRIPTION_WND_UID) : null
  return textButtonPurchase(utf8ToUpper(text), @() totalConvertAmount.get() <= 0 ? activateAction()
    : openMsgBox({
        uid = OLD_SUBSCRIPTION_WND_UID
        text = @() {
          key = totalConvertAmount
          watch = [totalConvertAmount, currencyId, leftTimeLoc]
          size = flex()
          flow = FLOW_VERTICAL
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          gap = hdpx(16)
          onAttach = @() totalConvertAmount.subscribe(attachSubscription)
          onDetach = @() totalConvertAmount.unsubscribe(attachSubscription)
          children = [
            {
              behavior = Behaviors.TextArea
              size = FLEX_H
              rendObj = ROBJ_TEXTAREA
              color = textColor
              text = loc("subscription/convertPremiumInfoTime", { time = colorize(userlogTextColor, leftTimeLoc.get()) })
              halign = ALIGN_CENTER
              valign = ALIGN_CENTER
            }.__update(fontSmall)
            {
              flow = FLOW_HORIZONTAL
              halign = ALIGN_CENTER
              valign = ALIGN_CENTER
              gap = hdpx(8)
              children = mkTextRow(
                loc("subscription/get"),
                @(v) {
                  rendObj = ROBJ_TEXT
                  color = textColor
                  text = v
                }.__update(fontSmall),
                { ["{amount}"] = mkCurrencyComp(totalConvertAmount.get(), currencyId.get()) } 
              )
            }
          ]
        }
        buttons = [
          { id = "cancel", isCancel = true }
          { id = "activate", styleId = "PURCHASE", isDefault = true, text, cb = activateAction }
        ]
    }))
}

function purchBlock(subs, isActive, subsList, totalConvertAmount, currencyId, leftTimeLoc) {
  let toggle = subsList.len() <= 1 ? null : toggleSubsBtn(subs, subsList)
  let isGroupActive = Computed(@() subsList.findindex(@(s) (subscriptions.get()?[s].isActive ?? false)
    || s in activeInternalSubs.get()))
  return @() {
    watch = [subscriptions, can_upgrade_subscription, isGroupActive]
    size = FLEX_H
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = isActive || (isGroupActive.get() && !can_upgrade_subscription.get())
      ? btnRow([
          toggle
          {
            size = [defButtonMinWidth, defButtonHeight]
            valign = ALIGN_CENTER
            halign = ALIGN_CENTER
            rendObj = ROBJ_TEXT
            text = loc(isActive ? "subscription/active" : "options/unavailable")
          }.__update(fontSmallAccentedShaded)
        ])
      : [
          {
            rendObj = ROBJ_TEXT
            color = textColor
            text = loc("pricePerTime",
              { price = subs.priceExt.priceText, time = getSubsPeriodString(subs) })
          }.__update(fontMedium)
          {
            rendObj = ROBJ_TEXT
            color = textColor
            text = loc("subscrition/autoRenewal")
          }.__update(fontTiny)
          { size = [flex(), smallGap] }
          btnRow([
            toggle
            mkSpinnerHideBlock(platformPurchaseInProgress,
              mkPurchButton(subs, subsList, totalConvertAmount, currencyId, leftTimeLoc, subscriptions.get()),
              spinnerBlockOvr)
          ])
        ]
  }
}

let urlOvr = {
  ovr = {
    color = 0xFF17C0FC
  }.__update(fontTinyAccented)
  childOvr = {
    color = 0xFF17C0FC
  }
}

let urls = {
  size = FLEX_H
  flow = FLOW_VERTICAL
  gap = urlsGap
  children = [
    urlText(loc("subscription/renewalAgreement"), TERMS_OF_SERVICE_URL, urlOvr)
    urlText(loc("subscription/EULA"), PRIVACY_POLICY_URL, urlOvr)
  ]
}

let subsIcons = @(list) function() {
  let children = []
  foreach(idx, subs in list) {
    let isCurrent = subs == openedSubsId.get()
    let child = {
      key = subs
      size = iconSize
      pos = [idx * iconSize[0] / 2, 0]
      rendObj = ROBJ_IMAGE
      image = Picture($"{getSubsPresentation(subs).image}:0:P")
      color = isCurrent ? 0xFFFFFFFF : 0x40404040
      keepAspect = true
      transform = { scale = isCurrent ? [1.0, 1.0] : [0.9, 0.9] }
      transitions = [
        { prop = AnimProp.color, duration = 0.3, easing = InOutQuad }
        { prop = AnimProp.scale, duration = 0.3, easing = InOutQuad }
      ]
    }
    if (isCurrent)
      children.append(child)
    else
      children.insert(0, child)
  }
  return {
    watch = openedSubsId
    size = [iconSize[0] * (list.len() + 1) / 2, iconSize[1]]
    hplace = ALIGN_CENTER
    behavior = list.len() <= 1 ? null : Behaviors.Button
    onClick = @() openSubsPreview(getNextFromList(list, openedSubsId.get()))
    children
  }
}

let infoBlock = @(hasConvertPremiumInfo) {
  size = FLEX_H
  minHeight = descriptionMinHeight
  flow = FLOW_VERTICAL
  gap = infoGap
  children = [
    description
    !hasConvertPremiumInfo ? null
      : {
          size = FLEX_H
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          color = textColor
          text = loc("subscription/convertPremiumInfo")
        }.__update(fontTinyAccented)
    urls
  ]
}

function mkWindow() {
  let leftTime = Computed(@() premiumEndsAt.get() - serverTime.get())
  let leftTimeLoc = Computed(@() secondsToHoursLoc((leftTime.get() / 60) * 60))
  let currencyId = Computed(@() platformSubs.get()?[subscription.get()?.id].premiumDayConvert.currencyId)
  let totalConvertAmount = Computed(@() (ceil(leftTime.get() / TIME_DAY_IN_SECONDS_F)
    * (platformSubs.get()?[subscription.get()?.id].premiumDayConvert.price ?? 0)).tointeger())
  return @() modalWndBg.__merge({
    watch = [subscription, subsGroup, isSubsActive, totalConvertAmount]
    size = [wndWidth + groupWidthInc * (subsGroup.get().len() - 1), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = subscription.get() == null ? null
      : [
          modalWndHeaderBg.__merge({
              flow = FLOW_HORIZONTAL
              gap = hdpx(20)
              children = [
                {size = flex()}
                {
                  size = headerIconSize
                  rendObj = ROBJ_IMAGE
                  image = Picture($"{getSubsPresentation(subscription.get().id).icon}:0:P")
                  keepAspect = true
                }
                {
                  rendObj = ROBJ_TEXT
                  text = getSubsName(subscription.get().id)
                }.__update(fontSmall)
                {size = flex()}
                closeWndBtn(closeSubsPreview)
              ]
            })
          {
            size = FLEX_H
            padding = wndGap
            flow = FLOW_HORIZONTAL
            gap = wndGap
            children = [
              infoBlock(totalConvertAmount.get() > 0)
              {
                size = [buttonBlockWidth + groupWidthInc * (subsGroup.get().len() - 1), flex()]
                flow = FLOW_VERTICAL
                halign = ALIGN_CENTER
                children = [
                  {size = flex()}
                  subsIcons(subsGroup.get())
                  {size = flex()}
                  purchBlock(subscription.get(), isSubsActive.get(), subsGroup.get(), totalConvertAmount, currencyId, leftTimeLoc)
                ]
              }
            ]
          }
        ]})
}

let mkSubscriptionWnd = @() bgShaded.__merge({
  key = WND_UID
  size = flex()
  padding = saBordersRv
  behavior = Behaviors.Button
  hotkeys = [[btnBEscUp, { action = closeSubsPreview }]]
  onClick = closeSubsPreview
  children = mkWindow()
})
let openImpl = @() addModalWindow(mkSubscriptionWnd())

if(isOpened.get())
  openImpl()
isOpened.subscribe(@(v) v ? openImpl() : removeModalWindow(WND_UID))

register_command(@() openSubsPreview("vip"), "ui.subs_wnd")
