from "%globalsDarg/darg_library.nut" import *
let { allow_subscriptions } = require("%appGlobals/permissions.nut")
let dailyCounter = require("%appGlobals/pServer/dailyCounter.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { registerHandler, skip_offer } = require("%appGlobals/pServer/pServerApi.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { activeOffer } = require("%rGui/shop/offerState.nut")
let { previewGoods, openSubsPreview } = require("%rGui/shop/goodsPreviewState.nut")
let { hasVip } = require("%rGui/state/profilePremium.nut")
let { mkCustomButton, mergeStyles } = require("%rGui/components/textButton.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { PRIMARY,COMMON, defButtonHeight } = require("%rGui/components/buttonStyles.nut")

let iconSize = (defButtonHeight * 0.7).tointeger()

let vipIconW = hdpxi(50)
let vipIconH = hdpxi(30)

let clock = "▩"

let ovrBtn = {
  minWidth = defButtonHeight
  hotkeys = ["^J:Y | Enter"]
}

let needShowSkipButton = Computed(@() allow_subscriptions.get() && activeOffer.get()?.id == previewGoods.get()?.id)

let leftSkipOfferCount = Computed(@() (serverConfigs.get()?.gameProfile.vipBonuses.offerSkips ?? 0)
  - (dailyCounter.get()?.offer_skip ?? 0))

registerHandler("onSkipOffer", function(res) {
  if(!activeOffer.get() && !res?.error)
    openMsgBox({
      text = loc("offer/skip/noOffers")
      buttons = [
        { id = "ok", styleId = "PRIMARY", isDefault = true }
      ]})
})

let onClickGenNewOffer = @() leftSkipOfferCount.get() < 1
  ? openMsgBox({
      text = loc("offer/skip/noOffersPerDay", { count = serverConfigs.get()?.gameProfile.vipBonuses.offerSkips ?? 0})
      buttons = [
        {
          id = "ok"
          styleId = "PRIMARY"
          isDefault = true
        }
      ]
  })
  : openMsgBox({
      text = loc("offer/genNewOffer", {count = leftSkipOfferCount.get()})
      buttons = [
        { id = "cancel", isCancel = true }
        {
          id = "apply"
          styleId = "PRIMARY"
          isDefault = true
          cb = @() skip_offer(curCampaign.get(), "onSkipOffer")
        }
      ]
})

let onClickNotVip = @() openMsgBox({
  text = loc("offer/skip/desc")
  buttons = [
    { id = "cancel", isCancel = true }
    {
      id = "view_subscription"
      styleId = "PRIMARY"
      isDefault = true
      cb = @() openSubsPreview("vip")
    }
  ]
})

let skipsEnded = {
  size = [ flex(), defButtonHeight]
  children = [
    {
      size = [iconSize, iconSize]
      rendObj = ROBJ_IMAGE
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      image = Picture($"ui/gameuiskin#icon_repeatable.svg:{iconSize}:{iconSize}:P")
      keepAspect = true
    }
    {
      pos = [hdpx(17), hdpx(0)]
      rendObj = ROBJ_TEXT
      text = clock
      halign = ALIGN_RIGHT
      valign = ALIGN_BOTTOM
    }.__update(fontSmall)
  ]
}

let contentVip = @(leftCount) leftCount < 1 ? skipsEnded : {
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    {
      size = [iconSize, iconSize]
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#icon_repeatable.svg:{iconSize}:{iconSize}:P")
      keepAspect = KEEP_ASPECT_FIT
    }
    @() {
      watch = serverConfigs
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = "/".concat(leftCount, serverConfigs.get()?.gameProfile.vipBonuses.offerSkips ?? 0)
    }.__update(fontSmall)
  ]
}

let contentCommon = @() {
  size = [ flex(), defButtonHeight]
  children = [
    {
      pos = [hdpx(5), hdpx(5)]
      size = [vipIconW, vipIconH]
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#vip_active.svg:{vipIconW}:{vipIconH}:P")
      keepAspect = KEEP_ASPECT_FIT
    }
    {
      size = [iconSize, iconSize]
      rendObj = ROBJ_IMAGE
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      image = Picture($"ui/gameuiskin#icon_repeatable.svg:{iconSize}:{iconSize}:P")
      keepAspect = KEEP_ASPECT_FIT
    }
  ]
}

let skipOfferBtn = @() {
  watch = [hasVip, needShowSkipButton, leftSkipOfferCount]
  vplace = ALIGN_BOTTOM
  children = !needShowSkipButton.get() ? null
    : !hasVip.get()
      ? mkCustomButton(contentCommon, onClickNotVip, mergeStyles(COMMON, { ovr = ovrBtn }))
    : mkCustomButton(contentVip(leftSkipOfferCount.get()), onClickGenNewOffer,
      mergeStyles(leftSkipOfferCount.get() < 1 ? COMMON : PRIMARY, { ovr = ovrBtn }))
  }

return skipOfferBtn