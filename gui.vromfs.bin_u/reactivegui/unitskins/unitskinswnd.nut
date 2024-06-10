from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/skins/skinTags.nut" import *
let { HangarCameraControl } = require("wt.behaviors")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { registerScene } = require("%rGui/navState.nut")
let { closeUnitSkins, unitSkinsOpenCount, unitSkins, selectedSkin, currentSkin,
availableSkins, selectedSkinCfg } = require("unitSkinsState.nut")
let { gamercardHeight, mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { GOLD, orderByCurrency } = require("%appGlobals/currenciesState.nut")
let { getUnitPresentation, getPlatoonOrUnitName } = require("%appGlobals/unitPresentation.nut")
let { unitPlateWidth, unitPlateHeight, unitPlatesGap, mkUnitRank
  mkUnitBg, mkUnitSelectedGlow, mkUnitImage, mkUnitTexts, mkUnitSlotLockedLine, mkUnitSelectedUnderlineVert
} = require("%rGui/unit/components/unitPlateComp.nut")
let { curSelectedUnitId, baseUnit, platoonUnitsList, unitToShow, isSkinsWndAttached
} = require("%rGui/unitDetails/unitDetailsState.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { shopGoods } = require("%rGui/shop/shopState.nut")
let { openGoodsPreview } = require("%rGui/shop/goodsPreviewState.nut")
let { getLootboxName } = require("%rGui/unlocks/rewardsView/lootboxPresentation.nut")
let { doubleSideGradient, doubleSideGradientPaddingX, doubleSideGradientPaddingY
} = require("%rGui/components/gradientDefComps.nut")
let { textButtonPrimary, textButtonPricePurchase } = require("%rGui/components/textButton.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { mkCurrencyComp, mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let listbox = require("%rGui/components/listbox.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { mkGradText, lockIcon, checkIcon, iconSize } =  require("unitSkinsComps.nut")
let { getSkinPresentation } = require("%appGlobals/config/skinPresentation.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { userlogTextColor, markTextColor } = require("%rGui/style/stdColors.nut")
let { PURCH_SRC_SKINS, PURCH_TYPE_SKIN, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { buy_unit_skin, enable_unit_skin, skinsInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { spinner } = require("%rGui/components/spinner.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { mkIsAutoSkin, mkSkinCustomTags } = require("%rGui/unit/unitSettings.nut")
let { unseenSkins, markAllUnitSkinsSeen, markSkinSeen } = require("unseenSkins.nut")
let { mkPriorityUnseenMarkWatch } = require("%rGui/components/unseenMark.nut")
let { eventLootboxesRaw } = require("%rGui/event/eventLootboxes.nut")
let { findLootboxWithReward } = require("%rGui/rewards/lootboxesRewards.nut")
let { openEmbeddedLootboxPreview } = require("%rGui/shop/lootboxPreviewState.nut")
let { openEventWnd, MAIN_EVENT_ID, getEventLoc, eventSeason, specialEvents } = require("%rGui/event/eventState.nut")
let { findUnlockWithReward } = require("%rGui/rewards/unlockRewards.nut")
let { bpFreeRewardsUnlock, bpPaidRewardsUnlock, bpPurchasedUnlock, openBattlePassWnd, battlePassGoods
} = require("%rGui/battlePass/battlePassState.nut")
let changeSkinTagWnd = require("changeSkinTagWnd.nut")
let { horizontalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")


let SKINS_IN_ROW = 4
let SKINS_IN_ROW_TAGS = 3
let skinSize = hdpxi(110)
let skinGap = evenPx(20)
let tagNameSize = hdpx(210)
let skinsRowWidth = skinSize * SKINS_IN_ROW + skinGap * (SKINS_IN_ROW - 1)
let skinsRowWidthWithTags = (skinSize + skinGap) * SKINS_IN_ROW_TAGS + tagNameSize + doubleSideGradientPaddingX * 2
let rowHeight = skinSize + skinGap
let aTimeSelected = 0.2
let selectedColor = 0x8052C4E4
let rowBgEvenColor = 0xD0000000
let rowBgOddColor = 0x70000000


let hasTagsChoice = Computed(@() curCampaign.get() == "tanks")

let function applyToPlatoon(unit, skinName) {
  if ((unit?.currentSkins[unit.name] ?? "") != skinName)
    enable_unit_skin(unit.name, unit.name, skinName)
  foreach (pu in unit.platoonUnits)
    if ((unit?.currentSkins[pu.name] ?? "") != skinName)
      enable_unit_skin(unit.name, pu.name, skinName)
}

let skinsPannable = horizontalPannableAreaCtor(skinsRowWidth + skinSize + saBorders[0], [skinSize, saBorders[0]])
let skinsPannableWithTags = horizontalPannableAreaCtor(
  (skinSize + skinGap) * SKINS_IN_ROW_TAGS + skinGap + saBorders[0], [2 * skinGap, saBorders[0]])

function mkUnitPlate(unit, platoonUnit, onClick) {
  let p = getUnitPresentation(platoonUnit)
  let platoonUnitFull = unit.__merge(platoonUnit)
  let isPremium = !!(unit?.isPremium || unit?.isUpgraded)
  let isSelected = Computed(@() unitToShow.get()?.name == platoonUnit.name)
  let isLocked = Computed(@() !isPremium && platoonUnit.reqLevel > (myUnits.get()?[unit.name].level ?? 0))

  return @() {
    watch = isLocked
    behavior = Behaviors.Button
    onClick
    sound = { click  = "choose" }
    flow = FLOW_HORIZONTAL
    children = [
      mkUnitSelectedUnderlineVert(unit, isSelected)
      {
        size = [unitPlateWidth, unitPlateHeight]
        children = [
          mkUnitBg(unit, isLocked.get())
          mkUnitSelectedGlow(unit, isSelected)
          mkUnitImage(platoonUnitFull, isLocked.get())
          mkUnitTexts(platoonUnitFull, loc(p.locId), isLocked.get())
          !isLocked.get() ? mkUnitRank(unit, { pos = [-hdpx(30), 0] }) : null
          mkUnitSlotLockedLine(platoonUnit, isLocked.get())
        ]
      }
    ]
  }
}

function platoonUnitsBlock() {
  let res = { watch = [ baseUnit, platoonUnitsList ] }
  return platoonUnitsList.get().len() == 0
      ? res
    : res.__update({
        flow = FLOW_VERTICAL
        gap = unitPlatesGap
        children = platoonUnitsList.get()
          .map(@(pu) mkUnitPlate(baseUnit.get(), pu, @() curSelectedUnitId(pu.name)))
      })
}

function onPurchase() {
  let unitName = baseUnit.get().name
  let skinName = selectedSkin.get()
  let skinCfg = selectedSkinCfg.get()
  let currencyId = selectedSkinCfg.get()?.currencyId
  let price = selectedSkinCfg.get()?.price
  openMsgBoxPurchase(
    loc("shop/needMoneyQuestion", { item = colorize(userlogTextColor, loc("skins")) }),
    skinCfg,
    @() buy_unit_skin(unitName, skinName, currencyId, price),
    mkBqPurchaseInfo(PURCH_SRC_SKINS, PURCH_TYPE_SKIN, skinName))
}

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

function openLootboxForEvent(lootbox) {
  openEventWnd(lootbox?.meta.event_id ?? MAIN_EVENT_ID)
  openEmbeddedLootboxPreview(lootbox.name)
}

function chooseBetterGoods(g1, g2) {
  if ((g1.price.price > 0) != (g2.price.price > 0))
    return g1.price.price > 0 ? g1 : g2
  let currencyOrder = (orderByCurrency?[g1.price.currencyId] ?? 100) <=> (orderByCurrency?[g2.price.currencyId] ?? 100)
  if (currencyOrder != 0)
    return currencyOrder > 0 ? g2 : g1
  return g1.price.price < g2.price.price ? g1 : g2
}

let receiveSkinInfo = @(unitName, skinName) function() {
  let res = {
    watch = [eventLootboxesRaw, serverConfigs, bpFreeRewardsUnlock, bpPaidRewardsUnlock, bpPurchasedUnlock, battlePassGoods, shopGoods]
    padding = [0, saBorders[0], 0, 0]
    hplace = ALIGN_RIGHT
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
  }

  let goodsByLootboxId = {}
  foreach(goods in shopGoods.get())
    foreach(id, _ in goods.lootboxes)
      goodsByLootboxId[id] <- (id not in goodsByLootboxId) ? goods : chooseBetterGoods(goodsByLootboxId[id], goods)

  let lootbox = findLootboxWithReward(goodsByLootboxId.keys().extend(eventLootboxesRaw.get().values()),
    serverConfigs.get(),
    @(r) type(r) == "table" ? r.skins?[unitName] == skinName //compatibility with 2024.04.14
      : (null != r.findvalue(@(g) g.gType == "skin" && g.id == unitName && g.subId == skinName)))

  let goods = goodsByLootboxId?[lootbox]
  if (goods != null) {
    let lootboxTbl = serverConfigs.get().lootboxesCfg[lootbox]
    return res.__update({
      children = [
        @() mkInfoTextarea(loc("canReceive/inShopLootbox",
          { name = colorize(markTextColor, getLootboxName(lootboxTbl.name, lootboxTbl?.meta.event)) }))
        textButtonPrimary(
          utf8ToUpper(loc("msgbox/btn_browse")),
          @() openGoodsPreview(goods.id),
          { hplace = ALIGN_CENTER })
      ]
    })
  }

  if (lootbox != null) {
    let { event_id = MAIN_EVENT_ID } = lootbox?.meta
    return res.__update({
      children = [
        @() mkInfoTextarea(
          loc("canReceive/inEvent",
            { eventName = colorize(markTextColor, getEventLoc(event_id, eventSeason.get(), specialEvents.get())) }),
          { watch = [ eventSeason, specialEvents ] })
        textButtonPrimary(
          utf8ToUpper(loc("msgbox/btn_browse")),
          @() openLootboxForEvent(lootbox),
          { hplace = ALIGN_CENTER })
      ]
    })
  }

  let bpUnlock = findUnlockWithReward([bpFreeRewardsUnlock.get(), bpPaidRewardsUnlock.get(), bpPurchasedUnlock.get()],
    serverConfigs.get(),
    @(r) type(r) == "table" ? r.skins?[unitName] == skinName //compatibility with 2024.04.14
      : (null != r.findvalue(@(g) g.gType == "skin" && g.id == unitName && g.subId == skinName)))
  let isBpGoods = battlePassGoods.get().findindex(@(v) v != null && v.skins?[unitName] == skinName) != null

  if (bpUnlock != null || isBpGoods)
    return res.__update({
      children = [
        mkInfoTextarea(loc("canReceive/inBattlePass"))
        textButtonPrimary(
          utf8ToUpper(loc("msgbox/btn_browse")),
          openBattlePassWnd,
          { hplace = ALIGN_CENTER })
      ]
    })

  return res
}

let function selectBtns(unit, vehicleName, skinName, cSkin) {
  if ("currentSkins" not in unit) //not own unit
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
        : textButtonPrimary(
            utf8ToUpper(loc("skins/applyToPlatoon")),
            @() applyToPlatoon(unit, skinName))
      cSkin == skinName ? mkGradText(loc("skins/applied"))
        : textButtonPrimary(
            utf8ToUpper(loc("mainmenu/btnApply")),
            @() enable_unit_skin(unit.name, vehicleName, skinName),
            { hplace = ALIGN_CENTER })
    ]
  }
}

let actionBtn = @() {
  watch = [selectedSkin, availableSkins, currentSkin, selectedSkinCfg, myUnits, unitToShow, skinsInProgress, baseUnit]
  size = [flex(), defButtonHeight]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  animations = wndSwitchAnim
  children = !selectedSkin.get() || baseUnit.get()?.name not in myUnits.get() || unitToShow.get() == null
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

let function skinBtn(skinPresentation) {
  let stateFlags = Watched(0)
  let { name, image } = skinPresentation
  let isLocked = Computed(@() name not in availableSkins.get())
  let isSelected = Computed(@() name == selectedSkin.get())
  let currencyId = Computed(@() serverConfigs.get()?.skins[name][baseUnit.get()?.name].currencyId)
  let canChangeTags = Computed(@() hasTagsChoice.get() && isSelected.get() && !isLocked.get())
  return @() {
    watch = stateFlags
    rendObj = ROBJ_MASK
    image = Picture($"ui/gameuiskin#slot_mask.svg:{skinSize}:{skinSize}:P")
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags(sf)
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
        watch = isLocked
        size = [skinSize, skinSize]
        rendObj = ROBJ_IMAGE
        color = isLocked.get() ? 0xFF909090 : 0xFFFFFFFF
        image = Picture($"ui/gameuiskin#{image}:{skinSize}:{skinSize}:P")
      }
      @() {
        watch = isSelected
        size = flex()
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#slot_border.svg:{skinSize}:{skinSize}:P")
        color = isSelected.get() ? selectedColor : 0
        transitions = [{ prop = AnimProp.color, duration = aTimeSelected }]
      }
      @() {
        watch = stateFlags
        size = flex()
        rendObj = ROBJ_IMAGE
        image = Picture("ui/gameuiskin#hovermenu_shop_button_glow.avif")
        color = stateFlags.get() & S_HOVER ? selectedColor : 0
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
            size = [iconSize, iconSize]
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

let function autoSkinRow() {
  let { isAutoSkin, setAutoSkin } = mkIsAutoSkin(Computed(@() baseUnit.get()?.name))
  let content = listbox({
    value = isAutoSkin
    list = [false, true]
    valToString = @(v) loc(v ? "controls/on" : "controls/off")
    setValue = setAutoSkin
  })
    .__update({ vplace = ALIGN_CENTER })
  return mkTankRow(tankTagsOrder.len(), loc("skins/autoselect"),
    content,
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

let unitSkinsGamercard = {
  size = [flex(), gamercardHeight]
  padding = saBordersRv
  flow = FLOW_HORIZONTAL
  children = [
    doubleSideGradient.__merge({
      size = [SIZE_TO_CONTENT, gamercardHeight]
      padding = [doubleSideGradientPaddingY, doubleSideGradientPaddingX, doubleSideGradientPaddingY, 0]
      valign = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      gap = hdpx(50)
      children = [
        backButton(closeUnitSkins)
        {
          flow = FLOW_VERTICAL
          gap = hdpx(10)
          children = [
            {
              rendObj = ROBJ_TEXT
              text = loc("skins/header")
            }.__update(fontSmall)
            @() {
              watch = baseUnit
              rendObj = ROBJ_TEXT
              text = getPlatoonOrUnitName(baseUnit.get(), loc)
            }.__update(fontSmall)
          ]
        }
      ]
    })
    { size = flex() }
    mkCurrenciesBtns([GOLD])
  ]
}

let unitSkinsWnd = {
  key = {}
  size = flex()
  behavior = HangarCameraControl
  flow = FLOW_VERTICAL
  onAttach = @() isSkinsWndAttached.set(true)
  onDetach = @() isSkinsWndAttached.set(false)
  children = [
    unitSkinsGamercard
    {
      size = flex()
      valign = ALIGN_BOTTOM
      padding = saBordersRv
      children = [
        platoonUnitsBlock
        @() {
          watch = [hasTagsChoice, unitToShow]
          hplace = ALIGN_RIGHT
          pos = [doubleSideGradientPaddingX, 0] //all content is in gradient blocks
          flow = FLOW_VERTICAL
          gap = hdpx(50)
          children = !unitToShow.get() ? null
            : [
                hasTagsChoice.get() ? skinsBlockWithTags : skinsBlockNoTags
                actionBtn
              ]
        }
      ]
    }
  ]
  animations = wndSwitchAnim
}

registerScene("unitSkinsWnd", unitSkinsWnd, closeUnitSkins, unitSkinsOpenCount)
