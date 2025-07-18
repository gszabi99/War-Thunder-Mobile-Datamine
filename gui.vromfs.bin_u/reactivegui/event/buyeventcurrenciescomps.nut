from "%globalsDarg/darg_library.nut" import *
let { mkCurrencyFullId, currencyToFullId, sortByCurrencyId } = require("%appGlobals/pServer/seasonCurrencies.nut")
let { getCurrencyDescription } = require("%appGlobals/config/currencyPresentation.nut")
let { eventCurrenciesGoods, closeBuyEventCurrenciesWnd, currencyId, parentEventId, parentEventLoc,
  buyCurrencyWndGamercardCurrencies
} = require("%rGui/event/buyEventCurrenciesState.nut")
let { mkGoodsWrap, mkSlotBgImg, mkCurrencyAmountTitle, mkGoodsImg, mkPricePlate, mkGoodsCommonParts, mkBgParticles,
  txt, mkGoodsLimitAndEndTime, goodsGlareAnimDuration } = require("%rGui/shop/goodsView/sharedParts.nut")
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
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { mkScrollArrow } = require("%rGui/components/scrollArrows.nut")
let { horizontalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")


let tasksBgGrad = mkColoredGradientY(0xFF09C6F9, 0xFF00808E, 12)
let titleFontGrad = mkFontGradient(0xFFDADADA, 0xFF848484, 11, 6, 2)
let glareDelay = 5.0
let glareOffsetMul = 0.62 * goodsGlareAnimDuration
let glareDuration = 0.2 * goodsGlareAnimDuration

let gap = hdpx(40)
let goodsW = hdpx(360)
let goodsH = hdpx(600)
let pricePlateH = hdpx(90)
let goodsSize = [goodsW, goodsH]
let goodsBgSize = [goodsW, goodsH - pricePlateH]

let maxColumns = (saSize[0] / (gap + goodsW)).tointeger()

let imgStyle = {
  imageHalign = ALIGN_CENTER
  imageValign = ALIGN_CENTER
  margin = const [hdpx(50), hdpx(25), 0, hdpx(25)]
}

function getImgByAmount(curId, amount) {
  let cfg = getCurrencyGoodsPresentation(curId, amount)
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

function mkQuestsLink(curId, eventId) {
  let cfg = getCurrencyGoodsPresentation(curId, 1000000)
  let bgParticles = mkBgParticles(goodsBgSize)

  return mkGoodsWrap(
    {},
    function() {
      openEventQuestsWnd(eventId)
      closeBuyEventCurrenciesWnd()
    },
    @(sf, _) [
      mkSlotBgImg()
      bgParticles
      sf & S_HOVER ? bgHiglight : null
      mkGoodsImg(cfg.img, cfg?.fallbackImg, imgStyle)
    ],
    questsLinkPlate,
    { size = goodsSize, clickableInfo = loc("item/open") },
    { size = goodsBgSize })
}

function mkTimeTextComputed(goods) {
  local { timeRange = null, timeRanges = [] } = goods
  if (timeRange != null && (timeRange.start != 0 || timeRange.end != 0)) 
    timeRanges = [timeRange]
  if (timeRanges.len() == 0)
    return Watched(null)

  return Computed(function() {
    let time = serverTime.get()
    local nextStart = null
    foreach (tr in timeRanges) {
      let { start = 0, end = 0 } = tr
      if (start > time)
        nextStart = min(nextStart ?? start, start)
      else if (end >= time)
        return null 
    }
    return nextStart == null ? loc("events/buyCurrency/noLongerAvailable")
      : loc("events/buyCurrency/availableAfter", { time = secondsToHoursLoc(nextStart - time) })
  })
}

function mkGoods(goods, onClick, state, animParams) {
  local cId = goods.currencies.findindex(@(v) v > 0) ?? ""
  local amount = goods.currencies?[cId] ?? 0
  let bgParticles = mkBgParticles(goodsBgSize)
  let timeText = mkTimeTextComputed(goods)

  let isAvailable = Computed(@() timeText.get() == null)
  let fullId = mkCurrencyFullId(cId)
  return @() {
    watch = [isAvailable, fullId]
    children = [
      mkGoodsWrap(
        goods,
        isAvailable.get() ? onClick : null,
        @(sf, _) [
          mkSlotBgImg()
          bgParticles
          sf & S_HOVER ? bgHiglight : null
          getImgByAmount(fullId.get(), amount)
          mkCurrencyAmountTitle(amount, goods?.viewBaseValue ?? 0, titleFontGrad)
          mkGoodsLimitAndEndTime(goods)
        ].extend(mkGoodsCommonParts(goods, state)),
        mkPricePlate(goods, state, animParams),
        { size = goodsSize },
        { size = goodsBgSize }
      )
      isAvailable.get() ? null : {
        size = flex()
        rendObj = ROBJ_BOX
        fillColor = 0xBF000000
        children = @() {
          watch = timeText
          size = FLEX_H
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          vplace = ALIGN_CENTER
          halign = ALIGN_CENTER
          text = timeText.get()
        }.__update(fontTinyShaded)
      }
    ]
  }
}

let pannableArea = horizontalPannableAreaCtor(sw(100), [saBorders[0], saBorders[0]])
let scrollHandler = ScrollHandler()

let scrollArrowsBlock = {
  size = [sw(100), goodsH]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    mkScrollArrow(scrollHandler, MR_L)
    mkScrollArrow(scrollHandler, MR_R)
  ]
}

let sortByCurrencyAndAmount = @(a, b) sortByCurrencyId(a.price.currencyId, b.price.currencyId)
  || a.price.price <=> b.price.price

let mkCurrenciesList = @(cId, goodsList, showQuestsLink, needUseScroll, ovr = {}) {
  flow = FLOW_HORIZONTAL
  halign = needUseScroll ? ALIGN_LEFT : ALIGN_CENTER
  gap
  children = [
    @() {
      watch = [showQuestsLink, parentEventId]
      children = showQuestsLink.get() ? mkQuestsLink(cId, parentEventId.get()) : null
    }
  ].extend(mkGoodsListWithBaseValue(goodsList)
      .sort(sortByCurrencyAndAmount)
      .map(@(good, idx) mkGoods(good,
        @() onGoodsClick(good),
        mkGoodsState(good),
        {
          delay = idx * glareOffsetMul + glareDelay + glareDuration
          repeatDelay = glareDelay
        })))
}.__update(ovr)

function mkEventCurrenciesGoods() {
  let cId = currencyToFullId.get()?[currencyId.get()] ?? currencyId.get()
  let showQuestsLink = Computed(@()
    getQuestCurrenciesInTab(parentEventId.get(), questsCfg.get(), questsBySection.get(),
      progressUnlockBySection.get(), progressUnlockByTab.get(), serverConfigs.get())
        .findindex(@(v) v == cId) != null)
  let needUseScroll = Computed(@() (eventCurrenciesGoods.get().len()) + (showQuestsLink.get() ? 1 : 0) > maxColumns)

  return {
    watch = [eventCurrenciesGoods, currencyId, currencyToFullId, needUseScroll]
    padding = const [hdpx(45), 0, 0, 0]
    size = flex()
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    children = !needUseScroll.get() ? mkCurrenciesList(cId, eventCurrenciesGoods.get(), showQuestsLink, needUseScroll.get())
      : {
        size = flex()
        children = [
          pannableArea(mkCurrenciesList(cId, eventCurrenciesGoods.get(), showQuestsLink, needUseScroll.get()),
            {},
            {
              behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ],
              scrollHandler = scrollHandler
            })
          scrollArrowsBlock
        ]
      }
  }
}

let buyEventCurrenciesHeader = @() {
  watch = [currencyId, parentEventLoc]
  size = FLEX_H
  halign = ALIGN_CENTER
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = utf8ToUpper(loc($"events/buyCurrency/{currencyId.get()}", { name = parentEventLoc.get() }))
}.__update(fontLarge)

let buyEventCurrenciesDesc = @(){
  watch = [eventCurrenciesGoods, currencyId]
  size = [saSize[0], SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  text = getCurrencyDescription(currencyId.get())
}.__update(fontMedium)

let buyEventCurrenciesGamercard = @() {
  watch = currencyId
  size = [saSize[0], gamercardHeight]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    backButton(closeBuyEventCurrenciesWnd, { vplace = ALIGN_CENTER })
    { size = flex() }
    {
      valign = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      gap = hdpx(70)
      children = buyCurrencyWndGamercardCurrencies.get().map(@(v) mkCurrencyBalance(v))
    }
  ]
}

return {
  buyEventCurrenciesHeader
  buyEventCurrenciesGamercard
  mkEventCurrenciesGoods
  buyEventCurrenciesDesc
}
