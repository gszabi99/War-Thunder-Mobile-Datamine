from "%appGlobals/config/skins/skinTags.nut" import *
from "%globalsDarg/darg_library.nut" import *
from "math" import round
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/config/lootboxPresentation.nut" import getLootboxName
from "%appGlobals/config/skinPresentation.nut" import getSkinPresentation
from "%appGlobals/pServer/campaign.nut" import purchasesCount, todayPurchasesCount, goodsLimitReset
from "%appGlobals/pServer/pServerApi.nut" import buy_unit_skin, enable_unit_skin, skinsInProgress
from "%appGlobals/pServer/profile.nut" import campMyUnits
from "%appGlobals/pServer/seasonCurrencies.nut" import currencyToFullId
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/rewardType.nut" import G_SKIN, G_LOOTBOX
from "%appGlobals/unitPresentation.nut" import getUnitName
from "%appGlobals/userstats/serverTimeDay.nut" import serverTimeDay, dayOffset
from "%rGui/battlePass/battlePassState.nut" import bpFreeRewardsUnlock, bpPaidRewardsUnlock, bpPurchasedUnlock,
  battlePassGoods
from "%rGui/battlePass/passState.nut" import BATTLE_PASS
from "%rGui/components/buttonStyles.nut" import defButtonHeight
from "%rGui/components/currencyComp.nut" import mkCurrencyComp, mkCurrencyImage
from "%rGui/components/gradientDefComps.nut" import doubleSideGradient
import "%rGui/components/listbox.nut" as listbox
from "%rGui/components/pannableArea.nut" import horizontalPannableAreaCtor
from "%rGui/components/spinner.nut" import spinner
from "%rGui/components/textButton.nut" import textButtonPrimary, textButtonPricePurchase
from "%rGui/components/unseenMark.nut" import mkPriorityUnseenMarkWatch
from "%rGui/event/eventLocName.nut" import mkEventLocComp
from "%rGui/event/eventLootboxes.nut" import eventLootboxesRaw
from "%rGui/event/eventState.nut" import MAIN_EVENT_ID
import "%rGui/event/shouldShowEventMechanics.nut" as shouldShowEventMechanics
from "%rGui/notifications/logEvents.nut" import sendTelemetrySavedEvent
from "%rGui/rewards/lootboxesRewards.nut" import findLootboxWithReward
from "%rGui/rewards/unlockRewards.nut" import findUnlockWithReward
from "%rGui/seasonScene/seasonSceneState.nut" import openSeasonScene, openMainSeasonScene, PASS_SCENE, LOOTBOX_TAB,
  openShopByGoods
from "%rGui/shop/bqPurchaseInfo.nut" import PURCH_SRC_SKINS, PURCH_TYPE_SKIN, mkBqPurchaseInfo
from "%rGui/shop/goodsPreviewState.nut" import openGoodsPreview
from "%rGui/shop/goodsUtils.nut" import chooseBetterGoods, canPurchaseGoods
from "%rGui/shop/lootboxPreviewState.nut" import openEventWndLootbox
from "%rGui/shop/msgBoxPurchase.nut" import openMsgBoxPurchase
from "%rGui/shop/shopState.nut" import shopGoods
from "%rGui/style/stdColors.nut" import userlogTextColor, markTextColor, selectColor, hoverColor
from "%rGui/unit/unitSettings.nut" import mkIsAutoSkin, mkSkinCustomTags
from "%rGui/unitCustom/unitCustomComps.nut" import mkGradText, mkIcon, iconSize
import "%rGui/unitCustom/unitSkins/changeSkinTagWnd.nut" as changeSkinTagWnd
from "%rGui/unitCustom/unitSkins/unitSkinsState.nut" import unitSkins, selectedSkin, currentSkin, availableSkins,
  selectedSkinCfg, hasTagsChoice
from "%rGui/unitCustom/unitSkins/unseenSkins.nut" import unseenSkins, markAllUnitSkinsSeen, markSkinSeen
from "%rGui/unitDetails/unitDetailsState.nut" import baseUnit, unitToShow, isOwnUnit


const telemetrySaveId = "DefaultSkinWasReplaced"
const SKINS_IN_ROW = 4
const SKINS_IN_ROW_TAGS = 3.4
const skinSize = hdpxi(100)
let skinBorderRadius = round(skinSize * 0.2).tointeger()
let skinGap = evenPx(15)
const tagNameSize = hdpx(170)
const skinsRowPadding = hdpx(20)
let skinsRowWidth = skinSize * SKINS_IN_ROW + skinGap * (SKINS_IN_ROW - 1)
let rowHeight = skinSize + skinGap
const aTimeSelected = 0.2
const rowBgEvenColor = 0xB3000000
const rowBgOddColor = 0x70000000

let skinsPannable = horizontalPannableAreaCtor(skinsRowWidth + skinSize + skinsRowPadding * 2, [skinsRowPadding, skinsRowPadding])
let skinsPannableWithTags = horizontalPannableAreaCtor(
  (skinSize + skinGap) * SKINS_IN_ROW_TAGS + skinsRowPadding, [skinsRowPadding, skinsRowPadding])

let mkTankRow = @(rowIdx, text, content, ovr = {}) {
  size = [pw(100), rowHeight]
  rendObj = ROBJ_SOLID
  padding = [skinGap / 2, skinsRowPadding]
  color = rowIdx % 2 == 1 ? rowBgOddColor : rowBgEvenColor
  flow = FLOW_HORIZONTAL
  gap = skinGap
  children = [
    {
      size = const [tagNameSize, FLEX]
      valign = ALIGN_CENTER
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = text
    }.__update(fontTinyAccented)
    content
  ]
}.__merge(ovr)

let mkInfoTextarea = @(text, ovr = {}) doubleSideGradient.__merge({
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  padding = skinsRowPadding
  children = {
    maxWidth = hdpx(400)
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    halign = ALIGN_CENTER
    text
  }.__update(fontTiny)
}.__update(ovr))

function findShopSkinGoods(unitName, skinName, allGoods) {
  local res = null
  foreach(g in allGoods) {
    if (g.isHidden)
      continue

    let { rewards } = g
    if (null == rewards.findvalue(@(r) r.id == unitName && r.subId == skinName && r.gType == G_SKIN))
      continue

    if (res == null || (g.rewards.len() <= res.rewards.len()))
      res = g
  }
  return res
}

function skinBtn(skinPresentation) {
  let stateFlags = Watched(0)
  let { name, image } = skinPresentation
  let isLocked = Computed(@() name not in availableSkins.get())
  let isSelected = Computed(@() name == selectedSkin.get())
  let currencyId = Computed(function() {
    let baseId = serverConfigs.get()?.skins[name][baseUnit.get()?.name].currencyId
      ?? findShopSkinGoods(baseUnit.get()?.name, name, shopGoods.get())?.price.currencyId
    return currencyToFullId.get()?[baseId] ?? baseId
  })
  let canChangeTags = Computed(@() hasTagsChoice.get() && isSelected.get() && !isLocked.get())

  return @() {
    watch = [stateFlags, isLocked]
    size = skinSize
    rendObj = ROBJ_BOX
    fillColor = isLocked.get() ? 0xFF909090 : 0xFFFFFFFF
    borderRadius = skinBorderRadius
    image = Picture($"ui/gameuiskin#{image}:{skinSize}:{skinSize}:P")
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags.set(sf)
    function onClick() {
      markSkinSeen(baseUnit.get()?.name, name)
      if (!isSelected.get())
        selectedSkin.set(name)
      else if (canChangeTags.get() && "name" in baseUnit.get())
        changeSkinTagWnd(baseUnit.get().name, name)
    }
    transform = { scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.95, 0.95] : [1, 1] }
    children = [
      @() {
        watch = isSelected
        size = FLEX
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#slot_border.svg:{skinSize}:{skinSize}:P")
        color = isSelected.get() ? selectColor : 0
        transitions = [{ prop = AnimProp.color, duration = aTimeSelected }]
      }
      @() {
        watch = stateFlags
        size = FLEX
        rendObj = ROBJ_BOX
        image = Picture("ui/gameuiskin#hovermenu_shop_button_glow.avif")
        fillColor = stateFlags.get() & S_HOVER ? hoverColor : 0
        borderRadius = skinBorderRadius
        transitions = [{ prop = AnimProp.color, duration = aTimeSelected }]
        transform = { rotate = 180 }
      }
      @() {
        watch = [isLocked, currencyId]
        size = FLEX
        halign = ALIGN_LEFT
        valign = ALIGN_BOTTOM
        flow = FLOW_HORIZONTAL
        children = !isLocked.get() ? null
          : !currencyId.get() ? mkIcon("ui/gameuiskin#lock_icon.svg")
          : mkCurrencyImage(currencyId.get(), iconSize, { vplace = ALIGN_BOTTOM, margin = hdpx(8) })
      }
      @() {
        watch = currentSkin
        size = FLEX
        halign = ALIGN_LEFT
        valign = ALIGN_BOTTOM
        children = currentSkin.get() == name
          ? mkIcon("ui/gameuiskin#check.svg", { color = 0xFF78FA78 })
          : null
      }
      @() !canChangeTags.get() ? { watch = canChangeTags }
        : {
            watch = canChangeTags
            size = iconSize
            margin = hdpx(10)
            hplace = ALIGN_RIGHT
            rendObj = ROBJ_IMAGE
            image = Picture($"ui/gameuiskin#menu_edit.svg:{iconSize}:{iconSize}:P")
            keepAspect = true
          }
    ]
  }
}

let skinBlock = @(skinPresentation) {
  children = [
    skinBtn(skinPresentation)
    mkPriorityUnseenMarkWatch(
      Computed(@() skinPresentation.name in unseenSkins.get()?[baseUnit.get()?.name]),
      { hplace = ALIGN_RIGHT, margin = hdpx(10) })
  ]
}

function autoSkinRow() {
  let { isAutoSkin, setAutoSkin } = mkIsAutoSkin(Computed(@() baseUnit.get()?.name))

  let content = listbox({
    value = isAutoSkin
    list = [false, true]
    setValue = setAutoSkin
    mkContentCtor = @(v, _, _) {
      size = const [FLEX, hdpx(70)]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      color = 0xFFFFFFFF
      text = loc(v ? "controls/on" : "controls/off")
    }.__update(fontTinyAccented)
  }).__update({ vplace = ALIGN_CENTER })

  return mkTankRow(tankTagsOrder.len(), loc("skins/autoselect"), content,
    { size = const [pw(100), SIZE_TO_CONTENT], padding = skinsRowPadding })
}

function skinsBlockWithTags() {
  let { skinCustomTags } = mkSkinCustomTags(Computed(@() baseUnit.get()?.name))
  let skinsPresentationsByTag = Computed(function() {
    let res = {}
    let unitName = unitToShow.get()?.name ?? ""
    foreach(skin, _ in unitSkins.get()) {
      let p = getSkinPresentation(unitName, skin).__merge({ name = skin })
      let tag = skinCustomTags.get()?[skin] ?? p.tag
      if (tag not in res)
        res[tag] <- []
      res[tag].append(p)
    }
    foreach(list in res)
      list.sort(@(a, b) a.name <=> b.name)
    return res
  })

  return {
    size = const [pw(100), SIZE_TO_CONTENT]
    key = {}
    flow = FLOW_VERTICAL
    onDetach = @() markAllUnitSkinsSeen(baseUnit.get()?.name)
    children = tankTagsOrder
      .map(@(tag, idx)
        mkTankRow(idx, getTagName(tag),
          {
            size = FLEX
            children = skinsPannableWithTags(@() {
              watch = skinsPresentationsByTag
              valign = ALIGN_CENTER
              flow = FLOW_HORIZONTAL
              gap = skinGap
              children = (skinsPresentationsByTag.get()?[tag] ?? [])
                .map(skinBlock)
            })
          }))
      .append(autoSkinRow)
  }
}

let skinsBlockNoTags = @() {
  key = "skinsBlockNoTags"
  size = const [pw(100), skinSize + 2 * skinsRowPadding]
  onDetach = @() markAllUnitSkinsSeen(baseUnit.get()?.name)
  rendObj = ROBJ_SOLID
  padding = const [0, skinsRowPadding]
  color = rowBgEvenColor
  children = skinsPannable(
    @() {
      watch = [unitSkins, unitToShow]
      flow = FLOW_HORIZONTAL
      gap = skinGap
      vplace = ALIGN_CENTER
      children = unitSkins.get()
        .keys()
        .map(@(v) getSkinPresentation(unitToShow.get()?.name ?? "", v).__merge({ name = v }))
        .map(skinBlock)
    })
}

function onPurchase() {
  if (selectedSkinCfg.get() == null)
    return

  let unitName = baseUnit.get().name
  let skinName = selectedSkin.get()
  let { currencyId, price } = selectedSkinCfg.get()
  let locSkinName = loc("skins/title", { unitName = getUnitName(baseUnit.get()) })

  openMsgBoxPurchase({
    text = loc("shop/needMoneyQuestion", { item = colorize(userlogTextColor, locSkinName) }),
    price = { currencyId, price },
    purchase = @() buy_unit_skin(unitName, skinName, currencyId, price),
    bqInfo = mkBqPurchaseInfo(PURCH_SRC_SKINS, PURCH_TYPE_SKIN, skinName)
  })
}

function openLootboxForEvent(lootbox) {
  openSeasonScene(lootbox?.meta.event_id ?? MAIN_EVENT_ID, LOOTBOX_TAB)
  openEventWndLootbox(lootbox.name)
}

let canChangeSkin = @(unit, myUnits) unit.isUpgraded == myUnits?[unit.name].isUpgraded

function selectBtns(unit, vehicleName, skinName, cSkin) {
  if ("skin" not in unit && "currentSkins" not in unit) 
    return null
  return @() {
    watch = campMyUnits
    size = FLEX
    halign = cSkin == skinName ? ALIGN_CENTER : ALIGN_RIGHT
    flow = FLOW_HORIZONTAL
    gap = hdpx(20)
    children = cSkin == skinName
      ? mkGradText(loc("skins/applied"))
      : !canChangeSkin(unit, campMyUnits.get()) ? null
      : textButtonPrimary(utf8ToUpper(loc("mainmenu/btnApply")),
          function() {
            enable_unit_skin(unit.name, vehicleName, skinName)
            if (skinName != "")
              sendTelemetrySavedEvent("skin_equiped_1", telemetrySaveId)
          })
  }
}

let receiveSkinInfo = @(unitName, skinName) function() {
  let res = {
    watch = [
      eventLootboxesRaw, serverConfigs, bpFreeRewardsUnlock, bpPaidRewardsUnlock,
      bpPurchasedUnlock, battlePassGoods, shopGoods, goodsLimitReset, dayOffset, serverTimeDay,
      purchasesCount, todayPurchasesCount, shouldShowEventMechanics, currencyToFullId
    ]
    padding = [0, saBorders[0], 0, 0]
    hplace = ALIGN_RIGHT
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
  }

  let skinGoods = findShopSkinGoods(unitName, skinName, shopGoods.get())
  if (skinGoods != null) {
    let currencyId = currencyToFullId.get()?[skinGoods?.price.currencyId] ?? skinGoods?.price.currencyId
    return res.__update({
      children = textButtonPricePurchase(
        utf8ToUpper(loc("mainmenu/btnBuy")),
        mkCurrencyComp(skinGoods?.price.price, currencyId),
        @() openShopByGoods(skinGoods),
        { hplace = ALIGN_CENTER })
    })
  }

  let goodsByLootboxId = {}
  foreach (goods in shopGoods.get()) {
    let { id, rewards, isHidden = false, limit = 0, dailyLimit = 0, showAsOffer = false } = goods
    if (isHidden && !showAsOffer)
      continue
    if (!canPurchaseGoods(id, limit, dailyLimit, goodsLimitReset.get(), dayOffset.get(),
          serverTimeDay.get(), purchasesCount.get(), todayPurchasesCount.get()))
      continue
    foreach (r in rewards) {
      if (r.gType != G_LOOTBOX)
        continue
      if (!isHidden)
        goodsByLootboxId[r.id] <- (r.id not in goodsByLootboxId) ? goods : chooseBetterGoods(goodsByLootboxId[r.id], goods)
      else if (showAsOffer && r.id not in goodsByLootboxId)
        goodsByLootboxId[r.id] <- goods
    }
  }

  let lootbox = findLootboxWithReward(goodsByLootboxId.keys().extend(eventLootboxesRaw.get().values()),
    serverConfigs.get(),
    @(r) (null != r.findvalue(@(g) g.gType == "skin" && g.id == unitName && g.subId == skinName)))

  let goods = goodsByLootboxId?[lootbox]
  if (goods != null) {
    let lootboxTbl = serverConfigs.get().lootboxesCfg[lootbox]
    return res.__update({
      children = [
        @() mkInfoTextarea(loc("canReceive/inShopLootbox", { name = colorize(markTextColor, getLootboxName(lootboxTbl.name)) }))
        textButtonPrimary(utf8ToUpper(loc("msgbox/btn_browse")), @() openGoodsPreview(goods.id), { hplace = ALIGN_CENTER })
      ]
    })
  }

  if (lootbox != null && shouldShowEventMechanics.get()) {
    let { event_id = MAIN_EVENT_ID } = lootbox?.meta
    let eventLocName = mkEventLocComp(Watched(event_id))
    return res.__update({
      children = [
        @() mkInfoTextarea(
          loc("canReceive/inEvent", { eventName = colorize(markTextColor, eventLocName.get()) }),
          { watch = eventLocName })
        textButtonPrimary(utf8ToUpper(loc("msgbox/btn_browse")), @() openLootboxForEvent(lootbox), { hplace = ALIGN_CENTER })
      ]
    })
  }

  let bpUnlock = findUnlockWithReward([bpFreeRewardsUnlock.get(), bpPaidRewardsUnlock.get(), bpPurchasedUnlock.get()],
    serverConfigs.get(),
    @(r) (null != r.findvalue(@(g) g.gType == G_SKIN && g.id == unitName && g.subId == skinName)))
  let isBpGoods = null != battlePassGoods.get()
    .findindex(@(v) v != null
      && null != v.rewards.findvalue(@(r) r.gType == G_SKIN && r.id == unitName && r.subId == skinName))

  if ((bpUnlock != null || isBpGoods) && shouldShowEventMechanics.get())
    return res.__update({
        children = [
        mkInfoTextarea(loc("canReceive/inBattlePass"))
        textButtonPrimary(utf8ToUpper(loc("msgbox/btn_browse")), @() openMainSeasonScene(PASS_SCENE, BATTLE_PASS), { hplace = ALIGN_CENTER })
      ]
    })

  return res
}

let skinActionBtn = @() {
  watch = [selectedSkin, availableSkins, currentSkin, selectedSkinCfg, unitToShow,
    skinsInProgress, baseUnit, isOwnUnit, campMyUnits]
  size = [FLEX, defButtonHeight]
  halign = ALIGN_RIGHT
  valign = ALIGN_CENTER
  children = !isOwnUnit.get() || !selectedSkin.get() || unitToShow.get() == null
      ? null
    : skinsInProgress.get() ? spinner
    : selectedSkin.get() == "upgraded" && !baseUnit.get()?.isUpgraded
      ? mkGradText(loc("attrib_section/upgradeBattleRewards")).__update({ hplace = ALIGN_CENTER })
    : currentSkin.get() == selectedSkin.get() || selectedSkin.get() in availableSkins.get()
      ? selectBtns(baseUnit.get(), unitToShow.get().name, selectedSkin.get(), currentSkin.get())
    : selectedSkinCfg.get()?.currencyId != null && canChangeSkin(unitToShow.get(), campMyUnits.get())
      ? textButtonPricePurchase(
          utf8ToUpper(loc("mainmenu/btnBuy")),
          mkCurrencyComp(selectedSkinCfg.get()?.price, selectedSkinCfg.get()?.currencyId),
          onPurchase,
          { hplace = ALIGN_CENTER })
    : receiveSkinInfo(baseUnit.get().name, selectedSkin.get())
}

return {
  skinActionBtn
  skinsBlockNoTags
  skinsBlockWithTags
}
