from "%globalsDarg/darg_library.nut" import *
let { HangarCameraControl } = require("wt.behaviors")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let Rand = require("%sqstd/rand.nut")
let { closeLvlUpWnd, upgradeUnitName, skipLevelUpUnitPurchase } = require("levelUpState.nut")
let { unitInfoPanel } = require("%rGui/unit/components/unitInfoPanel.nut")
let { textButtonPrimary, textButtonPurchase, textButtonCommon, buttonsHGap } = require("%rGui/components/textButton.nut")
let { defButtonHeight, defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { getPlatoonOrUnitName } = require("%appGlobals/unitPresentation.nut")
let { getUnitAnyPrice } = require("%rGui/unit/unitUtils.nut")
let purchaseUnit = require("%rGui/unit/purchaseUnit.nut")
let { unitPlateRatio, unitSelUnderlineFullSize, unitPlatesGap, mkUnitRank,
  mkUnitBg, mkUnitSelectedGlow, mkUnitImage, mkUnitTexts, mkUnitPrice, mkUnitSelectedUnderlineVert
} = require("%rGui/unit/components/unitPlateComp.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { unitInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { playerLevelInfo, allUnitsCfg, myUnits } = require("%appGlobals/pServer/profile.nut")
let { buyUnitsData } = require("%appGlobals/unitsState.nut")
let { setHangarUnit } = require("%rGui/unit/hangarUnit.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { PURCH_SRC_LEVELUP, PURCH_TYPE_UNIT, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { unitDiscounts } = require("%rGui/unit/unitsDiscountState.nut")

let contentAppearTime = 0.3
let buttonsAppearDelay = contentAppearTime + 0.5
let buttonsAppearTime = 1.0

let unitPlateWidth = hdpx(480)
let unitPlateHeight = unitPlateWidth * unitPlateRatio

let isAttached = Watched(false)

let availableUnitsList = Computed(@() Rand.shuffle(buyUnitsData.value.canBuyOnLvlUp.values()))
let playerSelectedUnit = Watched(null)
let curSelectedUnit = Computed(function() {
  let list = availableUnitsList.value
  if (list.len() == 0)
    return null
  if (playerSelectedUnit.value != null
      && null != list.findvalue(@(u) u.name == playerSelectedUnit.value))
    return playerSelectedUnit.value
  return list[0].name
})

let needSkipBtn = Computed(@() buyUnitsData.value.canLevelUpWithoutBuy
  && null == availableUnitsList.value.findvalue(@(u) getUnitAnyPrice(u, true, unitDiscounts.value)?.discount == 1))

let nextFreeUnitLevel = Computed(function() {
  local res = 0
  let newLevel = playerLevelInfo.value.level + 1
  foreach (u in allUnitsCfg.value)
    if (u.rank > newLevel && (res == 0 || u.rank < res) && getUnitAnyPrice(u, true, unitDiscounts.value)?.discount == 1.0)
      res = u.rank
  return res
})

function onBuyUnit() {
  if (curSelectedUnit.value == null || unitInProgress.value != null)
    return
  let unit = allUnitsCfg.value?[curSelectedUnit.value]
  if (unit == null)
    return
  sendNewbieBqEvent("chooseUnitInLevelUpWnd", { status = curSelectedUnit.value })
  if ((unit?.upgradeCostGold ?? 0) > 0)
    upgradeUnitName(curSelectedUnit.value)
  else {
    let bqPurchaseInfo = mkBqPurchaseInfo(PURCH_SRC_LEVELUP, PURCH_TYPE_UNIT, curSelectedUnit.value)
    purchaseUnit(curSelectedUnit.value, bqPurchaseInfo)
  }
}

function onSkipUnitPurchase() {
  sendNewbieBqEvent("skipChooseUnitInLevelUpWnd", { status = playerLevelInfo.value.level.tostring() })
  skipLevelUpUnitPurchase()
}

curSelectedUnit.subscribe(function(unitId) {
  if (isAttached.value && unitId != null)
    setHangarUnit(unitId)
})
isAttached.subscribe(function(v) {
  if (v && curSelectedUnit.value != null)
    setHangarUnit(curSelectedUnit.value)
})

let textarea = @(text, override = {}) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  color = 0xFFFFFFFF
  fontFx = FFT_GLOW
  fontFxFactor = hdpx(64)
  fontFxColor = 0xFF000000
  text
}.__update(fontMedium, override)

let unitActionButtons = function() {
  let unit = buyUnitsData.value.canBuyOnLvlUp?[curSelectedUnit.value]
  let price = unit != null ? getUnitAnyPrice(unit, true, unitDiscounts.value) : null
  let isFree = price != null && price.price == 0
  let isPaid = price != null && !isFree

  return {
    watch = [curSelectedUnit, needSkipBtn, unitDiscounts]
    size = SIZE_TO_CONTENT
    hplace = ALIGN_RIGHT
    flow = FLOW_HORIZONTAL
    gap = buttonsHGap
    children = [
      needSkipBtn.value ? textButtonPrimary(utf8ToUpper(loc("msgbox/btn_skip")), onSkipUnitPurchase, { hotkeys = ["^J:Y"] })
        : null
      isPaid ? textButtonPurchase(utf8ToUpper(loc("msgbox/btn_purchase")), onBuyUnit, { hotkeys = ["^J:X"] })
        : isFree ? textButtonPrimary(utf8ToUpper(loc("msgbox/btn_get")), onBuyUnit, { hotkeys = ["^J:X"] })
        : null
    ]
  }
}

let unitActions = mkSpinnerHideBlock(Computed(@() unitInProgress.value != null),
  unitActionButtons,
  {
    size = [SIZE_TO_CONTENT, defButtonHeight]
    minWidth = defButtonMinWidth
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
  })

let btnLater = textButtonCommon(utf8ToUpper(loc("msgbox/btn_later")), closeLvlUpWnd,
  { hotkeys = [btnBEscUp] })

let navBarPlace = {
  size = [ defButtonMinWidth * 2 + buttonsHGap, SIZE_TO_CONTENT ]
  vplace = ALIGN_RIGHT
  hplace = ALIGN_BOTTOM
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = buttonsHGap
  children = @() {
    watch = myUnits
    hplace = ALIGN_RIGHT
    flow = FLOW_HORIZONTAL
    gap = buttonsHGap
    children = [
      myUnits.value.len() > 0 ? btnLater : null //do not allow to later when player does not have units at all
      unitActions
    ]
  }
  transform = {}
  animations = appearAnim(buttonsAppearDelay, buttonsAppearTime)
}

let unitsPlateCombinedW = unitPlateWidth + unitSelUnderlineFullSize

function mkUnitPlate(unit, onClick) {
  if (unit == null)
    return null

  let isSelected = Computed(@() curSelectedUnit.value == unit.name)
  let price = getUnitAnyPrice(unit, true, unitDiscounts.value)

  return {
    size = [ unitsPlateCombinedW, unitPlateHeight ]
    behavior = Behaviors.Button
    onClick
    sound = {
      click  = "choose"
    }
    flow = FLOW_HORIZONTAL
    children = [
      mkUnitSelectedUnderlineVert(unit, isSelected)
      {
        size = [ unitPlateWidth, unitPlateHeight ]
        children = [
          mkUnitBg(unit)
          mkUnitSelectedGlow(unit, isSelected)
          mkUnitImage(unit)
          mkUnitTexts(unit, getPlatoonOrUnitName(unit, loc))
          mkUnitRank(unit)
          price != null ? mkUnitPrice(price) : null
        ]
      }
    ]
  }
}

let mkVerticalPannableArea = @(content, override = {}) {
  size = flex()
  flow = FLOW_VERTICAL
  clipChildren = true
  children = {
    size = flex()
    behavior = Behaviors.Pannable
    children = content
  }
}.__update(override)

let unitsBlock = @() {
  watch = [availableUnitsList, unitDiscounts]
  size = SIZE_TO_CONTENT
  flow = FLOW_VERTICAL
  gap = unitPlatesGap
  children = availableUnitsList.value.map(@(u) mkUnitPlate(u, @() playerSelectedUnit(u.name)))
}

let nextFreeUnitText = @() nextFreeUnitLevel.value == 0 ? { watch = nextFreeUnitLevel }
  : textarea(
      loc(
        curCampaign.value == "tanks" ? "levelUp/nextFreePlatoon" : "levelUp/nextFreeShip",
        { level = nextFreeUnitLevel.value }),
      {
        watch = [ nextFreeUnitLevel, curCampaign ]
        pos = [ unitSelUnderlineFullSize, 0 ]
        halign = ALIGN_LEFT
      }.__update(fontTiny))

let chooseShipBlock = {
  size = flex()
  flow = FLOW_VERTICAL
  gap = unitPlatesGap
  children = [
    mkVerticalPannableArea(unitsBlock, {
      size = [ unitsPlateCombinedW, flex() ]
    })
    nextFreeUnitText
  ]
}

return {
  key = {}
  onAttach = @() isAttached(true)
  onDetach = @() isAttached(false)
  size = flex()
  children = [
    @() textarea(loc(curCampaign.value == "tanks" ? "levelUp/selectPlatoon" : "levelUp/selectShip"),
      {
        watch = curCampaign
        hplace=ALIGN_CENTER
        maxWidth = hdpx(700) })
    unitInfoPanel({
      hplace=ALIGN_RIGHT
      behavior = [ Behaviors.Button, HangarCameraControl ]
      eventPassThrough = true
      onClick = @() unitDetailsWnd({ name = curSelectedUnit.value })
    })
    chooseShipBlock
    navBarPlace
  ]
  transform = {}
  animations = appearAnim(0, contentAppearTime)
}