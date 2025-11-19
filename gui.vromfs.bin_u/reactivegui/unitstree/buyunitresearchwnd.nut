from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { campConfigs, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { buy_unit_research, unitInProgress, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { textButtonPricePurchase } = require("%rGui/components/textButton.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { spinner } = require("%rGui/components/spinner.nut")
let { showNoBalanceMsgIfNeed } = require("%rGui/shop/msgBoxPurchase.nut")
let { PURCH_SRC_UNIT_RESEARCH, PURCH_TYPE_UNIT_EXP, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { unitsResearchStatus, visibleNodes } = require("%rGui/unitsTree/unitsTreeNodesState.nut")
let { unitPlateWidth, unitPlateHeight } = require("%rGui/unit/components/unitPlateComp.nut")
let { mkTreeNodesUnitPlateSimple } = require("%rGui/unitsTree/components/unitPlateNodeComp.nut")
let { mkCustomMsgBoxWnd, mkBtn } = require("%rGui/components/msgBox.nut")
let { animUnitAfterResearch, animExpPart, animNewUnitsAfterResearch } = require("%rGui/unitsTree/animState.nut")

let WND_UID = "buyUnitResearchWnd"

let unitName = mkWatched(persist, "unitName", null)
let unit = Computed(@() serverConfigs.get()?.allUnits[unitName.get()])
let unitExp = Computed(@() unitsResearchStatus.get()?[unitName.get()].exp ?? 0)
let unitReqExp = Computed(@() unitsResearchStatus.get()?[unitName.get()].reqExp ?? 1)
let unitResearchCfg = Computed(@() campConfigs.get()?.unitResearchLevels[unit.get()?.campaign][(unit.get()?.rank ?? 0) - 1])
let needShowWnd = keepref(Computed(@() unitName.get() != null))
let wndSize = [hdpx(1000), hdpx(600)]

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

let function mkPrice() {
  let speedUpCost = Computed(function() {
    let { costGold = 0, nextLevelExp = 0 } = unitResearchCfg.get()
    return nextLevelExp
        ? max(1, (min(1.0, (nextLevelExp - unitExp.get()).tofloat() / nextLevelExp) * costGold + 0.5).tointeger())
      : null
  })

  return @() {
    watch = [unitInProgress, speedUpCost]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = speedUpCost.get() == null ? null
      : unitInProgress.get() != null ? spinner
      : textButtonPricePurchase(utf8ToUpper(loc("msgbox/btn_purchase")),
        mkCurrencyComp(speedUpCost.get(), "gold"), @() onClick(speedUpCost.get() ?? 0))
  }
}

function mkContent() {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size = flex()
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = hdpx(30)
    children = [
      @() {
        watch = unitName
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        maxWidth = hdpx(700)
        color = 0xFFD8D8D8
        halign = ALIGN_CENTER
        text = loc("header/unitResearchComplete", { unitName = loc(getUnitLocId(unitName.get() ?? "")) })
      }.__update(fontTinyAccented)
      @() {
        watch = unit
        size = [unitPlateWidth, unitPlateHeight]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = unit.get() ? mkTreeNodesUnitPlateSimple(unit.get()) : null
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
