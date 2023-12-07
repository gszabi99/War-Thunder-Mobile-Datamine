from "%globalsDarg/darg_library.nut" import *
let { eventCurrenciesGoods, closeBuyEventCurrenciesWnd, currencyId } = require("buyEventCurrenciesState.nut")
let { mkGoodsWrap, mkSlotBgImg, mkCurrencyAmountTitle, mkGoodsImg, mkPricePlate, mkGoodsCommonParts, mkBgParticles,
  txt } = require("%rGui/shop/goodsView/sharedParts.nut")
let { mkColoredGradientY, mkFontGradient } = require("%rGui/style/gradients.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { onGoodsClick, mkGoodsListWithBaseValue, mkGoodsState } = require("%rGui/shop/shopWndPage.nut")
let { gamercardHeight } = require("%rGui/mainMenu/gamercard.nut")
let { mkCurrencyBalance } = require("%rGui/mainMenu/balanceComps.nut")
let { WARBOND, EVENT_KEY } = require("%appGlobals/currenciesState.nut")
let { eventSeasonName } = require("eventState.nut")
let { openEventQuestsWnd } = require("%rGui/quests/questsState.nut")

let priceBgGrad = mkColoredGradientY(0xFFD2A51E, 0xFF91620F, 12)
let tasksBgGrad = mkColoredGradientY(0xFF09C6F9, 0xFF00808E, 12)
let titleFontGrad = mkFontGradient(0xFFDADADA, 0xFF848484, 11, 6, 2)
let glareDelay = 3.0
let glareDuration = 0.2

let gap = hdpx(40)
let goodsW = hdpx(360)
let goodsH = hdpx(600)
let pricePlateH = hdpx(90)
let goodsSize = [goodsW, goodsH]
let goodsBgSize = [goodsW, goodsH - pricePlateH]

let imgStyle = {
  imageHalign = ALIGN_CENTER
  imageValign = ALIGN_BOTTOM
}

let imgCfgByCurrency = {
  [WARBOND] = [
    { mkImg = @() mkGoodsImg("ui/gameuiskin/warbond_goods_01.avif", imgStyle), amountAtLeast = 0 }
    { mkImg = @() mkGoodsImg("ui/gameuiskin/warbond_goods_02.avif", imgStyle), amountAtLeast = 2000 }
    { mkImg = @() mkGoodsImg("ui/gameuiskin/warbond_goods_03.avif", imgStyle), amountAtLeast = 10000 }
  ],
  [EVENT_KEY] = [
    { mkImg = @() mkGoodsImg("ui/gameuiskin/event_keys_01.avif", imgStyle), amountAtLeast = 0 }
    { mkImg = @() mkGoodsImg("ui/gameuiskin/event_keys_02.avif", imgStyle), amountAtLeast = 2 }
    { mkImg = @() mkGoodsImg("ui/gameuiskin/event_keys_03.avif", imgStyle), amountAtLeast = 10 }
  ]
}

let function getImgByAmount(amount, id) {
  let imgCfg = imgCfgByCurrency?[id] ?? []
  let idxByAmount = imgCfg.findindex(@(v) v.amountAtLeast > amount) ?? imgCfg.len()
  return imgCfg?[max(0, idxByAmount - 1)].mkImg()
}

let bgHiglight = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x0114181E
}

let questsLinkPlate = {
  size = flex()
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = tasksBgGrad
  children = txt({ text = utf8ToUpper(loc("mainmenu/btnQuests")) }.__update(fontSmall))
}

let questsLink = mkGoodsWrap(function() {
    openEventQuestsWnd()
    closeBuyEventCurrenciesWnd()
  },
  @(sf) [
    mkSlotBgImg()
    mkBgParticles(goodsBgSize)
    sf & S_HOVER ? bgHiglight : null
    mkGoodsImg("ui/gameuiskin/warbond_goods_03.avif", imgStyle)
  ],
  questsLinkPlate,
  { size = goodsSize, clickableInfo = loc("item/open") },
  { size = goodsBgSize })


let mkGoods = @(goods, onClick, state, animParams) @() {
  watch = currencyId
  children = mkGoodsWrap(onClick,
    @(sf) [
      mkSlotBgImg()
      mkBgParticles(goodsBgSize)
      sf & S_HOVER ? bgHiglight : null
      getImgByAmount(goods?[currencyId.value] ?? 0, currencyId.value)
      mkCurrencyAmountTitle(goods?[currencyId.value] ?? 0, goods?.viewBaseValue ?? 0, titleFontGrad)
    ].extend(mkGoodsCommonParts(goods, state)),
    mkPricePlate(goods, priceBgGrad, state, animParams),
    { size = goodsSize },
    { size = goodsBgSize })
}

let mkEventCurrenciesGoods = @() {
  watch = [eventCurrenciesGoods, currencyId]
  size = [flex(), SIZE_TO_CONTENT]
  padding = [hdpx(45), 0, 0, 0]
  flow = FLOW_HORIZONTAL
  gap
  halign = ALIGN_CENTER
  children = [currencyId.value == WARBOND ? questsLink : null]
    .extend(mkGoodsListWithBaseValue(eventCurrenciesGoods.value.values())
      .sort(@(a, b) (a?[currencyId.value] ?? 0) <=> (b?[currencyId.value] ?? 0))
      .map(@(good, idx) mkGoods(good,
        @() onGoodsClick(good),
        mkGoodsState(good),
        {
          delay = idx * glareDuration + glareDelay
          repeatDelay = glareDuration * (eventCurrenciesGoods.value.len() - idx)
        })))
}

let buyEventCurrenciesHeader = @() {
  watch = [currencyId, eventSeasonName]
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  text = utf8ToUpper(currencyId.value == WARBOND
      ? loc("events/buyWarbonds")
    : loc("events/buyEventKeys", { name = eventSeasonName.value }))
}.__update(fontLarge)

let buyEventCurrenciesGamercard = @() {
  watch = currencyId
  size = [saSize[0], gamercardHeight]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    backButton(closeBuyEventCurrenciesWnd, { vplace = ALIGN_CENTER })
    { size = flex() }
    mkCurrencyBalance(currencyId.value)
  ]
}

return {
  buyEventCurrenciesHeader
  buyEventCurrenciesGamercard
  mkEventCurrenciesGoods
}
