from "%globalsDarg/darg_library.nut" import *
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { msgBoxBg, msgBoxHeaderWithClose } = require("%rGui/components/msgBox.nut")
let { campConfigs, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { buy_unit_research, unitInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { buttonsHGap } = require("%rGui/components/textButton.nut")
let { mkColoredGradientY } = require("%rGui/style/gradients.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { spinner } = require("%rGui/components/spinner.nut")
let { showNoBalanceMsgIfNeed } = require("%rGui/shop/msgBoxPurchase.nut")
let { PURCH_SRC_UNIT_RESEARCH, PURCH_TYPE_UNIT_EXP, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { unitsResearchStatus } = require("unitsTreeNodesState.nut")
let { mkUnitImage, unitPlateWidth, unitPlateHeight } = require("%rGui/unit/components/unitPlateComp.nut")


let WND_UID = "buyUnitResearchWnd"
let priceBgGradient = mkColoredGradientY(0xFF00AAF8, 0xFF007683, 12)
let priceBgBorder = 0x7F003570
let blockSize = [hdpx(500), hdpx(200)]

let unitName = mkWatched(persist, "unitName", null)
let unit = Computed(@() serverConfigs.get()?.allUnits[unitName.get()])
let unitExp = Computed(@() unitsResearchStatus.get()?[unitName.get()].exp ?? 0)
let unitResearchCfg = Computed(@() campConfigs.get()?.unitResearchLevels[unit.get()?.campaign][(unit.get()?.rank ?? 0) - 1])
let needShowWnd = keepref(Computed(@() unitName.get() != null))

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
    close()
  }
}

let function mkPrice() {
  let speedUpCost = Computed(function() {
    let { costGold = 0, nextLevelExp = 0 } = unitResearchCfg.get()
    return nextLevelExp
        ? max(1, (min(1.0, (nextLevelExp - unitExp.get()).tofloat() / nextLevelExp) * costGold + 0.5).tointeger())
      : null
  })

  return @() {
    watch = [unitInProgress, speedUpCost]
    size = [flex(), hdpx(70)]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = unitInProgress.value != null ? spinner
      : [
          {
            size = flex()
            rendObj = ROBJ_IMAGE
            image = priceBgGradient
          }
          {
            size = flex()
            rendObj = ROBJ_BOX
            fillColor = 0
            borderColor = priceBgBorder
            borderWidth = hdpx(3)
          }
          mkCurrencyComp(speedUpCost.get(), "gold")
        ]
  }
}

function mkContent() {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size = [blockSize[0], SIZE_TO_CONTENT]
    padding = buttonsHGap
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags(sf)
    onClick
    sound = { click  = "click" }
    flow = FLOW_VERTICAL
    gap = hdpx(40)
    children = [
      @() {
        watch = unit
        size = [unitPlateWidth, unitPlateHeight]
        children = mkUnitImage(unit.get())
      }
      mkPrice()
    ]
    transform = { scale = (stateFlags.value & S_ACTIVE) != 0 ? [0.98, 0.98] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]
  }
}

let openImpl = @() addModalWindow(bgShaded.__merge({
  key = WND_UID
  size = flex()
  onClick = close
  children = @() msgBoxBg.__merge({
    watch = unitName
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      msgBoxHeaderWithClose(loc("header/unitResearchSpeedUp", { unitName = loc(getUnitLocId(unitName.get())) }),
        close,
        {
          minWidth = SIZE_TO_CONTENT,
          padding = [0, buttonsHGap]
        })
      mkContent()
    ]
  })
  animations = wndSwitchAnim
}))

if (needShowWnd.get())
  openImpl()
needShowWnd.subscribe(@(v) v ? openImpl() : removeModalWindow(WND_UID))

return @(uName) unitName.set(uName)
