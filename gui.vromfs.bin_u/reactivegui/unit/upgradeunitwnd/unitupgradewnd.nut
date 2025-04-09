from "%globalsDarg/darg_library.nut" import *
let { mkUnitBonuses, mkBonusTiny } = require("%rGui/unit/components/unitInfoComps.nut")
let { campConfigs, curCampaign} = require("%appGlobals/pServer/campaign.nut")
let { campUnitsCfg, campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { premiumTextColor, userlogTextColor } = require("%rGui/style/stdColors.nut")
let { unitPlateHeight, unitPlateWidth, mkUnitBg, mkUnitImage, mkUnitTexts,
  mkUnitInfo } = require("%rGui/unit/components/unitPlateComp.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { unitInProgress, levelInProgress} = require("%appGlobals/pServer/pServerApi.nut")
let { bgShadedDark } = require("%rGui/style/backgrounds.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { modalWndBg, modalWndHeader } = require("%rGui/components/modalWnd.nut")
let { upgradeCommonUnitName, buyExpUnitName, buyLevelUpUnitName, isChosenUnitUpgarde } = require("%rGui/unit/upgradeUnitWnd/upgradeUnitState.nut")
let { mkLevelBg } = require("%rGui/components/levelBlockPkg.nut")
let { wpOfferCard, premOfferCard, battleRewardsTitle, cardHPadding} = require("upgradeUnitWndPkg.nut")
let mkBuyUpgardeUnit = require("mkBuyUpgardeUnit.nut")
let mkBuyExpBtn = require("mkBuyExpBtn.nut")
let mkBuyLevelupBtn = require("mkBuyLevelupBtn.nut")
let { registerScene } = require("%rGui/navState.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { gamercardBalanceBtns } = require("%rGui/mainMenu/gamercard.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")

let WND_UID = "chooseUpgradeUnitWnd"

let offerCardHeight = hdpx(600)

function close() {
  buyExpUnitName.set(null)
  upgradeCommonUnitName.set(null)
  buyLevelUpUnitName.set(null)
}

let upgradeTitle = {
  size = [flex(), hdpx(70)]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  margin = [0, 0, hdpx(12), 0]
  gap = hdpx(10)
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
    }.__update(fontSmallShaded)
  ]
}

let commonTitle = {
  rendObj = ROBJ_TEXT
  text = loc("upgradeType/common")
  size = [flex(), hdpx(70)]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  margin = [0, 0, hdpx(12), 0]
}.__update(fontSmallShaded)

let mkCardTitle = @(unit) unit?.isUpgraded ? upgradeTitle : commonTitle

let mkLevelMark = @(unit) {
  vplace = ALIGN_BOTTOM
  margin = hdpx(10)
  size = [hdpx(45), hdpx(45)]
  children = mkLevelBg({
    childOvr = {
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      borderColor = unit?.isUpgraded ? 0xFFFFB70B : 0xFF7EE2FF
      children = {
        transform = { rotate = -45 }
        children = @() {
          watch = campMyUnits
          rendObj = ROBJ_TEXT
          text = !unit?.isUpgraded
            ? campMyUnits.get()?[unit.name].level ?? 0
            : unit?.levels.len()
        }.__update(fontTiny)}
    }
  })
}

let mkUnitPlate = @(unit) {
  size = [unitPlateWidth, unitPlateHeight]
  children = [
    mkUnitBg(unit)
    mkUnitImage(unit)
    mkUnitTexts(unit, loc(getUnitLocId(unit.name)))
    mkUnitInfo(unit)
    mkLevelMark(unit)
  ]
}


let mkTextUpgrade = @(text){
  size = [unitPlateWidth, SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  hplace = ALIGN_LEFT
  text
}.__update(fontTiny)

let upgradeDesc = {
  flow = FLOW_VERTICAL
  children = [
    mkTextUpgrade(loc("upgradeType/vehDesc"))
    mkTextUpgrade(loc("upgradeType/arsDesc"))
  ]
}

function buyBtn(unit){
  if(upgradeCommonUnitName.get())
    return mkBuyUpgardeUnit(unit)
  if(buyExpUnitName.get())
    return mkBuyExpBtn(unit)
  if(buyLevelUpUnitName.get())
    return mkBuyLevelupBtn(unit)
  return
}

let mkCardContent = @(unit) {
  size = [unitPlateWidth, offerCardHeight]
  flow = FLOW_VERTICAL
  padding = [hdpx(32), 0]
  halign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  children = [
    mkCardTitle(unit)
    mkUnitPlate(unit)
    {
      size =[flex(), SIZE_TO_CONTENT]
      padding = [hdpx(15), 0,0,0]
      valign = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      children = [
        battleRewardsTitle(unit, {padding = 0})
        {size = flex()}
        mkUnitBonuses(unit, {}, mkBonusTiny)
      ]
    }
    unit?.isUpgraded ? upgradeDesc : null
    {size = flex()}
    mkSpinnerHideBlock(Computed(@() unitInProgress.get() != null || levelInProgress.get() != null),
      @() buyBtn(unit))
  ]
}

function offerCards() {
  let watch = [campUnitsCfg, campConfigs, upgradeCommonUnitName, buyExpUnitName, buyLevelUpUnitName]
  let unit = campUnitsCfg.get()?[upgradeCommonUnitName.get() ?? buyExpUnitName.get() ?? buyLevelUpUnitName.get()]
  if (unit == null)
    return { watch }
  let upgradedUnit = unit?.__merge(campConfigs.value?.gameProfile.upgradeUnitBonus ?? {}
    { isUpgraded = true })
  return modalWndBg.__merge({
    flow = FLOW_VERTICAL
    onClick = close
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [
      @() modalWndHeader(utf8ToUpper(upgradeCommonUnitName.get()
        ? loc("shop/upgradeUnitHeader")
        : loc("mainmenu/campaign_levelup")))
      @() {
        watch = [upgradeCommonUnitName, curCampaign]
        margin = hdpx(40)
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc(upgradeCommonUnitName.get() ? "shop/upgradeUnitBody" : $"shop/levelupUnit/{curCampaign.get()}",
          { unit = colorize(userlogTextColor, $"{loc(getUnitLocId(unit.name))}") })
      }.__update(fontTinyAccented)
      @() {
        watch
        flow = FLOW_HORIZONTAL
        padding = [0, cardHPadding, hdpx(40), cardHPadding]
        gap = hdpx(20)
        children = [
          wpOfferCard(mkCardContent(unit))
          @() !upgradeCommonUnitName.get()
            ? {
              watch = upgradeCommonUnitName
              size = [hdpx(100), hdpx(70)]
            }
            : {
              watch = upgradeCommonUnitName
              rendObj = ROBJ_IMAGE
              size = [hdpx(100), hdpx(70)]
              vplace = ALIGN_CENTER
              image = Picture($"ui/gameuiskin#arrow_icon.svg:{hdpx(100)}:{hdpx(70)}:P")
            }
          premOfferCard(mkCardContent(upgradedUnit))
        ]
      }
    ]
  })
}

let chooseUpgradeUnitWnd = bgShadedDark.__merge({
  key = WND_UID
  size = flex()
  padding = saBordersRv
  flow = FLOW_VERTICAL
  onClick = close
  children = [
    {
      size = [flex(), gamercardHeight]
      vplace = ALIGN_TOP
      children = [
        backButton(close)
        gamercardBalanceBtns
      ]
    }
    offerCards
  ]
  animations = wndSwitchAnim
})

registerScene("chooseUpgradeUnitWnd", chooseUpgradeUnitWnd, close, isChosenUnitUpgarde)
