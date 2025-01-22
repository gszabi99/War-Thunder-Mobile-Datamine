from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { subscriptions } = require("%appGlobals/pServer/campaign.nut")
let { PRIVACY_POLICY_URL } = require("%appGlobals/legal.nut")
let { getSubsPresentation, getSubsName } = require("%appGlobals/config/subsPresentation.nut")
let { formatText } = require("%rGui/news/textFormatters.nut")
let { openedSubsId, closeSubsPreview } = require("%rGui/shop/goodsPreviewState.nut")
let { allSubs } = require("%rGui/shop/shopState.nut")
let { activatePlatfromSubscription, platformPurchaseInProgress } = require("%rGui/shop/platformGoods.nut")
let { getSubsPeriodString } = require("%rGui/shop/shopCommon.nut")

let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { modalWndBg, modalWndHeaderWithClose } = require("%rGui/components/modalWnd.nut")
let { textButtonPurchase } = require("%rGui/components/textButton.nut")
let { defButtonMinWidth, defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")


let WND_UID = "subscription_wnd"

let wndWidth = hdpx(1200)
let descriptionMinHeight = hdpx(500)
let wndGapY = hdpx(30)
let wndGapX = hdpx(50)
let smallGap = hdpx(20)
let bonusValueWidth = hdpx(60)
let descriptionGap = hdpx(10)
let urlsGap = hdpx(30)
let urlsButtomPadding = hdpx(100)
let buttonBlockWidth = defButtonMinWidth
let iconSize = [buttonBlockWidth, (buttonBlockWidth / 1.4).tointeger()]
let bonusIconSize = hdpx(40)
let textColor = 0xFFE0E0E0

let subscription = Computed(@() allSubs.get()?[openedSubsId.get()])
let isSubsActive = Computed(@() subscriptions.get()?[openedSubsId.get()].isActive ?? false)
let isOpened = keepref(Computed(@() subscription.get() != null))
let premiumBonusesCfg = Computed(@() serverConfigs.get()?.gameProfile.premiumBonuses)

let bonusMultText = @(v) $"{v}x"

let advantages = [
  {
    name = "bonusPlayerExp"
    bonus = @(cfg) bonusMultText(cfg?.expMul || 1.0)
    icon = mkCurrencyImage("playerExp", bonusIconSize, { vplace = ALIGN_TOP })
  }
  {
    name = "bonusUnitExp"
    bonus = @(cfg) bonusMultText(cfg?.expMul || 1.0)
    icon = mkCurrencyImage("unitExp", bonusIconSize, { vplace = ALIGN_TOP })
  }
  {
    name = "bonusWp"
    bonus = @(cfg) bonusMultText(cfg?.wpMul || 1.0)
    icon = mkCurrencyImage("wp", bonusIconSize, { vplace = ALIGN_TOP })
  }
  {
    name = "bonusGold"
    bonus = @(cfg) bonusMultText(cfg?.goldMul || 1.0)
    icon = mkCurrencyImage("gold", bonusIconSize, { vplace = ALIGN_TOP })
  }
]

let mkPremiumAdvString = @(bonus, cfg) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = smallGap
  children = [
    {
      size = [ bonusValueWidth, flex()]
      rendObj = ROBJ_TEXT
      color = textColor
      text = bonus.bonus(cfg)
    }.__update(fontSmall)
    bonus.icon
    {
      size = [ flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      color = textColor
      text = loc($"subscription/advantage/{bonus.name}")
    }.__update(fontSmall)
  ]
}

let spinnerBlockOvr = {
  size = [SIZE_TO_CONTENT, defButtonHeight]
  minWidth = defButtonMinWidth
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
}

let purchBlock = @(subs, isActive) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = isActive
    ? {
        rendObj = ROBJ_TEXT
        text = loc("subscription/active")
      }.__update(fontSmallAccentedShaded)
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
        mkSpinnerHideBlock(platformPurchaseInProgress,
          textButtonPurchase(utf8ToUpper(loc("subscription/activate")), @() activatePlatfromSubscription(subs)),
          spinnerBlockOvr)
      ]
}

let description = @() {
  watch = premiumBonusesCfg
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = descriptionGap
  children = premiumBonusesCfg.get() == null
    ? null
    : advantages.map(@(a) mkPremiumAdvString(a, premiumBonusesCfg.get()))
}

let urls = @() {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = urlsGap
  children = [
    formatText({
      t = "url"
      url = PRIVACY_POLICY_URL
      v = loc("subscription/renewalAgreement")
    })
    formatText({
      t = "url"
      url = PRIVACY_POLICY_URL // TODO: change for EULA url
      v = loc("subscription/EULA")
    })
  ]
}

let subsIcon = @() {
  watch = openedSubsId
  size = iconSize
  rendObj = ROBJ_IMAGE
  image = Picture($"{getSubsPresentation(openedSubsId.get()).icon}:0:P")
  keepAspect = KEEP_ASPECT_FIT
}

let window = @() modalWndBg.__merge({
  watch = [subscription, isSubsActive]
  size = [wndWidth, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = subscription.get() == null ? null
    : [
        modalWndHeaderWithClose(getSubsName(subscription.get().id), closeSubsPreview)
        {
          size = [flex(), SIZE_TO_CONTENT]
          padding = [wndGapY, wndGapX]
          flow = FLOW_HORIZONTAL
          gap = wndGapY
          children = [
            {
              size = [flex(), SIZE_TO_CONTENT]
              minHeight = descriptionMinHeight
              flow = FLOW_VERTICAL
              gap = descriptionGap
              children = [
                description
                {size = flex()}
                urls
                {size = [flex(), urlsButtomPadding]}
              ]
            }
            {
              size = [buttonBlockWidth, flex()]
              flow = FLOW_VERTICAL
              halign = ALIGN_CENTER
              children = [
                subsIcon
                {size = flex()}
                purchBlock(subscription.get(), isSubsActive.get())
              ]
            }
          ]
        }
      ]
})

let subscriptionWnd = bgShaded.__merge({
  key = WND_UID
  size = flex()
  padding = saBordersRv
  behavior = Behaviors.Button
  hotkeys = [[btnBEscUp, { action = closeSubsPreview }]]
  onClick = closeSubsPreview
  children = window
})
let openImpl = @() addModalWindow(subscriptionWnd)

if(isOpened.get())
  openImpl()
isOpened.subscribe(@(v) v ? openImpl() : removeModalWindow(WND_UID))
