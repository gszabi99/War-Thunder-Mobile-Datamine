from "%globalsDarg/darg_library.nut" import *
let { defer } = require("dagor.workcycle")
let { eventbus_send } = require("eventbus")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { G_ITEM } = require("%appGlobals/rewardType.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { shopGoods } = require("%rGui/shop/shopState.nut")
let { itemsCfgOrdered, orderByItems } = require("%appGlobals/itemsState.nut")
let { items, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { curSlots } = require("%appGlobals/pServer/slots.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { modalWndBg, modalWndHeader } = require("%rGui/components/modalWnd.nut")
let { textButtonBattle, mkCustomButton } = require("%rGui/components/textButton.nut")
let { defButtonHeight, PURCHASE } = require("%rGui/components/buttonStyles.nut")
let { shopPurchaseInProgress, buy_goods } = require("%appGlobals/pServer/pServerApi.nut")
let { mkCurrencyComp, CS_INCREASED_ICON } = require("%rGui/components/currencyComp.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { shopGoodsToRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { REWARD_STYLE_MEDIUM, mkRewardPlate } = require("%rGui/rewards/rewardPlateComp.nut")
let { showNoBalanceMsgIfNeed } = require("%rGui/shop/msgBoxPurchase.nut")
let { PURCH_SRC_HANGAR, PURCH_TYPE_CONSUMABLES, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { getPlatoonOrUnitName } = require("%appGlobals/unitPresentation.nut")
let { addCustomUnseenPurchHandler, removeCustomUnseenPurchHandler, markPurchasesSeen
} = require("%rGui/shop/unseenPurchasesState.nut")
let { balanceWp, balanceGold, balance } = require("%appGlobals/currenciesState.nut")
let { CS_COMMON, CS_NO_BALANCE } = require("%rGui/components/currencyStyles.nut")
let { wndSwitchAnim }= require("%rGui/style/stdAnimations.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { unitAttributes } = require("%rGui/attributes/unitAttr/unitAttrState.nut")
let { ceil, floor } = require("%sqstd/math.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { TIME_DAY_IN_SECONDS } = require("%sqstd/time.nut")
let { get_local_custom_settings_blk } = require("blkGetters")
let { debriefingData } = require("%rGui/debriefing/debriefingState.nut")
let { isOnlineSettingsAvailable } = require("%appGlobals/loginState.nut")
let { SGT_CONSUMABLES } = require("%rGui/shop/shopConst.nut")
let { isInSquad, isReady, isSquadLeader } = require("%appGlobals/squadState.nut")
let { markTextColor } = require("%rGui/style/stdColors.nut")
let { isItemAllowedForUnit } = require("%rGui/unit/unitItemAccess.nut")

let itemsGap = hdpx(50)

let itemBuyingWidth = hdpx(1000)
let titleWidth = hdpx(850)
let insideIndent = hdpxi(50)

let battleItemIconSize = hdpxi(105)
let arrowSize =  [hdpxi(80), hdpxi(60)]

let WND_UID = "itemWnd"
let close = @() removeModalWindow(WND_UID)

let defaultPurchaseDesc = "msg/purchaseDesc/toolKit"

let TIMERS_SHOWING_MISS_ITEMS = "timersShowingMissItemsWnd"

let spawnsByCampaign = {
  tanks_new = { maxSpawns = 3, maxSpawnsBySlot = 2 },
  tanks = { maxSpawns = 3, maxSpawnsBySlot = 2 },
  ships_new = { maxSpawns = 1, maxSpawnsBySlot = 1 },
  air = { maxSpawns = 8, maxSpawnsBySlot = 2 },
}

let defSpawnCfg = { maxSpawns = 1, maxSpawnsBySlot = 1 }

let itemShowCd = {
  spare = {
    hasBalance = TIME_DAY_IN_SECONDS
    noBalance = 7 * TIME_DAY_IN_SECONDS
  }
}

let battleItemsIcons = {
  ship_tool_kit = $"ui/gameuiskin#hud_consumable_repair.svg"
  ship_smoke_screen_system_mod = $"ui/gameuiskin#hud_consumable_smoke.svg"
  tank_tool_kit_expendable = $"ui/gameuiskin#hud_consumable_repair.svg"
  tank_medical_kit = $"ui/gameuiskin#hud_consumable_medicalkit.svg"
  tank_extinguisher = $"ui/gameuiskin#fire_indicator.svg"
  ircm_kit = "ui/gameuiskin#icon_ircm.avif"
}

let purchaseDesc = {
  ship_tool_kit = "msg/purchaseDesc/toolKit"
  tank_tool_kit_expendable = "msg/purchaseDesc/toolKit"
  tank_medical_kit = "msg/purchaseDesc/medicalKit"
  tank_extinguisher = "msg/purchaseDesc/extinguisher"
  ship_smoke_screen_system_mod = "msg/purchaseDesc/smoke"
  spare = "item/spare/desc"
  ircm_kit = "msg/purchaseDesc/ircmKit"
}

let titleWnd = @(unit, itemId){
  margin = const [hdpx(20), 0,0,0]
  size = [titleWidth, SIZE_TO_CONTENT]
  colorTable = {
    shipNameColor = 0x1052C4E4
  }
  halign = ALIGN_CENTER
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = unit ? loc($"header/notEnough/{itemId}", {unitName = getPlatoonOrUnitName(unit, loc)?? ""})
    : loc($"header/notEnough/common/{itemId}")
}.__update(fontMedium)

function getCheapestGoods(allGoods, isFit) {
  let byCurrency = {}
  foreach(goods in allGoods) {
    if (!isFit(goods))
      continue
    let { currencyId = "", price = 0 } = goods?.price
    if (price <= 0)
      continue
    let foundPrice = byCurrency?[currencyId].price.price
    if (foundPrice == null || foundPrice > price)
      byCurrency[currencyId] <- goods
  }
  return byCurrency?.wp ?? byCurrency.findvalue(@(_) true)
}

function shouldShowItem(name, hasBalance, timeWndShowing) {
  if (name not in itemShowCd)
    return true
  let timeInterval = itemShowCd?[name][hasBalance ? "hasBalance" : "noBalance"] ?? 0
  let lastTime = get_local_custom_settings_blk()?[TIMERS_SHOWING_MISS_ITEMS][name] ?? 0
  return timeWndShowing - lastTime > timeInterval
}

function getItemGoodsInfo(name, neededCount) {
  let goods = getCheapestGoods(shopGoods.get(),
    @(g) "rewards" in g ? g.rewards.len() == 1 && g.rewards[0].id == name && g.rewards[0].gType == G_ITEM
      : (g?.items[name] ?? 0) > 0 && g?.gtype == SGT_CONSUMABLES) 
  if (goods == null)
    return null
  let count = "rewards" in goods ? goods.rewards[0].count
    : goods.items[name] 
  let neededCountOfGoods = ceil(neededCount.tofloat() / count)
  let { price = 0, currencyId = "" } = goods?.price
  let totalPrice = price * neededCountOfGoods
  if (totalPrice <= 0)
    return null
  return { goods, price, currencyId, neededCountOfGoods, totalPrice }
}

function spareCalc(units, itemCfg, spawnCfg, hasItems, timeWndShowing) {
  if (spawnCfg.maxSpawns == 1)
    return null
  let {name, battleLimit} = itemCfg
  let spawnsBySpare = min(units.len(), (spawnCfg.maxSpawns / spawnCfg.maxSpawnsBySlot).tointeger())
  if (spawnsBySpare < hasItems)
    return null
  let itemGoodsInfo = getItemGoodsInfo(name, spawnsBySpare - hasItems)

  if (!itemGoodsInfo
      || !shouldShowItem(name, itemGoodsInfo.totalPrice <= (balance.get()?[itemGoodsInfo.currencyId] ?? 0), timeWndShowing))
    return null

  return {
    itemId = name,
    reqItems = spawnsBySpare,
    hasItems,
    goods = itemGoodsInfo.goods,
    hasUsing = hasItems / spawnsBySpare,
    limitItems = battleLimit,
    price = itemGoodsInfo.price,
    currencyId = itemGoodsInfo.currencyId,
    neededCountOfGoods = itemGoodsInfo.neededCountOfGoods,
    totalPrice = itemGoodsInfo.totalPrice
  }
}

let missingItemByType = {
  spare = spareCalc
}


let mkMissingItemsComp = @(units, spawnCfg, timeWndShowing) Computed(function() {
  let res = []
  foreach (cfg in itemsCfgOrdered.get()) {
    let { battleLimit = 0, itemsPerUse = 0, name = "" } = cfg
    let hasItems = items.get()?[name].count ?? 0

    if (name in missingItemByType) {
      let item = missingItemByType[name](units, cfg, spawnCfg, hasItems, timeWndShowing)
      if (item)
        res.append(item)
      continue
    }

    let { itemsByAttributes = [], itemsByModifications = [] } = serverConfigs.get()
    if (battleLimit <= 0)
      continue
    let unitUsingItemsRaw = []
    foreach(unit in units) {
      if (!isItemAllowedForUnit(name, unit.name))
        continue
      local limitItems = battleLimit
      let attributes = itemsByAttributes.filter(@(item) item.item == name)
      let attrByModifications = itemsByModifications.filter(@(item) item.item == name)
      foreach(attr in attributes) {
        let curLevel = unitAttributes.get()?[attr?.category][attr?.attribute]
          ?? curSlots.get().findvalue(@(s) s.name == unit.name)?.attrLevels[attr?.category][attr?.attribute]
          ?? 0
        limitItems += attr?.battleLimitAdd?[curLevel - 1] ?? 0
      }
      foreach(attr in attrByModifications)
        if (unit?.mods[attr?.mod])
          limitItems *= attr?.battleLimitMul ?? 1
      let unitItemsPerUse = unit?.itemsPerUse ?? 0
      let perUse = itemsPerUse <= 0 ? unitItemsPerUse : itemsPerUse
      let reqItems = perUse * limitItems
      unitUsingItemsRaw.resize(unitUsingItemsRaw.len() + spawnCfg.maxSpawnsBySlot,
        {reqItems, perUse, limitItems, name, u = unit.name})
    }

    local hasItemsTmp = hasItems

    let {reqItems, limitItems, hasUsing} = unitUsingItemsRaw.sort(@(a,b) b.reqItems <=> a.reqItems)
      .slice(0, spawnCfg.maxSpawns)
      .reduce(function(prev, cur) {
        let hasUsingTotal = prev.notEnough ? 0 : min(floor(hasItemsTmp/(cur.perUse == 0 ? 1 : cur.perUse)), cur.limitItems)
        hasItemsTmp -= hasUsingTotal * cur.perUse
        return {
        reqItems = prev.reqItems + cur.reqItems,
        limitItems = prev.limitItems + cur.limitItems,
        hasUsing = hasUsingTotal + prev.hasUsing
        notEnough = hasUsingTotal < cur.limitItems
      }}, { reqItems = 0, limitItems = 0, hasUsing = 0, notEnough = false })

    if (reqItems <= hasItems)
      continue

    let itemGoodsInfo = getItemGoodsInfo(name, reqItems - hasItems)
    if (!itemGoodsInfo)
      continue
    res.append({
      itemId = name,
      reqItems,
      hasItems,
      goods = itemGoodsInfo.goods,
      hasUsing,
      limitItems,
      price = itemGoodsInfo.price,
      currencyId = itemGoodsInfo.currencyId,
      neededCountOfGoods = itemGoodsInfo.neededCountOfGoods,
      totalPrice = itemGoodsInfo.totalPrice})
  }
  return res
})


function mkItemsRewards(item) {
  let { goods, neededCountOfGoods } = item
  let list = []
  if ("rewards" in goods) {
    foreach (r in goods.rewards)
      if (r.gType == G_ITEM)
        list.append(r.__merge({ count = r.count * neededCountOfGoods, order = orderByItems?[r.id] ?? orderByItems.len() }))
  }
  else 
    foreach (itemId, count in goods.items)
      if (count > 0)
        list.append({
          id = itemId,
          count = count * neededCountOfGoods,
          order = orderByItems?[itemId] ?? orderByItems.len()
        })
  if (list.len() == 0)
    return null
  list.sort(@(a, b) a.order <=> b.order)
  return {
    flow = FLOW_HORIZONTAL
    gap = itemsGap
    children = list.map(@(i) mkCurrencyComp(i.count, i.id, CS_INCREASED_ICON))
  }
}

function saveTimeShowingWnd(itemId){
  if (itemId in itemShowCd && isOnlineSettingsAvailable.get()){
    let sBlk = get_local_custom_settings_blk()
    let blk = sBlk.addBlock(TIMERS_SHOWING_MISS_ITEMS)
    blk[itemId] = serverTime.get()
    eventbus_send("saveProfile", {})
  }
}

function mkPurchaseBtn(item, toBattle) {
  let { goods, itemId, neededCountOfGoods, totalPrice } = item
  let { currencyId } = goods.price
  let userBalance = currencyId == "wp" ? balanceWp : balanceGold
  let textStyle = userBalance.get() < totalPrice ? CS_NO_BALANCE : CS_COMMON
  return [
      textButtonBattle(utf8ToUpper(loc(isInSquad.get() && !isReady.get() && !isSquadLeader.get() ? "mainmenu/btnReady" : "mainmenu/toBattle/short")),
        function() {
          saveTimeShowingWnd(itemId)
          close()
          toBattle()
      })
    mkCustomButton(mkCurrencyComp(totalPrice, currencyId, textStyle),
      function() {
        saveTimeShowingWnd(itemId)
        let bqPurchaseInfo = mkBqPurchaseInfo(PURCH_SRC_HANGAR, PURCH_TYPE_CONSUMABLES, goods.id)
        if (!showNoBalanceMsgIfNeed(totalPrice, currencyId, bqPurchaseInfo, close))
          buy_goods(goods.id, currencyId, totalPrice, neededCountOfGoods)
    }, PURCHASE)
  ]
}

let mkMsButtons = @(item, toBattle)
  mkSpinnerHideBlock(Computed(@() shopPurchaseInProgress.get() != null),
    mkPurchaseBtn(item, toBattle),
    {
      size = [SIZE_TO_CONTENT, defButtonHeight]
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      gap = hdpx(130)
    })

let countText = @(count){
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  colorTable = {
    mark = 0xFFFF0000
  }
  text = count
}.__update(fontTiny)

let mkItemPlate = @(itemId, count, ovr = {})
  mkRewardPlate(shopGoodsToRewardsViewInfo({ items = { [itemId] = count } })[0], REWARD_STYLE_MEDIUM, ovr)


let mkSimpleContent = @(item){
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    mkItemPlate(item.itemId, item.hasItems, { margin = [insideIndent*2, 0]})
    {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      size = const [hdpx(700), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      colorTable = {
        mark = 0xFFFF0000
      }
      text = loc(purchaseDesc?[item?.itemId] ?? defaultPurchaseDesc)
    }.__update(fontTiny)
    @() {
      pos = [hdpx(250), 0]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      children = mkItemsRewards(item)
    }
  ]
}

let mkContWithTransfToSkill = @(item) {
  flow = FLOW_VERTICAL
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    {
      pos = [-hdpx(35), 0]
      size = SIZE_TO_CONTENT
      flow = FLOW_HORIZONTAL
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      padding = [ insideIndent, 0 ]
      children = [
        mkItemPlate(item.itemId, item.hasItems)
        {
          margin = const [0, hdpx(25)]
          size = arrowSize
          valign = ALIGN_CENTER
          rendObj = ROBJ_IMAGE
          image = Picture($"ui/gameuiskin#arrow_icon.svg:{arrowSize[0]}:{arrowSize[1]}:P")
        }
        {
          size = [battleItemIconSize, battleItemIconSize]
          rendObj = ROBJ_BOX
          color = 0xFFFFFFFF
          borderColor = 0xFFFFFFFF
          borderWidth = 2
          flow = FLOW_VERTICAL
          children = [
            {
              rendObj = ROBJ_IMAGE
              keepAspect = true
              size = [battleItemIconSize, battleItemIconSize]
              image = Picture($"{battleItemsIcons[item.itemId]}:{battleItemIconSize}:{battleItemIconSize}:P")
            }
            @() {
              size = const [flex(), hdpx(30)]
              vplace = ALIGN_BOTTOM
              valign = ALIGN_CENTER
              halign = ALIGN_CENTER
              flow = FLOW_HORIZONTAL
              gap = hdpx(5)
              children = countText($"<color=@mark>{item.hasUsing}</color>/{item.limitItems}")
            }
          ]
        }
      ]
    }
    {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      size = const [hdpx(700), SIZE_TO_CONTENT]
      margin = const [0,0,hdpx(30),0]
      halign = ALIGN_CENTER
      colorTable = {
        mark = markTextColor
      }
      text = loc(purchaseDesc?[item?.itemId] ?? defaultPurchaseDesc)
    }.__update(fontTiny)
    @() {
      pos = [hdpx(250), 0]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      children = mkItemsRewards(item)
    }
  ]
}

let mkMsgContent = @(item, needSwitchAnim, toBattle, unit) modalWndBg.__merge({
  key = item.itemId
  size = FLEX_H
  padding = [0, 0, insideIndent, 0]
  flow = FLOW_VERTICAL
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    modalWndHeader(loc("missingItemsWnd/header"))
    titleWnd(unit, item.itemId)
    item.itemId in battleItemsIcons ? mkContWithTransfToSkill(item) : mkSimpleContent(item)
    mkMsButtons(item, toBattle)
  ]
  transform = {}
  animations = [
    { prop = AnimProp.translate, from = [0, 0], to = [hdpx(100), 0],
      duration = 0.5, easing = CosineFull, playFadeOut = true}
    { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.5
       easing = OutQuad, play = needSwitchAnim}
    { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.3,
      easing = OutQuad, playFadeOut = true}
  ]
})

let isPurchNoNeedResultWindow = @(purch) purch?.source == "purchaseInternal"
  && null == purch.goods.findvalue(@(g) g.gType != "item" && g.gType != "currency" && g.gType != "premium")
let markPurchasesSeenDelayed = @(purchList) defer(@() markPurchasesSeen(purchList.keys()))


function itemsPurchaseMessage(missItems, toBattle, unit, onClose) {
  let itemToShow = Computed(@() missItems.get()?[0])
  function content(){
    local needSwitchAnim = false
    return {
      watch = [itemToShow, missItems]
      size = FLEX_H
      function onAttach() {
        needSwitchAnim = true
      }
      children = itemToShow.get() == null ? null
        : mkMsgContent(itemToShow.get(), needSwitchAnim, toBattle, unit)
    }
  }
  addModalWindow(bgShaded.__merge({
    key = WND_UID
    function onClick() {
      if (itemToShow.get() != null)
        saveTimeShowingWnd(itemToShow.get().itemId)
      onClose()
      close()
    }
    onAttach = @() addCustomUnseenPurchHandler(isPurchNoNeedResultWindow, markPurchasesSeenDelayed)
    onDetach = @() removeCustomUnseenPurchHandler(markPurchasesSeenDelayed)
    size = flex()
    children = {
      flow = FLOW_VERTICAL
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      size = [ itemBuyingWidth, SIZE_TO_CONTENT ]
      children = content
    }
    animations = wndSwitchAnim
  }))
}

debriefingData.subscribe(function(_data) {
  let { itemsUsed = {} } = debriefingData.get()
  if (isOnlineSettingsAvailable.get()){
    let sBlk = get_local_custom_settings_blk()
    let blk = sBlk.addBlock(TIMERS_SHOWING_MISS_ITEMS)
    local hasChanges = false
    foreach(item, _ in itemsUsed){
      if ((blk?[item] ?? 0) != 0) {
        blk[item] = 0
        hasChanges = true
      }
    }
    if (hasChanges)
      eventbus_send("saveProfile", {})
  }
})

function offerMissingUnitItemsMessage(units, toBattle, spawnCfg = null, onClose = @() null) {
  if (units == null || units.len() == 0) {
    toBattle()
    return
  }

  let missItems = mkMissingItemsComp(
    units,
    spawnCfg ?? spawnsByCampaign?[curCampaign.get()] ?? defSpawnCfg,
    serverTime.get())


  if (missItems.get().len() == 0) {
    toBattle()
    return
  }
  missItems.subscribe(@(v) v.len() == 0 ? close() : null)
  itemsPurchaseMessage(missItems, toBattle, units.len() == 1 ? units[0] : null, onClose)
}


return offerMissingUnitItemsMessage