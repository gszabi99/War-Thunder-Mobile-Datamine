from "%globalsDarg/darg_library.nut" import *
let { ComputedImmediate } = require("%sqstd/frp.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { modalWndBg, modalWndHeaderWithClose } = require("%rGui/components/modalWnd.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { buy_unit_level, unitInProgress, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { buttonsHGap } = require("%rGui/components/textButton.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { PURCH_SRC_UNIT_UPGRADES, PURCH_TYPE_UNIT_LEVEL, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { generateDataDiscount, mkLevelBlock } = require("%rGui/attributes/buyLevelComp.nut")
let { getSpCostText } = require("%rGui/attributes/attrState.nut")


let WND_UID = "buyUnitLevelWnd" 

let unitName = mkWatched(persist, "unitName", null)
let unit = Computed(@() campMyUnits.get()?[unitName.get()])
let levelsToMax = Computed(@() (unit.get()?.levels.len() ?? 0) - (unit.get()?.level ?? 0))
let needShowWnd = keepref(ComputedImmediate(@() levelsToMax.get() > 0))

let close = @() unitName.set(null)

registerHandler("closeBuyUnitLevelWnd", @(_) close())

function onClickPurchase(curLevel, tgtLevel, nextLevelExp, costGold, sp) {
  if (unitInProgress.get() != null)
    return

  openMsgBoxPurchase({
    text = sp != 0
      ? loc("shop/needMoneyQuestion", {item = colorize(userlogTextColor, getSpCostText(sp))})
      : loc("shop/needUnitUpgrade"),
    price = { price = costGold, currencyId = GOLD },
    purchase = @() buy_unit_level(unitName.get(), curLevel, tgtLevel, nextLevelExp, costGold, "closeBuyUnitLevelWnd"),
    bqInfo = mkBqPurchaseInfo(PURCH_SRC_UNIT_UPGRADES, PURCH_TYPE_UNIT_LEVEL, $"{unitName.get()} {curLevel} +{tgtLevel - curLevel}")
  })
}

function wndContent() {
  let res = { watch = [unit, levelsToMax, campConfigs] }
  let levelsSp = campConfigs.get()?.unitLevelsSp?[unit.get()?.attrPreset].levels
  if (levelsSp == null)
    return res
  return res.__update({
    flow = FLOW_HORIZONTAL
    padding = buttonsHGap
    gap = buttonsHGap
    children = generateDataDiscount(campConfigs.get()?.unitLevelsDiscount ?? [], levelsToMax.get())
      .map(@(v) mkLevelBlock(unit.get(),
        v.costMul,
        {
          levels = v.levels,
          levelsSp,
          maxLevels = unit.get().levels
        },
        unitInProgress,
        onClickPurchase))
  })
}

let openImpl = @() addModalWindow(bgShaded.__merge({
  key = WND_UID
  size = flex()
  onClick = close
  children = @() modalWndBg.__merge({
    watch = unitName
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      modalWndHeaderWithClose(
        loc("header/unitLevelBoost",
          { unitName = unitName.get() == null ? "" : loc(getUnitLocId(unitName.get())) }),
        close,
        {
          minWidth = SIZE_TO_CONTENT,
          padding = [0, buttonsHGap]
        })
      wndContent
    ]
  })
  animations = wndSwitchAnim
}))

if (needShowWnd.get())
  openImpl()
needShowWnd.subscribe(@(v) v ? openImpl() : removeModalWindow(WND_UID))

return @(uName) unitName.set(uName)
