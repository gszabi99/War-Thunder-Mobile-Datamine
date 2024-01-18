from "%globalsDarg/darg_library.nut" import *
let { eventCurrenciesGoods, closeBuyEventCurrenciesWnd, currencyId, parentEventId, parentEventLoc
} = require("buyEventCurrenciesState.nut")
let { mkGoodsWrap, mkSlotBgImg, mkCurrencyAmountTitle, mkGoodsImg, mkPricePlate, mkGoodsCommonParts, mkBgParticles,
  txt } = require("%rGui/shop/goodsView/sharedParts.nut")
let { mkColoredGradientY, mkFontGradient } = require("%rGui/style/gradients.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { onGoodsClick, mkGoodsListWithBaseValue, mkGoodsState } = require("%rGui/shop/shopWndPage.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { mkCurrencyBalance } = require("%rGui/mainMenu/balanceComps.nut")
let { openEventQuestsWnd, getQuestCurrenciesInTab, questsCfg, questsBySection, progressUnlockBySection,
  progressUnlockByTab } = require("%rGui/quests/questsState.nut")
let getCurrencyGoodsPresentation = require("%appGlobals/config/currencyGoodsPresentation.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { eventSeason } = require("%rGui/event/eventState.nut")

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
  margin = hdpx(25)
}

let function getImgByAmount(amount, curId, season) {
  let imgCfg = getCurrencyGoodsPresentation(curId, season)
  let idxByAmount = imgCfg.findindex(@(v) v.amountAtLeast > amount) ?? imgCfg.len()
  let cfg = imgCfg?[max(0, idxByAmount - 1)]
  return mkGoodsImg(cfg?.img, cfg?.fallbackImg, imgStyle)
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

let function mkQuestsLink(curId, season) {
  let imgCfg = getCurrencyGoodsPresentation(curId, season)
  let cfg = imgCfg?[imgCfg.len() - 1]

  return mkGoodsWrap(function() {
      openEventQuestsWnd()
      closeBuyEventCurrenciesWnd()
    },
    @(sf) [
      mkSlotBgImg()
      mkBgParticles(goodsBgSize)
      sf & S_HOVER ? bgHiglight : null
      mkGoodsImg(cfg?.img, cfg?.fallbackImg, imgStyle)
    ],
    questsLinkPlate,
    { size = goodsSize, clickableInfo = loc("item/open") },
    { size = goodsBgSize })
}


let mkGoods = @(goods, onClick, state, animParams) @() {
  watch = [currencyId, eventSeason]
  children = mkGoodsWrap(onClick,
    @(sf) [
      mkSlotBgImg()
      mkBgParticles(goodsBgSize)
      sf & S_HOVER ? bgHiglight : null
      getImgByAmount(goods?[currencyId.value] ?? 0, currencyId.value, eventSeason.get())
      mkCurrencyAmountTitle(goods?[currencyId.value] ?? 0, goods?.viewBaseValue ?? 0, titleFontGrad)
    ].extend(mkGoodsCommonParts(goods, state)),
    mkPricePlate(goods, priceBgGrad, state, animParams),
    { size = goodsSize },
    { size = goodsBgSize })
}

let function mkEventCurrenciesGoods() {
  let showQuestsLink = Computed(@()
    getQuestCurrenciesInTab(parentEventId.get(), questsCfg.get(), questsBySection.get(),
      progressUnlockBySection.get(), progressUnlockByTab.get(), serverConfigs.get())
        .findindex(@(v) v == currencyId.get()) != null)

  return {
    watch = [eventCurrenciesGoods, currencyId, showQuestsLink, eventSeason]
    size = [flex(), SIZE_TO_CONTENT]
    padding = [hdpx(45), 0, 0, 0]
    flow = FLOW_HORIZONTAL
    gap
    halign = ALIGN_CENTER
    children = [showQuestsLink.value ? mkQuestsLink(currencyId.value, eventSeason.get()) : null]
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
}

let buyEventCurrenciesHeader = @() {
  watch = [currencyId, parentEventLoc]
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = utf8ToUpper(loc($"events/buyCurrency/{currencyId.value}", { name = parentEventLoc.value }))
}.__update(fontLarge)

let buyEventCurrenciesDesc = @(){
  watch = eventCurrenciesGoods
  size = [(goodsW + gap) * (eventCurrenciesGoods.value.len() + 1), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  text = loc("events/buyCurrency/desc")
}.__update(fontMedium)

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
  buyEventCurrenciesDesc
}
