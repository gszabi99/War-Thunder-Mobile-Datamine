from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/skins/skinTags.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { round } = require("math")

let { buy_unit_skin, enable_unit_skin, skinsInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { getSkinPresentation } = require("%appGlobals/config/skinPresentation.nut")
let { getLootboxName } = require("%appGlobals/config/lootboxPresentation.nut")
let { getPlatoonOrUnitName } = require("%appGlobals/unitPresentation.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { orderByCurrency } = require("%appGlobals/currenciesState.nut")
let { G_SKIN, G_LOOTBOX } = require("%appGlobals/rewardType.nut")

let { unseenSkins, markAllUnitSkinsSeen, markSkinSeen } = require("%rGui/unitCustom/unitSkins/unseenSkins.nut")
let { PURCH_SRC_SKINS, PURCH_TYPE_SKIN, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { mkGradText, lockIcon, checkIcon, iconSize } =  require("%rGui/unitCustom/unitCustomComps.nut")
let { textButtonPrimary, textButtonPricePurchase } = require("%rGui/components/textButton.nut")
let { bpFreeRewardsUnlock, bpPaidRewardsUnlock, bpPurchasedUnlock, battlePassGoods
} = require("%rGui/battlePass/battlePassState.nut")
let { unitSkins, selectedSkin, currentSkin, availableSkins, selectedSkinCfg, hasTagsChoice
} = require("%rGui/unitCustom/unitSkins/unitSkinsState.nut")
let { openEventWnd, MAIN_EVENT_ID, getEventLoc, eventSeason, allSpecialEvents
} = require("%rGui/event/eventState.nut")
let { doubleSideGradient, doubleSideGradientPaddingX, doubleSideGradientPaddingY
} = require("%rGui/components/gradientDefComps.nut")
let { mkCurrencyComp, mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { openEventWndLootbox } = require("%rGui/shop/lootboxPreviewState.nut")
let changeSkinTagWnd = require("%rGui/unitCustom/unitSkins/changeSkinTagWnd.nut")
let { horizontalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { baseUnit, unitToShow, isOwnUnit } = require("%rGui/unitDetails/unitDetailsState.nut")
let { mkIsAutoSkin, mkSkinCustomTags } = require("%rGui/unit/unitSettings.nut")
let { sendAppsFlyerSavedEvent } = require("%rGui/notifications/logEvents.nut")
let { mkPriorityUnseenMarkWatch } = require("%rGui/components/unseenMark.nut")
let { userlogTextColor, markTextColor, selectColor, hoverColor } = require("%rGui/style/stdColors.nut")
let { findLootboxWithReward } = require("%rGui/rewards/lootboxesRewards.nut")
let { shopGoods, openShopWndByGoods } = require("%rGui/shop/shopState.nut")
let { findUnlockWithReward } = require("%rGui/rewards/unlockRewards.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { openGoodsPreview } = require("%rGui/shop/goodsPreviewState.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { eventLootboxesRaw } = require("%rGui/event/eventLootboxes.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { spinner } = require("%rGui/components/spinner.nut")
let listbox = require("%rGui/components/listbox.nut")
let { openPassScene, BATTLE_PASS } = require("%rGui/battlePass/passState.nut")


let appsFlyerSaveId = "DefaultSkinWasReplaced"
let SKINS_IN_ROW = 4
let SKINS_IN_ROW_TAGS = 3
let skinSize = hdpxi(110)
let skinBorderRadius = round(skinSize * 0.2).tointeger()
let skinGap = evenPx(20)
let tagNameSize = hdpx(210)
let skinsRowWidth = skinSize * SKINS_IN_ROW + skinGap * (SKINS_IN_ROW - 1)
let skinsRowWidthWithTags = (skinSize + skinGap) * SKINS_IN_ROW_TAGS + tagNameSize + doubleSideGradientPaddingX * 2
let rowHeight = skinSize + skinGap
let aTimeSelected = 0.2
let rowBgEvenColor = 0xD0000000
let rowBgOddColor = 0x70000000

function applyToPlatoon(unit, skinName) {
  if ((unit?.currentSkins[unit.name] ?? "") != skinName)
    enable_unit_skin(unit.name, unit.name, skinName)
  foreach (pu in unit.platoonUnits)
    if ((unit?.currentSkins[pu.name] ?? "") != skinName)
      enable_unit_skin(unit.name, pu.name, skinName)
  if (skinName != "")
    sendAppsFlyerSavedEvent("skin_equiped_1", appsFlyerSaveId)
}

let skinsPannable = horizontalPannableAreaCtor(skinsRowWidth + skinSize + saBorders[0], [skinSize, saBorders[0]])
let skinsPannableWithTags = horizontalPannableAreaCtor(
  (skinSize + skinGap) * SKINS_IN_ROW_TAGS + skinGap + saBorders[0], [2 * skinGap, saBorders[0]])

let mkTankRow = @(rowIdx, text, content, ovr = {}) {
  size = [skinsRowWidthWithTags, rowHeight]
  flow = FLOW_HORIZONTAL
  gap = skinGap
  children = [
    {
      size = [tagNameSize, flex()]
      valign = ALIGN_CENTER
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = text
    }.__update(fontSmall)
    content
  ]
}.__merge(doubleSideGradient,
  {
    padding = [skinGap / 2, doubleSideGradientPaddingX]
    color = rowIdx % 2 == 1 ? rowBgOddColor : rowBgEvenColor
  },
  ovr)

let mkInfoTextarea = @(text, ovr = {}) doubleSideGradient.__merge({
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    maxWidth = hdpx(400)
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    halign = ALIGN_CENTER
    text
  }.__update(fontTiny)
}.__update(ovr))

let calcAmountOfRewards = @(g) "rewards" in g
  ? g.rewards.len()
    
  : g.units.len() + g.unitUpgrades.len() + g.skins.len() + g.items.len() + g.decorators.len()

function findShopSkinGoods(unitName, skinName, allGoods) {
  local res = null
  foreach(g in allGoods) {
    if (g.isHidden)
      continue

    let { rewards = null, skins = {} } = g
    if (rewards != null) {
      if (null == rewards.findvalue(@(r) r.id == unitName && r.subId == skinName && r.gType == G_SKIN))
        continue
    }
    else if (skins?[unitName] != skinName)
      continue

    if (res == null || (calcAmountOfRewards(g) <= calcAmountOfRewards(res)))
      res = g
  }
  return res
}

function skinBtn(skinPresentation) {
  let stateFlags = Watched(0)
  let { name, image } = skinPresentation
  let isLocked = Computed(@() name not in availableSkins.get())
  let isSelected = Computed(@() name == selectedSkin.get())
  let currencyId = Computed(@() serverConfigs.get()?.skins[name][baseUnit.get()?.name].currencyId
    ?? findShopSkinGoods(baseUnit.get()?.name, name, shopGoods.get())?.price.currencyId)
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
        size = flex()
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#slot_border.svg:{skinSize}:{skinSize}:P")
        color = isSelected.get() ? selectColor : 0
        transitions = [{ prop = AnimProp.color, duration = aTimeSelected }]
      }
      @() {
        watch = stateFlags
        size = flex()
        rendObj = ROBJ_BOX
        image = Picture("ui/gameuiskin#hovermenu_shop_button_glow.avif")
        fillColor = stateFlags.get() & S_HOVER ? hoverColor : 0
        borderRadius = skinBorderRadius
        transitions = [{ prop = AnimProp.color, duration = aTimeSelected }]
        transform = { rotate = 180 }
      }
      @() {
        watch = [isLocked, currencyId]
        size = flex()
        halign = ALIGN_LEFT
        valign = ALIGN_BOTTOM
        flow = FLOW_HORIZONTAL
        children = !isLocked.get() ? null
          : !currencyId.get() ? lockIcon
          : mkCurrencyImage(currencyId.get(), iconSize, { vplace = ALIGN_BOTTOM, margin = hdpx(8) })
      }
      @() {
        watch = currentSkin
        size = flex()
        halign = ALIGN_LEFT
        valign = ALIGN_BOTTOM
        children = currentSkin.get() == name ? checkIcon : null
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
    valToString = @(v) loc(v ? "controls/on" : "controls/off")
    setValue = setAutoSkin
  }).__update({ vplace = ALIGN_CENTER })

  return mkTankRow(tankTagsOrder.len(), loc("skins/autoselect"), content,
    { size = [skinsRowWidthWithTags, SIZE_TO_CONTENT] })
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
    key = {}
    flow = FLOW_VERTICAL
    onDetach = @() markAllUnitSkinsSeen(baseUnit.get()?.name)
    children = tankTagsOrder
      .map(@(tag, idx)
        mkTankRow(idx, getTagName(tag),
          {
            size = flex()
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
  size = [skinsRowWidth + doubleSideGradientPaddingX * 2, skinSize + 2 * doubleSideGradientPaddingY]
  onDetach = @() markAllUnitSkinsSeen(baseUnit.get()?.name)
  children = skinsPannable(
    @() {
      watch = [unitSkins, unitToShow]
      flow = FLOW_HORIZONTAL
      gap = skinGap
      children = unitSkins.get()
        .keys()
        .map(@(v) getSkinPresentation(unitToShow.get()?.name ?? "", v).__merge({ name = v }))
        .map(skinBlock)
    })
}.__merge(doubleSideGradient)

function onPurchase() {
  if (selectedSkinCfg.get() == null)
    return

  let unitName = baseUnit.get().name
  let skinName = selectedSkin.get()
  let { currencyId, price } = selectedSkinCfg.get()
  let locSkinName = loc("skins/title", { unitName = getPlatoonOrUnitName(baseUnit.get(), loc) })

  openMsgBoxPurchase({
    text = loc("shop/needMoneyQuestion", { item = colorize(userlogTextColor, locSkinName) }),
    price = { currencyId, price },
    purchase = @() buy_unit_skin(unitName, skinName, currencyId, price),
    bqInfo = mkBqPurchaseInfo(PURCH_SRC_SKINS, PURCH_TYPE_SKIN, skinName)
  })
}

function chooseBetterGoods(g1, g2) {
  if ((g1.price.price > 0) != (g2.price.price > 0))
    return g1.price.price > 0 ? g1 : g2

  let currencyOrder = (orderByCurrency?[g1.price.currencyId] ?? 100) <=> (orderByCurrency?[g2.price.currencyId] ?? 100)
  if (currencyOrder != 0)
    return currencyOrder > 0 ? g2 : g1

  return g1.price.price < g2.price.price ? g1 : g2
}

function openLootboxForEvent(lootbox) {
  openEventWnd(lootbox?.meta.event_id ?? MAIN_EVENT_ID)
  openEventWndLootbox(lootbox.name)
}

function selectBtns(unit, vehicleName, skinName, cSkin) {
  if ("currentSkins" not in unit) 
    return null

  let showApplyToPlatoon = unit.platoonUnits.len() > 0
    && ((unit.currentSkins?[unit.name] ?? "") != skinName
      || unit.platoonUnits.findvalue(@(v) (unit.currentSkins?[v.name] ?? "") != skinName) != null)

  return {
    hplace = ALIGN_RIGHT
    padding = [0, saBorders[0], 0, 0]
    flow = FLOW_HORIZONTAL
    gap = hdpx(20)
    children = [
      !showApplyToPlatoon ? null
        : textButtonPrimary(utf8ToUpper(loc("skins/applyToPlatoon")), @() applyToPlatoon(unit, skinName))
      cSkin == skinName ? mkGradText(loc("skins/applied"))
        : textButtonPrimary(utf8ToUpper(loc("mainmenu/btnApply")),
            function() {
              enable_unit_skin(unit.name, vehicleName, skinName)
              if (skinName != "")
                sendAppsFlyerSavedEvent("skin_equiped_1", appsFlyerSaveId)
            },
            { hplace = ALIGN_CENTER })
    ]
  }
}

let receiveSkinInfo = @(unitName, skinName) function() {
  let res = {
    watch = [eventLootboxesRaw, serverConfigs, bpFreeRewardsUnlock, bpPaidRewardsUnlock, bpPurchasedUnlock, battlePassGoods, shopGoods]
    padding = [0, saBorders[0], 0, 0]
    hplace = ALIGN_RIGHT
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
  }

  let skinGoods = findShopSkinGoods(unitName, skinName, shopGoods.get())
  if (skinGoods != null)
    return res.__update({
      children = textButtonPricePurchase(
        utf8ToUpper(loc("mainmenu/btnBuy")),
        mkCurrencyComp(skinGoods?.price.price, skinGoods?.price.currencyId),
        @() openShopWndByGoods(skinGoods),
        { hplace = ALIGN_CENTER })
    })

  let goodsByLootboxId = {}
  foreach (goods in shopGoods.get()) {
    let { rewards = null, lootboxes = {} } = goods
    if (rewards != null) {
      foreach (r in rewards)
        if (r.gType == G_LOOTBOX)
          goodsByLootboxId[r.id] <- (r.id not in goodsByLootboxId) ? goods : chooseBetterGoods(goodsByLootboxId[r.id], goods)
    }
    else 
      foreach (id, _ in lootboxes)
        goodsByLootboxId[id] <- (id not in goodsByLootboxId) ? goods : chooseBetterGoods(goodsByLootboxId[id], goods)
  }

  let lootbox = findLootboxWithReward(goodsByLootboxId.keys().extend(eventLootboxesRaw.get().values()),
    serverConfigs.get(),
    @(r) (null != r.findvalue(@(g) g.gType == "skin" && g.id == unitName && g.subId == skinName)))

  let goods = goodsByLootboxId?[lootbox]
  let lootboxTbl = goods != null
    ? serverConfigs.get()?.lootboxesCfg[lootbox]
    : null
  if (lootboxTbl) {
    return res.__update({
      children = [
        @() mkInfoTextarea(loc("canReceive/inShopLootbox", { name = colorize(markTextColor, getLootboxName(lootboxTbl.name)) }))
        textButtonPrimary(utf8ToUpper(loc("msgbox/btn_browse")), @() openGoodsPreview(goods.id), { hplace = ALIGN_CENTER })
      ]
    })
  }

  if (lootbox != null) {
    let { event_id = MAIN_EVENT_ID } = lootbox?.meta
    return res.__update({
      children = [
        @() mkInfoTextarea(
          loc("canReceive/inEvent",
            { eventName = colorize(markTextColor, getEventLoc(event_id, eventSeason.get(), allSpecialEvents.get())) }),
          { watch = [eventSeason, allSpecialEvents] })
        textButtonPrimary(utf8ToUpper(loc("msgbox/btn_browse")), @() openLootboxForEvent(lootbox), { hplace = ALIGN_CENTER })
      ]
    })
  }

  let bpUnlock = findUnlockWithReward([bpFreeRewardsUnlock.get(), bpPaidRewardsUnlock.get(), bpPurchasedUnlock.get()],
    serverConfigs.get(),
    @(r) (null != r.findvalue(@(g) g.gType == G_SKIN && g.id == unitName && g.subId == skinName)))
  let isBpGoods = null != battlePassGoods.get()
    .findindex(@(v) v != null
      && (null != v?.rewards.findvalue(@(r) r.gType == G_SKIN && r.id == unitName && r.subId == skinName)
        || v?.skins[unitName] == skinName)) 

  if (bpUnlock != null || isBpGoods)
    return res.__update({
      children = [
        mkInfoTextarea(loc("canReceive/inBattlePass"))
        textButtonPrimary(utf8ToUpper(loc("msgbox/btn_browse")), @() openPassScene(BATTLE_PASS), { hplace = ALIGN_CENTER })
      ]
    })

  return res
}

let skinActionBtn = @() {
  watch = [selectedSkin, availableSkins, currentSkin, selectedSkinCfg, unitToShow, skinsInProgress, baseUnit, isOwnUnit]
  size = [flex(), defButtonHeight]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  animations = wndSwitchAnim
  children = !isOwnUnit.get() || !selectedSkin.get() || unitToShow.get() == null
      ? null
    : skinsInProgress.get() ? spinner
    : selectedSkin.get() == "upgraded" && !baseUnit.get()?.isUpgraded
      ? mkGradText(loc("attrib_section/upgradeBattleRewards"))
    : currentSkin.get() == selectedSkin.get() || selectedSkin.get() in availableSkins.get()
      ? selectBtns(baseUnit.get(), unitToShow.get().name, selectedSkin.get(), currentSkin.get())
    : selectedSkinCfg.get()?.currencyId != null
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
