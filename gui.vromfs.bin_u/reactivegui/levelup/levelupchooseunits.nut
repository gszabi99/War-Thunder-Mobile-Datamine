from "%globalsDarg/darg_library.nut" import *
let { HangarCameraControl } = require("wt.behaviors")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let Rand = require("%sqstd/rand.nut")
let { closeLvlUpWnd, skipLevelUpUnitPurchase } = require("%rGui/levelUp/levelUpState.nut")
let { unitInfoPanel } = require("%rGui/unit/components/unitInfoPanel.nut")
let { textButtonPrimary, textButtonPurchase, textButtonCommon, buttonsHGap } = require("%rGui/components/textButton.nut")
let { defButtonHeight, defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { getPlatoonOrUnitName } = require("%appGlobals/unitPresentation.nut")
let { getUnitAnyPrice } = require("%rGui/unit/unitUtils.nut")
let purchaseUnit = require("%rGui/unit/purchaseUnit.nut")
let { unitPlateRatio, unitSelUnderlineFullSize, unitPlatesGap, mkUnitInfo,
  mkUnitBg, mkUnitSelectedGlow, mkUnitImage, mkUnitTexts, mkUnitPrice, mkUnitSelectedUnderlineVert
} = require("%rGui/unit/components/unitPlateComp.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { unitInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { playerLevelInfo, campUnitsCfg, campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { buyUnitsData } = require("%appGlobals/unitsState.nut")
let { setHangarUnit } = require("%rGui/unit/hangarUnit.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { PURCH_SRC_LEVELUP, PURCH_TYPE_UNIT, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { unitDiscounts } = require("%rGui/unit/unitsDiscountState.nut")
let { buyLevelUpUnitName } = require("%rGui/unit/upgradeUnitWnd/upgradeUnitState.nut")

let contentAppearTime = 0.3
let buttonsAppearDelay = contentAppearTime + 0.5
let buttonsAppearTime = 1.0

let unitPlateWidth = hdpx(480)
let unitPlateHeight = unitPlateWidth * unitPlateRatio

let isAttached = Watched(false)

let availableUnitsList = Computed(@() Rand.shuffle(buyUnitsData.get().canBuyOnLvlUp.values()))
let playerSelectedUnit = Watched(null)
let curSelectedUnit = Computed(function() {
  let list = availableUnitsList.get()
  if (list.len() == 0)
    return null
  if (playerSelectedUnit.get() != null
      && null != list.findvalue(@(u) u.name == playerSelectedUnit.get()))
    return playerSelectedUnit.get()
  return list[0].name
})

let needSkipBtn = Computed(@() buyUnitsData.get().canLevelUpWithoutBuy
  && null == availableUnitsList.get().findvalue(@(u) getUnitAnyPrice(u, true, unitDiscounts.get())?.discount == 1))

let nextFreeUnitLevel = Computed(function() {
  local res = 0
  let newLevel = playerLevelInfo.get().level + 1
  foreach (u in campUnitsCfg.get())
    if (u.rank > newLevel && (res == 0 || u.rank < res) && getUnitAnyPrice(u, true, unitDiscounts.get())?.discount == 1.0)
      res = u.rank
  return res
})

function onBuyUnit() {
  if (curSelectedUnit.get() == null || unitInProgress.get() != null)
    return
  let unit = campUnitsCfg.get()?[curSelectedUnit.get()]
  if (unit == null)
    return
  sendNewbieBqEvent("chooseUnitInLevelUpWnd", { status = curSelectedUnit.get() })
  if ((unit?.upgradeCostGold ?? 0) > 0)
    buyLevelUpUnitName.set(curSelectedUnit.get())
  else {
    let bqPurchaseInfo = mkBqPurchaseInfo(PURCH_SRC_LEVELUP, PURCH_TYPE_UNIT, curSelectedUnit.get())
    purchaseUnit(curSelectedUnit.get(), bqPurchaseInfo)
  }
}

function onSkipUnitPurchase() {
  sendNewbieBqEvent("skipChooseUnitInLevelUpWnd", { status = playerLevelInfo.get().level.tostring() })
  skipLevelUpUnitPurchase()
}

curSelectedUnit.subscribe(function(unitId) {
  if (isAttached.get() && unitId != null)
    setHangarUnit(unitId)
})
isAttached.subscribe(function(v) {
  if (v && curSelectedUnit.get() != null)
    setHangarUnit(curSelectedUnit.get())
})

let textarea = @(text, override = {}) {
  size = FLEX_H
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
  let unit = buyUnitsData.get().canBuyOnLvlUp?[curSelectedUnit.get()]
  let price = unit != null ? getUnitAnyPrice(unit, true, unitDiscounts.get()) : null
  let isFree = price != null && price.price == 0
  let isPaid = price != null && !isFree

  return {
    watch = [curSelectedUnit, needSkipBtn, unitDiscounts]
    size = SIZE_TO_CONTENT
    hplace = ALIGN_RIGHT
    flow = FLOW_HORIZONTAL
    gap = buttonsHGap
    children = [
      needSkipBtn.get() ? textButtonPrimary(utf8ToUpper(loc("msgbox/btn_skip")), onSkipUnitPurchase, { hotkeys = ["^J:Y"] })
        : null
      isPaid ? textButtonPurchase(utf8ToUpper(loc("msgbox/btn_purchase")), onBuyUnit, { hotkeys = ["^J:X"] })
        : isFree ? textButtonPrimary(utf8ToUpper(loc("msgbox/btn_get")), onBuyUnit, { hotkeys = ["^J:X"] })
        : null
    ]
  }
}

let unitActions = mkSpinnerHideBlock(Computed(@() unitInProgress.get() != null),
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
    watch = campMyUnits
    hplace = ALIGN_RIGHT
    flow = FLOW_HORIZONTAL
    gap = buttonsHGap
    children = [
      campMyUnits.get().len() > 0 ? btnLater : null 
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

  let isSelected = Computed(@() curSelectedUnit.get() == unit.name)
  let price = getUnitAnyPrice(unit, true, unitDiscounts.get())

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
          mkUnitInfo(unit)
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
    touchMarginPriority = TOUCH_BACKGROUND
    children = content
  }
}.__update(override)

let unitsBlock = @() {
  watch = [availableUnitsList, unitDiscounts]
  size = SIZE_TO_CONTENT
  flow = FLOW_VERTICAL
  gap = unitPlatesGap
  children = availableUnitsList.get().map(@(u) mkUnitPlate(u, @() playerSelectedUnit.set(u.name)))
}

let nextFreeUnitText = @() nextFreeUnitLevel.get() == 0 ? { watch = nextFreeUnitLevel }
  : textarea(
      loc(
        curCampaign.value == "tanks" ? "levelUp/nextFreePlatoon" : "levelUp/nextFreeShip",
        { level = nextFreeUnitLevel.get() }),
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
  onAttach = @() isAttached.set(true)
  onDetach = @() isAttached.set(false)
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
      touchMarginPriority = TOUCH_BACKGROUND
      onClick = @() unitDetailsWnd({ name = curSelectedUnit.get() })
    })
    chooseShipBlock
    navBarPlace
  ]
  transform = {}
  animations = appearAnim(0, contentAppearTime)
}