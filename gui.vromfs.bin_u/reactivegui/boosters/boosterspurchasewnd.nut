from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { getBoosterIcon } = require("%appGlobals/config/boostersPresentation.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { registerScene } = require("%rGui/navState.nut")
let { isOpenedBoosterWnd } = require("%rGui/boosters/boostersState.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { gamercardBalanceBtns } = require("%rGui/mainMenu/gamercard.nut")
let { infoCommonButton } = require("%rGui/components/infoButton.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { mkColoredGradientY, simpleHorGrad } = require("%rGui/style/gradients.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let boosterDesc = require("%rGui/boosters/boosterDesc.nut")
let { PURCH_SRC_BOOSTERS, PURCH_TYPE_BOOSTERS, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let purchaseBooster = require("%rGui/boosters/purchaseBooster.nut")
let { mkWaitDimmingSpinner } = require("%rGui/components/spinner.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { boosterInProgress, toggle_booster_activation } = require("%appGlobals/pServer/pServerApi.nut")
let { hoverColor, warningTextColor } = require("%rGui/style/stdColors.nut")
let { textButtonPricePurchase } = require("%rGui/components/textButton.nut")
let { mkBgParticles, tinyLimitReachedPlate } = require("%rGui/shop/goodsView/sharedParts.nut")

let close = @() isOpenedBoosterWnd.set(false)

let checkBoxIconSize = hdpxi(72)
let bgSize = [hdpxi(370), hdpxi(412)]
let boosterSize = hdpxi(230)

let priceBgGrad = mkColoredGradientY(0xFF72A0D0, 0xFF588090, 12)

let animTrigger = @(bstId) $"changeBoosterNumber_${bstId}"

let bgHiglight = {
  size = flex()
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
    size = const [flex(), hdpx(90)]
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
            { ovr = { size = flex(), minWidth = 0, behavior = null } })
      : null
    transitions = [{ prop = AnimProp.picSaturate, duration = 1.0, easing = InQuad }]
  }
}

let gamercardPannel = {
  size = [flex(), gamercardHeight]
  vplace = ALIGN_TOP
  children = [
    backButton(close)
    gamercardBalanceBtns
  ]
}

let infoBtn = @(id) infoCommonButton(
  @() boosterDesc(id),
  {
    size = [evenPx(60), evenPx(60)]
    hplace = ALIGN_LEFT
  }
)

let cardTitle = @(id) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_LEFT
  padding = hdpx(30)
  text = utf8ToUpper(loc($"boosters/{id}"))
}.__update(fontVeryTinyAccentedShaded)

let cardHeader = @(id) {
  size = FLEX_H
  padding = hdpx(10)
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(16)
  children = [
    infoBtn(id)
    {
      size = FLEX_H
      maxHeight = evenPx(60)
      children = cardTitle(id)
    }
  ]
}

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
      size = flex()
      flow = FLOW_VERTICAL
      children = [
        cardHeader(bst.id)
        {
          size = flex()
          valign = ALIGN_CENTER
          gap = hdpx(20)
          children = [
            {
              size = [boosterSize, boosterSize]
              rendObj = ROBJ_IMAGE
              hplace = ALIGN_CENTER
              image = Picture($"{getBoosterIcon(bst.id)}:{boosterSize}:{boosterSize}:P")
            }
            {
              size = [SIZE_TO_CONTENT, boosterSize]
              hplace = ALIGN_RIGHT
              pos = [-hdpx(20), -hdpx(12)]
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
          padding = hdpx(10)
          children = {
            size = [flex(), SIZE_TO_CONTENT]
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
  padding = [0, hdpx(10)]
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

let function boosterCard(bst) {
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
            padding = hasSpinner.get() ? null : [0,0,hdpx(10),hdpx(10)]
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
    header
    goods
    footer
  ]
}

let window = bgShaded.__merge({
  size = flex()
  padding = saBordersRv
  children = [
    gamercardPannel
    content
  ]
  animations = wndSwitchAnim
})

registerScene("boostersWnd", window, close, isOpenedBoosterWnd)