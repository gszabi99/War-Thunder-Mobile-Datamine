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
let { mkColoredGradientY } = require("%rGui/style/gradients.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let boosterDesc = require("%rGui/boosters/boosterDesc.nut")
let { PURCH_SRC_BOOSTERS, PURCH_TYPE_BOOSTERS, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let purchaseBooster = require("%rGui/boosters/purchaseBooster.nut")
let { mkWaitDimmingSpinner } = require("%rGui/components/spinner.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { boosterInProgress, toggle_booster_activation } = require("%appGlobals/pServer/pServerApi.nut")
let { hoverColor } = require("%rGui/style/stdColors.nut")
let { textButtonPricePurchase } = require("%rGui/components/textButton.nut")
let { mkBgParticles } = require("%rGui/shop/goodsView/sharedParts.nut")

let close = @() isOpenedBoosterWnd.set(false)

let checkBoxIconSize = hdpxi(72)
let bgSize = [hdpxi(370), hdpxi(412)]
let boosterSize = hdpxi(230)

let priceBgGrad = mkColoredGradientY(0xFF72A0D0, 0xFF588090, 12)

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
}.__update(fontTiny)

function mkPricePlate(bst) {
  let isDelayed = Computed(@() boosterInProgress.get() != null)
  return @() {
    watch = isDelayed
    size = const [flex(), hdpx(90)]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = priceBgGrad
    picSaturate = isDelayed.get() ? 0 : 1.0
    children = bst.price > 0
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
    margin = const [hdpx(12), hdpx(16)]
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
}.__update(fontVeryTinyAccented)

let cardHeader = @(id) {
  size = FLEX_H
  padding = hdpx(10)
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    infoBtn(id)
    {
      size = FLEX_H
      maxHeight = evenPx(60)
      children = cardTitle(id)
    }
  ]
}

let boosterSlot = @(bst, sf) {
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
      padding = const [0, 0, hdpx(20), 0]
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
}.__update(fontTinyAccented)

let animTrigger = @(bstId) $"changeBoosterNumber_${bstId}"
let battlesLeftTitle = @(bst, sf, battlesLeft, isDisabled) {
  size = FLEX_H
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
  clipChildren = true
  children = [
    textBase(battlesLeft).__merge({
      text = isDisabled || battlesLeft <= 0 ? loc("booster/use") : loc("booster/using")
      color = battlesLeft > 0 && (sf & S_HOVER) ? hoverColor : null
    })
    textBase(battlesLeft).__merge({
      text = loc("booster/battlesLeft", { battlesLeft })
      color = battlesLeft > 0 && (sf & S_HOVER) ? hoverColor : null
      transform = {}
      animations = [{
        prop = AnimProp.scale, from = [1,1], to = [1.7, 1.7],
        duration = 1, trigger = animTrigger(bst.id), easing = DoubleBlink
      }]
    })
  ]
}

let function boosterCard(bst) {
  let stateFlags = Watched(0)
  let cbStateFlags = Watched(0)
  let isDisabled = Computed(@() servProfile.get()?.boosters[bst.id].isDisabled ?? false)
  let battlesLeft = Computed(@() servProfile.get()?.boosters[bst.id].battlesLeft ?? 0)
  let hasSpinner = Computed(@() boosterInProgress.get() == bst.id)
  battlesLeft.subscribe(@(_) anim_start(animTrigger(bst.id)))
  return {
    flow = FLOW_VERTICAL
    children = [
      @() {
        watch = stateFlags
        behavior = Behaviors.Button
        flow = FLOW_VERTICAL
        sound = { click  = "click" }
        transform = { scale = battlesLeft.get() > 0 && (stateFlags.get() & S_ACTIVE) ? [0.95, 0.95] : [1, 1] }
        onElemState = @(sf) stateFlags.set(sf)
        onClick = @() purchaseBooster(bst.id, loc($"boosters/{bst.id}"),
          mkBqPurchaseInfo(PURCH_SRC_BOOSTERS, PURCH_TYPE_BOOSTERS, bst.id))
        gap = -hdpx(2)
        children = [
          {
            children = [
              boosterSlot(bst, stateFlags.get())
              mkWaitDimmingSpinner(hasSpinner)
            ]
          }
          mkPricePlate(bst)
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
          battlesLeftTitle(bst, cbStateFlags.get(), battlesLeft.get(), isDisabled.get())
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

registerScene("bstWnd", window, close, isOpenedBoosterWnd)