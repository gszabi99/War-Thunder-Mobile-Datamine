from "%globalsDarg/darg_library.nut" import *
from "%sqstd/frp.nut" import ComputedImmediate
from "%appGlobals/currenciesState.nut" import GOLD
from "%appGlobals/pServer/campaign.nut" import campConfigs
from "%appGlobals/pServer/pServerApi.nut" import buy_unit_level, unitInProgress, registerHandler
from "%appGlobals/pServer/profile.nut" import campMyUnits
from "%appGlobals/unitPresentation.nut" import getUnitName
from "%rGui/attributes/attrState.nut" import getSpCostText
from "%rGui/attributes/buyLevelComp.nut" import generateDataDiscount, mkLevelBlock
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/modalWnd.nut" import modalWndBg, modalWndHeaderWithClose
from "%rGui/components/textButton.nut" import buttonsHGap
from "%rGui/shop/bqPurchaseInfo.nut" import PURCH_SRC_UNIT_UPGRADES, PURCH_TYPE_UNIT_LEVEL, mkBqPurchaseInfo
from "%rGui/shop/msgBoxPurchase.nut" import openMsgBoxPurchase
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/style/stdColors.nut" import userlogTextColor, selectColor
from "%rGui/tutorial/tutorialConst.nut" import TUTORIAL_ATTRIBUTES_ID
from "%rGui/tutorial/tutorialWnd/tutorialWndState.nut" import activeTutorialId


const WND_UID = "buyUnitLevelWnd" 
const FREE_LEVELS_TO_BUY = 5

let unitName = mkWatched(persist, "unitName", null)
let unit = Computed(@() campMyUnits.get()?[unitName.get()])
let unitLevels = Computed(@() campConfigs.get()?.unitLevels[unit.get()?.levelPreset] ?? [])
let maxLevel = Computed(@() unit.get()?.maxLevel ?? unitLevels.get().len()) 
let levelsToMax = Computed(@() maxLevel.get() - (unit.get()?.level ?? 0))
let needShowWnd = keepref(ComputedImmediate(@() levelsToMax.get() > 0))

let hasFreeLevelsToBuy = Computed(@() activeTutorialId.get() == TUTORIAL_ATTRIBUTES_ID)

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
    spendingCountry = campConfigs.get()?.allUnits[unitName.get()].country ?? ""
    bqInfo = mkBqPurchaseInfo(PURCH_SRC_UNIT_UPGRADES, PURCH_TYPE_UNIT_LEVEL, $"{unitName.get()} {curLevel} +{tgtLevel - curLevel}")
  })
}

function wndContent() {
  let res = { watch = [unit, levelsToMax, campConfigs, unitLevels] }
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
          levelsCfg = unitLevels.get()
        },
        unitInProgress,
        onClickPurchase,
        selectColor,
        v.levels == FREE_LEVELS_TO_BUY ? hasFreeLevelsToBuy : Watched(false),
        v.levels == FREE_LEVELS_TO_BUY ? { key = "attrOneLevelBtn" } : {}))
  })
}

let openImpl = @() addModalWindow(bgShaded.__merge({
  key = WND_UID
  size = FLEX
  onClick = close
  children = @() modalWndBg.__merge({
    watch = unitName
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      modalWndHeaderWithClose(
        loc("header/unitLevelBoost",
          { unitName = unitName.get() == null ? "" : getUnitName(unitName.get()) }),
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
