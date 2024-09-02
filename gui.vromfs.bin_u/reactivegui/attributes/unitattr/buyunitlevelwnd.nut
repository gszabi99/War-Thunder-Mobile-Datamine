from "%globalsDarg/darg_library.nut" import *
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { msgBoxBg, msgBoxHeaderWithClose } = require("%rGui/components/msgBox.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { buy_unit_level, unitInProgress, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { buttonsHGap } = require("%rGui/components/textButton.nut")
let { showNoBalanceMsgIfNeed } = require("%rGui/shop/msgBoxPurchase.nut")
let { PURCH_SRC_UNIT_UPGRADES, PURCH_TYPE_UNIT_LEVEL, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { generateDataDiscount, mkLevelBlock } = require("%rGui/attributes/buyLevelComp.nut")


let WND_UID = "buyUnitLevelWnd" //we no need several such messages at all.

let unitName = mkWatched(persist, "unitName", null)
let unit = Computed(@() myUnits.get()?[unitName.get()])
let levelsToMax = Computed(@() (unit.get()?.levels.len() ?? 0) - (unit.get()?.level ?? 0))
let needShowWnd = keepref(Computed(@() levelsToMax.get() > 0))

let close = @() unitName(null)

registerHandler("closeBuyUnitLevelWnd", @(_) close())

function onClickPurchase(curLevel, tgtLevel, nextLevelExp, costGold) {
  if (unitInProgress.get() != null)
    return
  let bqPurchaseInfo = mkBqPurchaseInfo(PURCH_SRC_UNIT_UPGRADES, PURCH_TYPE_UNIT_LEVEL, $"{unitName.get()} {curLevel} +{tgtLevel - curLevel}")
  if (!showNoBalanceMsgIfNeed(costGold, GOLD, bqPurchaseInfo, close))
    buy_unit_level(unitName.get(), curLevel, tgtLevel, nextLevelExp, costGold, "closeBuyUnitLevelWnd")
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
  children = @() msgBoxBg.__merge({
    watch = unitName
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      msgBoxHeaderWithClose(loc("header/unitLevelBoost", { unitName = loc(getUnitLocId(unitName.get())) }),
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

return @(uName) unitName(uName)
