from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/currenciesState.nut" import GOLD
from "%appGlobals/pServer/campaign.nut" import campConfigs, curCampaign
from "%appGlobals/pServer/pServerApi.nut" import buy_unit_research, unitInProgress, registerHandler
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/unitPresentation.nut" import getUnitName
from "%rGui/components/currencyComp.nut" import mkCurrencyComp
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/msgBox.nut" import mkCustomMsgBoxWnd, mkBtn
from "%rGui/components/spinner.nut" import spinner
from "%rGui/components/textButton.nut" import textButtonPricePurchase
from "%rGui/gameModes/newbieOfflineMissions.nut" import isFirstBattleRewardPart
from "%rGui/shop/bqPurchaseInfo.nut" import PURCH_SRC_UNIT_RESEARCH, PURCH_TYPE_UNIT_EXP, mkBqPurchaseInfo
from "%rGui/shop/msgBoxPurchase.nut" import showNoBalanceMsgIfNeed
from "%rGui/shop/msgQuestDesc.nut" import mkQuestDesc
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/tutorial/tutorialConst.nut" import TUTORIAL_UNITS_RESEARCH_ID
from "%rGui/tutorial/tutorialWnd/tutorialWndState.nut" import activeTutorialId
from "%rGui/unit/components/unitPlateComp.nut" import unitPlateWidth, unitPlateHeight
from "%rGui/unitsTree/animState.nut" import animUnitAfterResearch, animExpPart, animNewUnitsAfterResearch
from "%rGui/unitsTree/components/unitPlateNodeComp.nut" import mkTreeNodesUnitPlateSimple
from "%rGui/unitsTree/unitsTreeNodesState.nut" import unitsResearchStatus, visibleNodes
from "%rGui/unlocks/unlocks.nut" import spendingUnlocks


const WND_UID = "buyUnitResearchWnd"
let currencyIdByUnitCost = {
  costGold = "gold"
}

let unitName = mkWatched(persist, "unitName", null)
let unit = Computed(@() serverConfigs.get()?.allUnits[unitName.get()])
let unitExp = Computed(@() unitsResearchStatus.get()?[unitName.get()].exp ?? 0)
let unitReqExp = Computed(@() unitsResearchStatus.get()?[unitName.get()].reqExp ?? 1)
let unitResearchCfg = Computed(@() campConfigs.get()?.unitResearchLevels[unit.get()?.campaign][(unit.get()?.rank ?? 0) - 1])
let unitCurrencyId = Computed(@()
  currencyIdByUnitCost?[unitResearchCfg.get()?.keys().findvalue(@(v) v in currencyIdByUnitCost)] ?? "")
let needShowWnd = keepref(Computed(@() unitName.get() != null))
let hasFreeUnitResearchToBuy = Computed(@() activeTutorialId.get() == TUTORIAL_UNITS_RESEARCH_ID
  && isFirstBattleRewardPart.get())
let wndSize = [hdpx(1100), hdpx(700)]

let close = @() unitName.set(null)

function onClick(cost) {
  if (unitInProgress.get() != null)
    return
  let bqPurchaseInfo = mkBqPurchaseInfo(PURCH_SRC_UNIT_RESEARCH, PURCH_TYPE_UNIT_EXP, unitName.get())
  if (!showNoBalanceMsgIfNeed(cost, GOLD, bqPurchaseInfo, close)) {
    animExpPart.set(1.0 * unitExp.get() / unitReqExp.get())
    buy_unit_research(
      unitName.get(),
      curCampaign.get(),
      cost,
      (unitResearchCfg.get()?.nextLevelExp ?? 0) - unitExp.get(),
      {
        id = "buyUnitResearch",
        unitName = unitName.get()
      })
  }
}


registerHandler("buyUnitResearch", function(res, context) {
  if (res?.error == null) {
    animUnitAfterResearch.set(context.unitName)
    animNewUnitsAfterResearch.set(visibleNodes.get()
      ?.filter(@(n) n.reqUnits.contains(context.unitName) && (unitsResearchStatus.get()?[n.name].canResearch ?? false))
      .map(@(n) n.name) ?? {})
  }
  close()
})

function mkPrice() {
  let speedUpCost = Computed(function() {
    if (hasFreeUnitResearchToBuy.get())
      return 0
    let { costGold = 0, nextLevelExp = 0 } = unitResearchCfg.get()
    return nextLevelExp
        ? max(1, (min(1.0, (nextLevelExp - unitExp.get()).tofloat() / nextLevelExp) * costGold + 0.5).tointeger())
      : null
  })

  return @() {
    watch = [unitInProgress, speedUpCost, unitCurrencyId]
    key = "buy_unit_research_btn" 
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = speedUpCost.get() == null ? null
      : unitInProgress.get() != null ? spinner
      : textButtonPricePurchase(utf8ToUpper(loc("msgbox/btn_purchase")),
          mkCurrencyComp(speedUpCost.get() == 0 ? utf8ToUpper(loc("shop/free")) : speedUpCost.get(),
            unitCurrencyId.get()),
          @() onClick(speedUpCost.get() ?? 0))
  }
}

function mkContent() {
  let stateFlags = Watched(0)
  let country = Computed(@() unit.get()?.country ?? "")
  return @() {
    watch = stateFlags
    size = FLEX
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    margin = const [0, 0, hdpx(20), 0]
    gap = hdpx(30)
    children = [
      @() {
        watch = unitName
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        maxWidth = hdpx(700)
        color = 0xFFD8D8D8
        halign = ALIGN_CENTER
        text = loc("header/unitResearchComplete", { unitName = getUnitName(unitName.get() ?? "") })
      }.__update(fontTinyAccented)
      @() {
        watch = unit
        size = [unitPlateWidth, unitPlateHeight]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = unit.get() ? mkTreeNodesUnitPlateSimple(unit.get()) : null
      }
      @() {
        watch = [spendingUnlocks, unitCurrencyId, country]
        flow = FLOW_VERTICAL
        children = mkQuestDesc(unitCurrencyId.get(), spendingUnlocks.get(), country.get())
      }
    ]
    transform = { scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.98, 0.98] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]
  }
}

let openImpl = @() addModalWindow(bgShaded.__merge({
  key = WND_UID
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  onClick = close
  children = {
    halign = ALIGN_CENTER
    children = mkCustomMsgBoxWnd(loc("header/unitResearchSpeedUp"),
      mkContent(),
      [
        mkBtn({id = "cancel" isCancel = true, cb = close}, WND_UID),
        mkPrice()
      ],
      {size = wndSize})
  }
  animations = wndSwitchAnim
})
)

if (needShowWnd.get())
  openImpl()
needShowWnd.subscribe(@(v) v ? openImpl() : removeModalWindow(WND_UID))

return @(uName) unitName.set(uName)
