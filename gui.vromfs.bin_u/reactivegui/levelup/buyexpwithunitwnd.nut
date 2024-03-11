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
  mkUnitRank } = require("%rGui/unit/components/unitPlateComp.nut")
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
let { applyDiscount } = require("%rGui/unit/unitUtils.nut")
let { ceil } = require("%sqstd/math.nut")
let currencyStyles = require("%rGui/components/currencyStyles.nut")
let { CS_SMALL_INCREASED_ICON } = currencyStyles
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { setCurrentUnit } = require("%appGlobals/unitsState.nut")
let { requestOpenUnitPurchEffect } = require("%rGui/unit/unitPurchaseEffectScene.nut")
let { openRewardsModal, lvlUpCost } = require("%rGui/levelUp/levelUpState.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")


let fonticonPreview = "⌡"

let offerCardWidth = hdpx(480)
let offerCardHeight = sh(70)

let wpCardPatternSize = [hdpx(140), hdpx(140)]
let premCardPatternSize = [hdpx(200), hdpx(200)]

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

let mkOfferCardBgPatternChunk = @(patternSize) {
  size = patternSize
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#button_pattern.svg:{patternSize[0]}:{patternSize[1]}")
  keepAspect = KEEP_ASPECT_NONE
  color = 0x23000000
}

function mkOfferCardBgPattern(isUpgraded) {
  let patternSize = isUpgraded ? premCardPatternSize : wpCardPatternSize
  let patternChunk = mkOfferCardBgPatternChunk(patternSize)
  return {
    size = flex()
    clipChildren = true
    flow = FLOW_HORIZONTAL
    children = array(ceil(offerCardWidth.tofloat() / patternSize[0]).tointeger(),
      {
        flow = FLOW_VERTICAL
        children = array(ceil(offerCardHeight.tofloat() / patternSize[1]).tointeger(),
          patternChunk)
      })
  }
}

let mkBgGradient = @(height, ovr = {}) {
  size = [flex(), height]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#gradient_button.svg:{50}:{50}")
  color = 0xDC000000
}.__merge(ovr)

let topGradient = mkBgGradient((offerCardHeight / 4).tointeger())
let bottomGradient = mkBgGradient((offerCardHeight / 2).tointeger(),
  { transform = { rotate = 180 }, vplace = ALIGN_BOTTOM, color = 0xFF000000 })
let cardBgGradient = {
  size = flex()
  padding = [hdpx(1), 0, 0, 0]
  children = [
    topGradient
    bottomGradient
  ]
}

let offerCardBaseStyle = {
  rendObj = ROBJ_FRAME
  borderWidth = [hdpx(2), hdpx(2), 0, hdpx(2)]
  size = [ offerCardWidth, sh(80) ]
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
    mkUnitRank(unit)
  ]
}

function mkTapPreviewText(unit) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    flow = FLOW_HORIZONTAL
    gap = hdpx(24)
    margin = [0, 0, hdpx(40), 0]
    onClick = @() unitDetailsWnd(unit)
    onElemState = @(sf) stateFlags(sf)
    sound = { click = "click" }
    transform = {
      scale = (stateFlags.value & S_ACTIVE) != 0 ? [0.85, 0.85] : [1, 1]
    }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = Linear }]
    children = [
      {
        rendObj = ROBJ_TEXT
        text = fonticonPreview
      }.__update(fontBig)
      {
        rendObj = ROBJ_TEXT
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
  let wpPrice = applyDiscount(unit.costWp, unit.levelUpDiscount)
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
        content
        @() openConfirmationWnd(unit, curCampaign.value, lvlUpCost.value, playerLevelInfo.value)
        unit?.isUpgraded ? buttonStyles.PURCHASE : buttonStyles.PRIMARY
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
    mkUnitBonuses(unit, { gap = hdpx(100), margin = [ 0, 0, hdpx(50), 0 ] })
    mkUnitPlate(unit)
    mkTapPreviewText(unit)
    mkPriceTexts(unit)
    mkSpinnerHideBlock(Computed(@() levelInProgress.value != null), mkBuyBtn(unit))
  ]
}

let wpOfferCard = @(unit) {
  children = [
    { rendObj = ROBJ_SOLID, size = flex(), color = 0xC8212C3C }
    mkOfferCardBgPattern(unit?.isUpgraded)
    cardBgGradient
    mkCardContent(unit)
  ]
}.__merge(offerCardBaseStyle)

let premOfferCard = @(unit) {
  children = [
    { rendObj = ROBJ_SOLID, size = flex(), color = 0xC8760302 }
    mkOfferCardBgPattern(unit?.isUpgraded)
    cardBgGradient
    mkCardContent(unit)
  ]
}.__merge(offerCardBaseStyle)

function offerCards() {
  let watch = [allUnitsCfg, campConfigs]
  let unit = allUnitsCfg.value?[curUnit.value]
  if (unit == null)
    return { watch }
  return {
    watch
    flow = FLOW_HORIZONTAL
    gap = offerCardWidth
    children = [
      wpOfferCard(unit)
      premOfferCard(
        unit.__merge(campConfigs.value?.gameProfile.upgradeUnitBonus ?? {}
        { isUpgraded = true })
      )
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