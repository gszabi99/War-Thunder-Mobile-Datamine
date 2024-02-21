from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { getBoosterIcon } = require("%appGlobals/config/boostersPresentation.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { registerScene } = require("%rGui/navState.nut")
let { isOpenedBoosterWnd } = require("boostersState.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { gamercardBalanceBtns } = require("%rGui/mainMenu/gamercard.nut")
let { infoGreyButton } = require("%rGui/components/infoButton.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { mkColoredGradientY } = require("%rGui/style/gradients.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let boosterDesc = require("boosterDesc.nut")
let { PURCH_SRC_BOOSTERS, PURCH_TYPE_BOOSTERS, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let purchaseBooster = require("purchaseBooster.nut")
let { boosterInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")

let close = @() isOpenedBoosterWnd(false)

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
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  text = loc("boosters/footer")
}.__update(fontTiny)

let mkPricePlate = @(bst) {
  size = [flex(), hdpx(90)]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = priceBgGrad
  children = bst.price > 0
    ? mkSpinnerHideBlock(Computed(@() boosterInProgress.value != null),
        boosterInProgress.value == null ? mkCurrencyComp(bst.price, bst.currencyId) : null)
    : null
}

let gamercardPannel = {
  size = [flex(), gamercardHeight]
  vplace = ALIGN_TOP
  children = [
    backButton(close)
    gamercardBalanceBtns
  ]
}

let infoBtn = @(id) infoGreyButton(
  @() boosterDesc(id),
  {
    size = [evenPx(60), evenPx(60)]
    margin = [hdpx(12), hdpx(16)]
    hplace = ALIGN_LEFT
  }
)

let cardTitle = @(id) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_LEFT
  padding = hdpx(30)
  text = utf8ToUpper(loc($"boosters/{id}"))
}.__update(fontVeryTinyAccented)

let cardHeader = @(id) {
  size = [flex(), SIZE_TO_CONTENT]
  padding = hdpx(10)
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    infoBtn(id)
    {
      size = [flex(), SIZE_TO_CONTENT]
      maxHeight = evenPx(60)
      children = cardTitle(id)
    }
  ]
}

let boosterSlot = @(bst, sf) {
  rendObj = ROBJ_SOLID
  color = 0xFF645858
  children = [
    sf & S_HOVER ? bgHiglight : null
    {
      rendObj = ROBJ_IMAGE
      size = bgSize
      image = Picture($"ui/gameuiskin/shop_bg_slot.avif:{bgSize[0]}:{bgSize[1]}:P")
    }
    {
      size = flex()
      padding = [0, 0, hdpx(20), 0]
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
let battlesLeftTitle = @(bst) {
  size = [bgSize[0], SIZE_TO_CONTENT]
  hplace = ALIGN_CENTER
  margin = [hdpx(20),0,0,0]
  flow = FLOW_HORIZONTAL
  gap = hdpx(15)
  children = [
    {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      size = [flex(), SIZE_TO_CONTENT]
      text = loc("booster/activeBattles")
    }.__update(fontTinyAccented)
    @() {
      watch = servProfile
      rendObj = ROBJ_TEXT
      text = servProfile.value?.boosters[bst.id].battlesLeft ?? 0
      transform = {}
      animations = [{
        prop = AnimProp.scale, from = [1,1], to = [1.7, 1.7],
        duration = 1, trigger = $"changeBoosterNumber_{bst.id}", easing = DoubleBlink
    }]
    }.__update(fontTinyAccented)
  ]
}

let function boosterCard(bst) {
  let stateFlags = Watched(0)
  let battlesLeft = Computed(@() servProfile.value?.boosters[bst.id].battlesLeft)
  battlesLeft.subscribe(@(_) anim_start($"changeBoosterNumber_{bst.id}"))
  return @(){
    watch = [stateFlags, serverConfigs]
    flow = FLOW_VERTICAL
    keepWatch = battlesLeft
    onClick = @() purchaseBooster(bst.id, loc($"boosters/{bst.id}"),
      mkBqPurchaseInfo(PURCH_SRC_BOOSTERS, PURCH_TYPE_BOOSTERS, bst.id))
    onElemState = @(v) stateFlags(v)
    behavior = Behaviors.Button
    sound = { click  = "click" }
    transform = {
      scale = stateFlags.value & S_ACTIVE ? [0.95, 0.95] : [1, 1]
    }
    children = [
      boosterSlot(bst, stateFlags.value)
      mkPricePlate(bst)
      battlesLeftTitle(bst)
    ]
  }
}

let goods = @() {
  watch = serverConfigs
  flow = FLOW_HORIZONTAL
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  gap = hdpx(50)
  children = serverConfigs.get()?.allBoosters
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