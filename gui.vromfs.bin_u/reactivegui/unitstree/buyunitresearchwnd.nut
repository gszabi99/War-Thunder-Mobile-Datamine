from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { campConfigs, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { buy_unit_research, unitInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { textButtonPricePurchase } = require("%rGui/components/textButton.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { spinner } = require("%rGui/components/spinner.nut")
let { showNoBalanceMsgIfNeed } = require("%rGui/shop/msgBoxPurchase.nut")
let { PURCH_SRC_UNIT_RESEARCH, PURCH_TYPE_UNIT_EXP,PURCH_SRC_UNITS, PURCH_TYPE_UNIT, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { unitsResearchStatus } = require("unitsTreeNodesState.nut")
let { unitPlateWidth, unitPlateHeight } = require("%rGui/unit/components/unitPlateComp.nut")
let { mkTreeNodesUnitPlateSimple } = require("%rGui/unitsTree/components/unitPlateNodeComp.nut")
let { mkCustomMsgBoxWnd, mkBtn } = require("%rGui/components/msgBox.nut")
let purchaseUnit = require("%rGui/unit/purchaseUnit.nut")

let WND_UID = "buyUnitResearchWnd"

let unitName = mkWatched(persist, "unitName", null)
let unit = Computed(@() serverConfigs.get()?.allUnits[unitName.get()])
let unitExp = Computed(@() unitsResearchStatus.get()?[unitName.get()].exp ?? 0)
let unitResearchCfg = Computed(@() campConfigs.get()?.unitResearchLevels[unit.get()?.campaign][(unit.get()?.rank ?? 0) - 1])
let needShowWnd = keepref(Computed(@() unitName.get() != null))

let wndSize = [hdpx(1000), hdpx(600)]

let close = @() unitName.set(null)

function onClick() {
  if (unitInProgress.value != null)
    return
  let bqPurchaseInfo = mkBqPurchaseInfo(PURCH_SRC_UNIT_RESEARCH, PURCH_TYPE_UNIT_EXP, unitName.get())
  if (!showNoBalanceMsgIfNeed(unitResearchCfg.get()?.costGold, GOLD, bqPurchaseInfo, close)) {
    buy_unit_research(
      unitName.get(),
      curCampaign.get(),
      unitResearchCfg.get()?.costGold ?? 0,
      (unitResearchCfg.get()?.nextLevelExp ?? 0) - unitExp.get())
  }
}
unitsResearchStatus.subscribe(function(v){
  if (v?[unitName.get()].canBuy) {
    let bqPurchaseInfo = mkBqPurchaseInfo(PURCH_SRC_UNITS, PURCH_TYPE_UNIT, unitName.get())
    purchaseUnit(unitName.get(), bqPurchaseInfo)
    close()
  }
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
    children = unitInProgress.value != null ? spinner
      : textButtonPricePurchase(utf8ToUpper(loc("msgbox/btn_purchase")),
        mkCurrencyComp(speedUpCost.get(), "gold"), onClick)
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
    children = [
      @() {
        watch = unit
        size = [unitPlateWidth, unitPlateHeight]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = mkTreeNodesUnitPlateSimple(unit.get())
      }
    ]
    transform = { scale = (stateFlags.value & S_ACTIVE) != 0 ? [0.98, 0.98] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]
  }
}

let openImpl = @() addModalWindow(bgShaded.__merge({
  key = WND_UID
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  onClick = close
  children = @(){
    watch = unitName
    halign = ALIGN_CENTER
    children = mkCustomMsgBoxWnd(loc("header/unitResearchSpeedUp",
      { unitName = loc(getUnitLocId(unitName.get())) }),
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
