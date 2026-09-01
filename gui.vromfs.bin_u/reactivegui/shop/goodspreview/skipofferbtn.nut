from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/subsPresentation.nut" import mkSubsIcon
from "%appGlobals/pServer/campaign.nut" import curCampaign
import "%appGlobals/pServer/dailyCounter.nut" as dailyCounter
from "%appGlobals/pServer/pServerApi.nut" import registerHandler, skip_offer, get_skip_offer_availability,
  skipOfferInProgress
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/permissions.nut" import allow_subscriptions
from "%rGui/components/buttonStyles.nut" import PRIMARY, COMMON, defButtonHeight
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/components/spinner.nut" import spinner
from "%rGui/components/textButton.nut" import mkCustomButton, mergeStyles
from "%rGui/shop/goodsPreviewState.nut" import previewGoods, openSubsPreview
from "%rGui/shop/offerState.nut" import activeOffer
from "%rGui/state/profilePremium.nut" import hasVip


let iconSize = 2 * (defButtonHeight * 0.25).tointeger()
let iconSizeBig = 2 * (defButtonHeight * 0.3).tointeger()

const vipIconH = hdpxi(40)

const clock = "▩"

let ovrBtn = {
  minWidth = defButtonHeight
  hotkeys = ["^J:Y | Enter"]
}

let isAttached = Watched(false)
let hasMoreOffer = Watched(false)
let isMoreOfferActual = Watched(false)

let needShowSkipButton = Computed(@() allow_subscriptions.get() && activeOffer.get()?.id == previewGoods.get()?.id)

let leftSkipOfferCount = Computed(@() (serverConfigs.get()?.gameProfile.vipBonuses.offerSkips ?? 0)
  - (dailyCounter.get()?.offer_skip ?? 0))

let canUpdateMoreOffer = keepref(Computed(@() needShowSkipButton.get()
  && hasVip.get()
  && leftSkipOfferCount.get() > 0
  && isAttached.get()
  && !isMoreOfferActual.get()
  && !skipOfferInProgress.get()))

let onClickGenNewOffer = @() openMsgBox({
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

let onClickNotActive = @() openMsgBox({ text = !hasMoreOffer.get()
  ? loc("offer/skip/noOffers")
  : loc("offer/skip/noOffersPerDay", { count = serverConfigs.get()?.gameProfile.vipBonuses.offerSkips ?? 0})
})

let onClickNotVip = @() openMsgBox({
  text = loc("offer/skip/desc")
  buttons = [
    { id = "cancel", isCancel = true }
    {
      id = "view_subscription"
      styleId = "PRIMARY"
      isDefault = true
      cb = @() openSubsPreview("vip", "offer_skip")
    }
  ]
})

servProfile.subscribe(@(_) isMoreOfferActual.set(false))
serverConfigs.subscribe(@(_) isMoreOfferActual.set(false))
curCampaign.subscribe(@(_) isMoreOfferActual.set(false))
canUpdateMoreOffer.subscribe(@(v) !v ? null
  : get_skip_offer_availability(curCampaign.get(), "onGetSkipOfferAvailability"))

registerHandler("onSkipOffer", @(res) (activeOffer.get() || res?.error) ? null
  : openMsgBox({ text = loc("offer/skip/noOffers") }))
registerHandler("onGetSkipOfferAvailability", function(res) {
  if (res?.error)
    return
  isMoreOfferActual.set(true)
  hasMoreOffer.set(res?.hasMoreOffer ?? false)
})

let skipsEnded = {
  size = [FLEX, defButtonHeight]
  children = [
    {
      size = [iconSizeBig, iconSizeBig]
      rendObj = ROBJ_IMAGE
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      image = Picture($"ui/gameuiskin#icon_repeatable.svg:{iconSizeBig}:{iconSizeBig}:P")
      keepAspect = true
    }
    {
      pos = const [hdpx(17), hdpx(0)]
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
  gap = hdpx(-4)
  children = [
    {
      size = [iconSizeBig, iconSizeBig]
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#icon_repeatable.svg:{iconSizeBig}:{iconSizeBig}:P")
      keepAspect = KEEP_ASPECT_FIT
    }
    @() {
      watch = serverConfigs
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = "/".concat(leftCount, serverConfigs.get()?.gameProfile.vipBonuses.offerSkips ?? 0)
    }.__update(fontSmallShaded)
  ]
}

let contentCommon = @() {
  size = [FLEX, defButtonHeight]
  children = [
    {
      pos = const [-hdpx(25), 0]
      children = mkSubsIcon("vip", vipIconH)
    }
    {
      size = [iconSize, iconSize]
      pos = const [hdpx(10), -hdpx(8)]
      rendObj = ROBJ_IMAGE
      hplace = ALIGN_RIGHT
      vplace = ALIGN_BOTTOM
      image = Picture($"ui/gameuiskin#icon_repeatable.svg:{iconSize}:{iconSize}:P")
      keepAspect = KEEP_ASPECT_FIT
    }
  ]
}

let skipOfferBtn = @() {
  watch = [hasVip, needShowSkipButton, leftSkipOfferCount, skipOfferInProgress, hasMoreOffer]
  key = isAttached
  vplace = ALIGN_BOTTOM
  onAttach = @() isAttached.set(true)
  onDetach = @() isAttached.set(false)
  children = !needShowSkipButton.get() ? null
    : !hasVip.get() ? mkCustomButton(contentCommon, onClickNotVip, mergeStyles(COMMON, { ovr = ovrBtn }))
    : skipOfferInProgress.get()
      ? {
          size = defButtonHeight
          minWidth = defButtonHeight
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          children = spinner
        }
    : leftSkipOfferCount.get() < 1 || !hasMoreOffer.get()
      ? mkCustomButton(contentVip(leftSkipOfferCount.get()), onClickNotActive, mergeStyles(COMMON, { ovr = ovrBtn }))
    : mkCustomButton(contentVip(leftSkipOfferCount.get()), onClickGenNewOffer, mergeStyles(PRIMARY, { ovr = ovrBtn }))
  }

return skipOfferBtn