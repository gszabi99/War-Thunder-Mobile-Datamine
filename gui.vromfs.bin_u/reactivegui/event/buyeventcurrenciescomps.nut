from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
import "%appGlobals/config/currencyGoodsPresentation.nut" as getCurrencyGoodsPresentation
from "%appGlobals/config/currencyPresentation.nut" import getCurrencyConvertInfo
from "%appGlobals/pServer/seasonCurrencies.nut" import mkCurrencyFullId, currencyToFullId, sortByCurrencyId,
  currencySeasons
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/rewardType.nut" import G_CURRENCY
from "%appGlobals/timeToText.nut" import secondsToHoursLoc
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/pannableArea.nut" import horizontalPannableAreaCtor
from "%rGui/components/scrollArrows.nut" import mkScrollArrow
from "%rGui/event/buyEventCurrenciesState.nut" import eventCurrenciesGoods, closeBuyEventCurrenciesWnd, currencyId,
  parentEventLoc, buyCurrencyWndGamercardCurrencies
from "%rGui/event/eventLootboxes.nut" import inactiveLootboxes
from "%rGui/mainMenu/gamercard.nut" import mkCurrenciesBtns
from "%rGui/quests/questsState.nut" import getQuestNextRewardCurrenciesInTab, questsCfg, questsBySection,
  progressUnlockBySection, progressUnlockByTab
from "%rGui/seasonScene/seasonSceneState.nut" import openQuestsWndOnTab
from "%rGui/shop/goodsView/sharedParts.nut" import mkGoodsWrap, mkSlotBgImg, mkCurrencyAmountTitle, mkGoodsImg,
  mkPricePlate, mkGoodsCommonParts, mkBgParticles, txt, mkGoodsLimitAndEndTime, goodsGlareAnimDuration
from "%rGui/shop/shopWndPage.nut" import onGoodsClick, mkGoodsListWithBaseValue, mkGoodsState
from "%rGui/style/gradients.nut" import mkColoredGradientY, mkFontGradient
from "%rGui/components/gradientDefComps.nut" import headerGradientWithRightBlock

let tasksBgGrad = mkColoredGradientY(0xFF09C6F9, 0xFF00808E, 12)
let titleFontGrad = mkFontGradient(0xFFDADADA, 0xFF848484, 11, 6, 2)
const glareDelay = 5.0
let glareOffsetMul = 0.62 * goodsGlareAnimDuration
let glareDuration = 0.2 * goodsGlareAnimDuration

const gap = hdpx(40)
const goodsW = hdpx(360)
const goodsH = hdpx(600)
const pricePlateH = hdpx(90)
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
  size = FLEX
  rendObj = ROBJ_SOLID
  color = 0x0114181E
}

let questsLinkPlate = {
  size = FLEX
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = tasksBgGrad
  children = txt({ text = utf8ToUpper(loc("mainmenu/btnQuests")) }.__update(fontSmall))
}

function mkQuestsLink(curId, tabId) {
  let cfg = getCurrencyGoodsPresentation(curId, 1000000)
  let bgParticles = mkBgParticles(goodsBgSize)

  return mkGoodsWrap(
    {},
    function() {
      openQuestsWndOnTab(tabId)
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
  let { timeRanges = [] } = goods
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
      : loc("events/buyCurrency/availableAfter",
          { time = secondsToHoursLoc(nextStart - time).replace(" ", nbsp) })
  })
}

function mkGoods(goods, onClick, state, animParams) {
  let { viewBaseValue = 0, rewards } = goods
  let { id = null, count = 0 } = rewards.findvalue(@(r) r.gType == G_CURRENCY)
  if (id == null)
    return null

  let bgParticles = mkBgParticles(goodsBgSize)
  let timeText = mkTimeTextComputed(goods)
  let isAvailable = Computed(@() timeText.get() == null)
  let fullId = mkCurrencyFullId(id)
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
          getImgByAmount(fullId.get(), count)
          mkCurrencyAmountTitle(count, viewBaseValue, titleFontGrad)
          mkGoodsLimitAndEndTime(goods)
        ].extend(mkGoodsCommonParts(goods, state)),
        mkPricePlate(goods, state, animParams),
        { size = goodsSize },
        { size = goodsBgSize }
      )
      isAvailable.get() ? null : {
        size = FLEX
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
  size = const [sw(100), goodsH]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    mkScrollArrow(scrollHandler, MR_L)
    mkScrollArrow(scrollHandler, MR_R)
  ]
}

let sortByCurrencyAndAmount = @(a, b) sortByCurrencyId(a.price.currencyId, b.price.currencyId)
  || a.price.price <=> b.price.price

let mkCurrenciesList = @(cId, goodsList, showQuestsLinkTabId, needUseScroll, ovr = {}) {
  flow = FLOW_HORIZONTAL
  halign = needUseScroll ? ALIGN_LEFT : ALIGN_CENTER
  gap
  children = [
    showQuestsLinkTabId != null ? mkQuestsLink(cId, showQuestsLinkTabId) : null
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
  let showQuestsLinkTabId = Computed(function() {
    foreach (tabId, _ in questsCfg.get()) {
      let currencies = getQuestNextRewardCurrenciesInTab(tabId, questsCfg.get(), questsBySection.get(),
        progressUnlockBySection.get(), progressUnlockByTab.get(), serverConfigs.get())
      if (currencyId.get() in currencies)
        return tabId
    }
    return null
  })
  let needUseScroll = Computed(@()
    (eventCurrenciesGoods.get().len()) + (showQuestsLinkTabId.get() != null ? 1 : 0) > maxColumns)
  let cFullId = Computed(@() currencyToFullId.get()?[currencyId.get()] ?? currencyId.get())

  return @() {
    watch = [eventCurrenciesGoods, cFullId, needUseScroll, showQuestsLinkTabId]
    size = FLEX_H
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    children = !needUseScroll.get()
      ? mkCurrenciesList(cFullId.get(), eventCurrenciesGoods.get(), showQuestsLinkTabId.get(), needUseScroll.get())
      : {
        size = FLEX_H
        children = [
          pannableArea(
            mkCurrenciesList(cFullId.get(), eventCurrenciesGoods.get(), showQuestsLinkTabId.get(), needUseScroll.get()),
            { size = const [sw(100), FLEX] },
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
  size = FLEX_V
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  text = utf8ToUpper(loc($"events/buyCurrency/{currencyId.get()}", { name = parentEventLoc.get() }))
}.__update(fontBig)

let hasLootboxesForConvertion = @(cId, inactLootboxes, servConfigs) !!servConfigs?.lootboxesCfg
  .findvalue(@(v, id) (id not in inactLootboxes) && v.currencyId == cId)

let buyEventCurrenciesDesc = function() {
  let convertionCurrencyId = currencySeasons.get()?[currencyId.get()].convertion.currencyId ?? ""
  return {
    watch = [currencyId, currencySeasons, inactiveLootboxes, serverConfigs]
    size = [saSize[0], SIZE_TO_CONTENT]
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    halign = ALIGN_CENTER
    text = convertionCurrencyId == ""
        && !hasLootboxesForConvertion(currencyId.get(), inactiveLootboxes.get(), serverConfigs.get())
      ? null
      : getCurrencyConvertInfo(convertionCurrencyId)
  }.__update(fontMedium)
}

let buyEventCurrenciesGamercard = @() {
  watch = [currencyId, buyCurrencyWndGamercardCurrencies]
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    headerGradientWithRightBlock([ backButton(closeBuyEventCurrenciesWnd), buyEventCurrenciesHeader ],
      mkCurrenciesBtns(buyCurrencyWndGamercardCurrencies.get(), { [currencyId.get()] = true })
    )

  ]
}

return {
  buyEventCurrenciesGamercard
  mkEventCurrenciesGoods
  buyEventCurrenciesDesc
}
