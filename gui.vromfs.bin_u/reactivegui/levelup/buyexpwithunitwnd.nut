from "%globalsDarg/darg_library.nut" import *
let { gamercardBalanceBtns } = require("%rGui/mainMenu/gamercard.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { playerLevelInfo, allUnitsCfg, myUnits } = require("%appGlobals/pServer/profile.nut")
let { GOLD, WP } = require("%appGlobals/currenciesState.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { mkUnitBonuses } = require("%rGui/unit/components/unitInfoComps.nut")
let { campConfigs, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { premiumTextColor, userlogTextColor } = require("%rGui/style/stdColors.nut")
let { unitPlateHeight, unitPlateWidth, mkUnitBg, mkUnitImage, mkUnitTexts, mkPlayerLevel,
  mkUnitInfo } = require("%rGui/unit/components/unitPlateComp.nut")
let { getUnitLocId, getUnitPresentation } = require("%appGlobals/unitPresentation.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { mkCustomButton } = require("%rGui/components/textButton.nut")
let buttonStyles = require("%rGui/components/buttonStyles.nut")
let { utf8ToUpper, utf8ToLower } = require("%sqstd/string.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { PURCH_SRC_HANGAR, PURCH_TYPE_PLAYER_LEVEL, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { buy_player_level, buy_unit, registerHandler, levelInProgress
} = require("%appGlobals/pServer/pServerApi.nut")
let { bgShadedDark } = require("%rGui/style/backgrounds.nut")
let { registerScene } = require("%rGui/navState.nut")
let { set_camera_shift_upper } = require("hangar")
let { applyDiscount, getShortPrice } = require("%rGui/unit/unitUtils.nut")
let currencyStyles = require("%rGui/components/currencyStyles.nut")
let { CS_SMALL_INCREASED_ICON } = currencyStyles
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { setCurrentUnit } = require("%appGlobals/unitsState.nut")
let { requestOpenUnitPurchEffect } = require("%rGui/unit/unitPurchaseEffectScene.nut")
let { openRewardsModal, lvlUpCost } = require("%rGui/levelUp/levelUpState.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")
let { wpOfferCard, premOfferCard, gapCards, battleRewardsTitle } = require("chooseUpgradePkg.nut")

let fonticonPreview = "⌡"

let curUnit = mkWatched(persist, "curUnit", null)

let close = @() curUnit(null)

let lvlText = @(level, starLevel) {
  size = [SIZE_TO_CONTENT, hdpx(50)]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("mainmenu/rank")
    }.__update(fontMediumShaded)
    mkPlayerLevel(level, starLevel)
  ]
}

function upgradeAccelerationText(info) {
  let { level, starLevel, isStarProgress = false } = info
  let levelIcon = mkPlayerLevel(level + 1, (isStarProgress ? starLevel + 1 : 0))
  return {
    size = [SIZE_TO_CONTENT, hdpx(40)]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = mkTextRow(
      loc("buyUnitAndExp/desc"),
      @(text) { rendObj = ROBJ_TEXT, text }.__update(fontSmall),
      {
        ["{buyLvl}"] = levelIcon, //warning disable: -forgot-subst
      }
    )
  }
}

function curLevelMark(info) {
  let { level, starLevel, historyStarLevel } = info
  let starAdd = max(0, historyStarLevel - starLevel) - starLevel
  return lvlText(level + starAdd, starLevel + starAdd)
}

let header = @() {
  watch = [playerLevelInfo, lvlUpCost]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = hdpx(12)
  children = [
    curLevelMark(playerLevelInfo.get())
    upgradeAccelerationText(playerLevelInfo.get())
    mkCurrencyComp(lvlUpCost.value, GOLD)
  ]
}

let gamercard = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = flex()
  valign = ALIGN_CENTER
  children = [
    backButton(close)
    gamercardBalanceBtns
  ]
}

let mkCardTitle = @(unit)
  unit?.isUpgraded
    ? {
      size = [flex(), hdpx(70)]
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      margin = [0, 0, hdpx(12), 0]
      gap = hdpx(40)
      children = [
        {
          size = [hdpx(90), hdpx(40)]
          rendObj = ROBJ_IMAGE
          keepAspect = KEEP_ASPECT_FIT
          image = Picture("ui/gameuiskin#icon_premium.svg")
        }
        {
          rendObj = ROBJ_TEXT
          text = loc("upgradeType/upgraded")
          color = premiumTextColor
        }.__update(fontMediumShaded)
      ]
    }
    : {
      rendObj = ROBJ_TEXT
      text = loc("upgradeType/common")
      size = [flex(), hdpx(70)]
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      margin = [0, 0, hdpx(12), 0]
    }.__update(fontMediumShaded)

let mkUnitPlate = @(unit) {
  size = [unitPlateWidth, unitPlateHeight]
  children = [
    mkUnitBg(unit)
    mkUnitImage(unit)
    mkUnitTexts(unit, loc(getUnitLocId(unit.name)))
    mkUnitInfo(unit)
  ]
}

function mkTapPreviewText(unit) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    behavior = Behaviors.Button
    onClick = @() unitDetailsWnd(unit)
    onElemState = @(sf) stateFlags(sf)
    size = [flex(), SIZE_TO_CONTENT]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(24)
    margin = [0, 0, hdpx(40), 0]
    padding = [0, hdpx(40)]
    sound = { click = "click" }
    transform = {
      scale = (stateFlags.value & S_ACTIVE) != 0 ? [0.85, 0.85] : [1, 1]
    }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = Linear }]
    children = [
      {
        rendObj = ROBJ_TEXT
        halign = ALIGN_CENTER
        text = fonticonPreview
      }.__update(fontBig)
      {
        behavior = Behaviors.TextArea
        size = [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        halign = ALIGN_CENTER
        text = loc("buyUnitAndExp/tapToPreview")
      }.__update(fontSmall)
    ]
  }
}

let mkPriceTexts = @(unit) {
  flow = FLOW_VERTICAL
  size = [SIZE_TO_CONTENT, hdpx(120)]
  minWidth = buttonStyles.defButtonMinWidth
  gap = hdpx(6)
  children = [
    @() {
      watch = lvlUpCost
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children = [
        mkCurrencyComp(lvlUpCost.value, GOLD, CS_SMALL_INCREASED_ICON)
        { rendObj = ROBJ_TEXT, text = $" - {utf8ToLower(loc("mainmenu/rank"))}" }.__update(fontTiny)
      ]
    }
    {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children = unit?.isUpgraded
        ? [
          mkCurrencyComp(unit.upgradeCostGold, GOLD, CS_SMALL_INCREASED_ICON)
          { rendObj = ROBJ_TEXT, text = $" - {utf8ToLower(loc("itemTypes/vehicles"))}" }.__update(fontTiny)
        ]
        : [
          mkCurrencyComp(
            applyDiscount(unit.costWp, unit.levelUpDiscount) || utf8ToUpper(loc("shop/free"))
            WP
            CS_SMALL_INCREASED_ICON
          )
          { rendObj = ROBJ_TEXT, text = $" - {utf8ToLower(loc("itemTypes/vehicles"))}" }.__update(fontTiny)
        ]
    }
  ]
}

function mkPriceParameters(unit) {
  let unitCurrency = unit?.isUpgraded ? GOLD : WP
  if (unitCurrency == GOLD) {
    let unitPriceParameters = {}
    unitPriceParameters.price <- unit.upgradeCostGold + lvlUpCost.value
    unitPriceParameters.currencyId <- GOLD
    return unitPriceParameters
  }

  let itemsToBuy = []
  let unitPrice = applyDiscount(unit.costWp, unit.levelUpDiscount)
  if (unitPrice) {
    let unitPriceParameters = {}
    unitPriceParameters.price <- applyDiscount(unit.costWp, unit.levelUpDiscount)
    unitPriceParameters.currencyId <- WP
    itemsToBuy.append(unitPriceParameters)
  }
  let lvlUpPriceParameters = {}
  lvlUpPriceParameters.price <- lvlUpCost.value
  lvlUpPriceParameters.currencyId <- GOLD
  itemsToBuy.append(lvlUpPriceParameters)
  return itemsToBuy
}

registerHandler("onUnitPurchaseWithLevel",
  function onUnitPurchaseWithLevel(res, context) {
    if (res?.error != null)
      return
    let { unitId } = context
    let errString = setCurrentUnit(unitId)
    if (errString != "") {
      logerr($"On choose unit after purchase: {errString}")
      return
    }
    openRewardsModal()
    requestOpenUnitPurchEffect(myUnits.value?[unitId])
  }
)

registerHandler("onLvlPurchase",
  function onLvlPurchase(res, context) {
    if (res?.error != null) {
      close()
      return
    }
    let { unit } = context
    close()
    buy_unit(
      unit.name
      unit?.isUpgraded ? GOLD : WP
      unit?.isUpgraded ? unit.upgradeCostGold : applyDiscount(unit.costWp, unit.levelUpDiscount)
      { id = "onUnitPurchaseWithLevel", unitId = unit.name }
    )
  }
)

function mkPriceComp(unit, lvlCost) {
  if (unit?.isUpgraded)
    return mkCurrencyComp(unit.upgradeCostGold + lvlCost, GOLD)
  let wpPrice = getShortPrice(applyDiscount(unit.costWp, unit.levelUpDiscount))
  return wpPrice
    ? [mkCurrencyComp(wpPrice, WP), mkCurrencyComp(lvlCost, GOLD)]
    : mkCurrencyComp(lvlCost, GOLD)
}

function mkPurchaseFunc(unit, campaign, lvlCost, levelInfo) {
  let { level, nextLevelExp, exp } = levelInfo
  return @() buy_player_level(
      campaign
      level
      nextLevelExp - exp
      lvlCost
      { id = "onLvlPurchase", unit }
    )
}

let openConfirmationWnd = @(unit, campaign, lvlUpPrice, levelInfo) openMsgBoxPurchase(
    loc("shop/needMoneyQuestion",
      { item = colorize(userlogTextColor
        $"{loc(getUnitPresentation(unit).locId)}") })
    mkPriceParameters(unit)
    mkPurchaseFunc(unit, campaign, lvlUpPrice, levelInfo)
    mkBqPurchaseInfo(PURCH_SRC_HANGAR, PURCH_TYPE_PLAYER_LEVEL, (levelInfo.level + 1).tostring())
  )

function mkBuyBtn(unit) {
  let content = {
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    gap = hdpx(12)
    children = [
      @() {
        watch = lvlUpCost
        flow = FLOW_HORIZONTAL
        gap = hdpx(32)
        children = mkPriceComp(unit, lvlUpCost.value)
      }
    ]
  }
  return @() {
    watch = [playerLevelInfo, curCampaign, lvlUpCost]
    children = mkCustomButton(
        content,
        @() openConfirmationWnd(unit, curCampaign.value, lvlUpCost.value, playerLevelInfo.value),
        unit?.isUpgraded
          ? buttonStyles.PURCHASE.__merge({ hotkeys = ["^J:RT | Enter"] })
          : buttonStyles.PRIMARY.__merge({ hotkeys = ["^J:LT | Enter"] })
      )
  }
}

let mkCardContent = @(unit) {
  size = flex()
  flow = FLOW_VERTICAL
  padding = [hdpx(32), hdpx(16)]
  halign = ALIGN_CENTER
  children = [
    mkCardTitle(unit)
    battleRewardsTitle(unit)
    mkUnitBonuses(unit, { gap = hdpx(100), margin = [ 0, 0, hdpx(50), 0 ] })
    mkUnitPlate(unit)
    mkTapPreviewText(unit)
    mkPriceTexts(unit)
    mkSpinnerHideBlock(Computed(@() levelInProgress.value != null), mkBuyBtn(unit))
  ]
}

function offerCards() {
  let watch = [allUnitsCfg, campConfigs]
  let unit = allUnitsCfg.value?[curUnit.value]
  let upgradedUnit = unit?.__merge(campConfigs.value?.gameProfile.upgradeUnitBonus ?? {}
    { isUpgraded = true })
  if (unit == null)
    return { watch }
  return {
    watch
    flow = FLOW_HORIZONTAL
    gap = gapCards
    children = [
      wpOfferCard(unit, mkCardContent(unit))
      premOfferCard(upgradedUnit, mkCardContent(upgradedUnit))
    ]
  }
}

let buyExpWithUnitWnd = bgShadedDark.__merge({
  key = {}
  rendObj = ROBJ_SOLID
  size = flex()
  padding = saBordersRv
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  onAttach = set_camera_shift_upper
  children = [
    gamercard
    header
    offerCards
  ]
})

registerScene("buyExpWithUnitWnd", buyExpWithUnitWnd, close,
  keepref(Computed(@() curUnit.value != null)))

return @(unit) curUnit(unit)