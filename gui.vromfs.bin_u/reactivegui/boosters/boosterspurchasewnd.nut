from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/config/boostersPresentation.nut" import getBoosterIcon
from "%appGlobals/pServer/campaign.nut" import campConfigs
from "%appGlobals/pServer/pServerApi.nut" import boosterInProgress, toggle_booster_activation
import "%appGlobals/pServer/servProfile.nut" as servProfile
import "%rGui/boosters/boosterDesc.nut" as boosterDesc
from "%rGui/boosters/boostersState.nut" import isOpenedBoosterWnd
import "%rGui/boosters/purchaseBooster.nut" as purchaseBooster
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/currencyComp.nut" import mkCurrencyComp
from "%rGui/components/gradientDefComps.nut" import headerGradientWithRightBlock
from "%rGui/components/infoButton.nut" import infoCommonButton
from "%rGui/components/spinner.nut" import mkWaitDimmingSpinner
from "%rGui/components/textButton.nut" import textButtonPricePurchase
from "%rGui/mainMenu/gamercard.nut" import gamercardBalanceBtns
from "%rGui/navState.nut" import registerScene
from "%rGui/shop/bqPurchaseInfo.nut" import PURCH_SRC_BOOSTERS, PURCH_TYPE_BOOSTERS, mkBqPurchaseInfo
from "%rGui/shop/goodsView/sharedParts.nut" import mkBgParticles, tinyLimitReachedPlate
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/gradients.nut" import mkColoredGradientY, simpleHorGrad
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/style/stdColors.nut" import hoverColor, warningTextColor


let close = @() isOpenedBoosterWnd.set(false)

const cardWidth = hdpxi(370)
const cardPadding = hdpx(10)
const checkBoxIconSize = hdpxi(72)
const bgSize = [cardWidth, hdpxi(412)]
const boosterSize = hdpxi(230)
const infoBtnSize = evenPx(60)
const cardHeaderMaxHeight = evenPx(90)
const titleWidth = cardWidth - infoBtnSize - cardPadding * 2 - hdpx(16)

let priceBgGrad = mkColoredGradientY(0xFF72A0D0, 0xFF588090, 12)

let animTrigger = @(bstId) $"changeBoosterNumber_${bstId}"

let bgHiglight = {
  size = FLEX
  rendObj = ROBJ_SOLID
  color = 0xFFEDE4C7
}

let header = {
  rendObj = ROBJ_TEXT
  hplace = ALIGN_CENTER
  text = utf8ToUpper(loc("boosters/header"))
}.__update(fontMedium)

let footer = {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  text = loc("boosters/footer")
}.__update(fontTinyShaded)

function mkPricePlate(bst, count) {
  let isDelayed = Computed(@() boosterInProgress.get() != null)
  let { limit = 0 } = bst
  return @() {
    watch = isDelayed
    size = const [FLEX, hdpx(90)]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = priceBgGrad
    picSaturate = isDelayed.get() ? 0 : 1.0
    children = limit > 0 && limit <= count ? tinyLimitReachedPlate
      : bst.price > 0
        ? textButtonPricePurchase(null,
            mkCurrencyComp(bst.price, bst.currencyId),
            @() null,
            { ovr = { size = FLEX, minWidth = 0, behavior = null } })
      : null
    transitions = [{ prop = AnimProp.picSaturate, duration = 1.0, easing = InQuad }]
  }
}

let gamercardPannel = headerGradientWithRightBlock(
  [
    backButton(close)
    header
  ],
  gamercardBalanceBtns)

let infoBtn = @(id) infoCommonButton(
  @() boosterDesc(id),
  {
    size = [infoBtnSize, infoBtnSize]
    hplace = ALIGN_LEFT
  }
)

let cardTitle = @(id) {
  size = [titleWidth, SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_LEFT
  padding = hdpx(30)
  text = utf8ToUpper(loc($"boosters/{id}"))
}.__update(fontVeryTinyAccentedShaded)

let cardHeader = memoize(function(id) {
  let title = cardTitle(id)
  if (calc_content_size(title)[1] > cardHeaderMaxHeight)
    title.__update(fontVeryVeryTinyAccentedShaded)

  return {
    size = FLEX_H
    padding = cardPadding
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = hdpx(16)
    children = [
      infoBtn(id)
      {
        size = FLEX_H
        maxHeight = cardHeaderMaxHeight
        children = title
      }
    ]
  }
})

let boosterSlot = @(bst, count, sf) {
  rendObj = ROBJ_SOLID
  color = 0xFF645858
  borderColor = 0x40FFFFFF
  borderWidth = hdpx(2)
  padding = hdpx(2)
  children = [
    sf & S_HOVER ? bgHiglight : null
    mkBgParticles(bgSize)
    {
      rendObj = ROBJ_IMAGE
      size = bgSize
      image = Picture($"ui/gameuiskin/shop_bg_slot.avif:{bgSize[0]}:{bgSize[1]}:P")
    }
    {
      size = FLEX
      flow = FLOW_VERTICAL
      children = [
        cardHeader(bst.id)
        {
          size = FLEX
          valign = ALIGN_CENTER
          gap = hdpx(20)
          children = [
            {
              size = const [boosterSize, boosterSize]
              rendObj = ROBJ_IMAGE
              hplace = ALIGN_CENTER
              image = Picture($"{getBoosterIcon(bst.id)}:{boosterSize}:{boosterSize}:P")
            }
            {
              size = const [SIZE_TO_CONTENT, boosterSize]
              hplace = ALIGN_RIGHT
              pos = const [-hdpx(20), -hdpx(12)]
              rendObj = ROBJ_TEXT
              text = bst.battles.tostring().replace("0", "O")
              color = 0xFFC0C0C0
            }.__update(fontWtBig)
          ]
        }
        {
          size = FLEX_H
          rendObj = ROBJ_IMAGE
          flipX = true
          flow = FLOW_VERTICAL
          image = simpleHorGrad
          color = 0x80000000
          padding = cardPadding
          children = {
            size = const [FLEX, SIZE_TO_CONTENT]
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            color = (bst?.limit ?? 0) <= 0 || bst.limit > count ? 0xFFFFFFFF
              : warningTextColor
            text = utf8ToUpper((bst?.limit ?? 0) <= 0 ? loc("item/balance", {count})
              : loc("item/balanceWithLimit", {count, limit = bst.limit}))
            transform = { pivot = [0, 0.5] }
            animations = [{
              prop = AnimProp.scale, from = [1,1], to = [1.3, 1.3],
              duration = 1, trigger = animTrigger(bst.id), easing = DoubleBlink
            }]
          }.__update(fontVeryTinyAccentedShaded)
        }
      ]
    }
  ]
}

let textBase = @(battlesLeft) {
  rendObj = ROBJ_TEXT
  size = FLEX_H
  padding = const [0, cardPadding]
  halign = ALIGN_CENTER
  behavior = Behaviors.Marquee
  delay = defMarqueeDelay
  hplace = ALIGN_CENTER
  opacity = battlesLeft <= 0 ? 0.5 : 1
}.__update(fontTinyAccentedShaded)

let battlesLeftTitle = @(sf, battlesLeft, isDisabled) {
  size = FLEX_H
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
  clipChildren = true
  children = textBase(battlesLeft).__merge({
      text = isDisabled || battlesLeft <= 0 ? loc("booster/use") : loc("booster/using")
      color = battlesLeft > 0 && (sf & S_HOVER) ? hoverColor : null
    })
}

function boosterCard(bst) {
  let stateFlags = Watched(0)
  let cbStateFlags = Watched(0)
  let isDisabled = Computed(@() servProfile.get()?.boosters[bst.id].isDisabled ?? false)
  let battlesLeft = Computed(@() servProfile.get()?.boosters[bst.id].battlesLeft ?? 0)
  let hasSpinner = Computed(@() boosterInProgress.get() == bst.id)
  let { limit = 0 } = bst
  battlesLeft.subscribe(@(_) anim_start(animTrigger(bst.id)))
  return {
    flow = FLOW_VERTICAL
    children = [
      @() {
        watch = [stateFlags, battlesLeft]
        behavior = Behaviors.Button
        flow = FLOW_VERTICAL
        sound = { click  = "click" }
        transform = { scale = battlesLeft.get() > 0 && (stateFlags.get() & S_ACTIVE) ? [0.95, 0.95] : [1, 1] }
        onElemState = @(sf) stateFlags.set(sf)
        onClick = @() (limit > 0 && limit <= battlesLeft.get()) ? null
          : purchaseBooster(bst.id, loc($"boosters/{bst.id}"),
              mkBqPurchaseInfo(PURCH_SRC_BOOSTERS, PURCH_TYPE_BOOSTERS, bst.id))
        gap = -hdpx(2)
        children = [
          {
            children = [
              boosterSlot(bst, battlesLeft.get(), stateFlags.get())
              mkWaitDimmingSpinner(hasSpinner)
            ]
          }
          mkPricePlate(bst, battlesLeft.get())
        ]
      }
      @() {
        watch = [cbStateFlags, battlesLeft, isDisabled, hasSpinner]
        behavior = Behaviors.Button
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        margin = const [hdpx(20), 0, 0, 0]
        transform = {
          scale = battlesLeft.get() > 0 && (cbStateFlags.get() & S_ACTIVE) ? [0.95, 0.95] : [1, 1]
        }
        onElemState = @(sf) cbStateFlags.set(sf)
        onClick = @() battlesLeft.get() <= 0 || hasSpinner.get() ? null
          : toggle_booster_activation(bst.id, !isDisabled.get())
        children = [
          {
            size = array(2, hdpx(80))
            rendObj = ROBJ_BOX
            opacity = isDisabled.get() || battlesLeft.get() <= 0 ? 0.5 : 1.0
            borderColor = battlesLeft.get() > 0 && (cbStateFlags.get() & S_HOVER) ? hoverColor : 0xFF9FA7AF
            borderWidth = hdpx(3)
            fillColor = 0x88000000
            padding = hasSpinner.get() ? null : [0,0, cardPadding, cardPadding]
            valign = ALIGN_CENTER
            halign = ALIGN_CENTER
            children = hasSpinner.get() ? mkWaitDimmingSpinner(hasSpinner, hdpxi(50))
              : {
                  size = array(2, checkBoxIconSize)
                  rendObj = ROBJ_IMAGE
                  image = isDisabled.get() || battlesLeft.get() <= 0 ? null
                    : Picture($"ui/gameuiskin#daily_mark_claimed.avif:{checkBoxIconSize}:{checkBoxIconSize}:P")
                  keepAspect = KEEP_ASPECT_FIT
                  color = 0xFFFFFFFF
                }
          }
          battlesLeftTitle(cbStateFlags.get(), battlesLeft.get(), isDisabled.get())
        ]
      }
    ]
  }
}

let goods = @() {
  watch = campConfigs
  flow = FLOW_HORIZONTAL
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  gap = hdpx(50)
  children = campConfigs.get()?.allBoosters
    .map(@(b, id) b.__merge({ id }))
    .values()
    .sort(@(a, b) a.id <=> b.id)
    .map(@(bst) boosterCard(bst))
}

let content = {
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = hdpx(30)
  children = [
    goods
    footer
  ]
}

let window = bgShaded.__merge({
  size = FLEX
  padding = saBordersRv
  children = [
    gamercardPannel
    content
  ]
  animations = wndSwitchAnim
})

registerScene("boostersWnd", window, close, isOpenedBoosterWnd)