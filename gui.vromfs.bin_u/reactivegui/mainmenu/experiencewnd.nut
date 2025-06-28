from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let Rand = require("%sqstd/rand.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")
let { buy_player_level, levelup_without_unit, levelInProgress, registerHandler
} = require("%appGlobals/pServer/pServerApi.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { mkCustomButton } = require("%rGui/components/textButton.nut")
let { PURCHASE, defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { lvlUpCost, openLvlUpWndIfCan } = require("%rGui/levelUp/levelUpState.nut")
let { buyUnitsData } = require("%appGlobals/unitsState.nut")
let { mkUnitBg, mkUnitImage, mkUnitTexts, unitPlateSmall, mkUnitInfo, mkUnitSelectedGlow,
  mkPlayerLevel
} = require("%rGui/unit/components/unitPlateComp.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { isExperienceWndOpen } = require("expWndState.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { modalWndBg, modalWndHeader } = require("%rGui/components/modalWnd.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { levelBlock } = require("%rGui/mainMenu/gamercard.nut")
let { playerExpColor } = require("%rGui/components/levelBlockPkg.nut")
let { setHangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { PURCH_SRC_HANGAR, PURCH_TYPE_PLAYER_LEVEL, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { buyExpUnitName } = require("%rGui/unit/upgradeUnitWnd/upgradeUnitState.nut")

let expStarIconSize = hdpx(35)

let expBuyWndUid = "exp_buy_wnd_uid"

let closeExperienceWnd = @() isExperienceWndOpen(false)

let availableUnitsList = Computed(@() Rand.shuffle(buyUnitsData.value.canBuyOnLvlUp.values()))

function mkUnitPlate(unit, onClick) {
  if (unit == null)
    return null
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags(sf)
    onClick
    sound = {
      click  = "choose"
    }
    flow = FLOW_HORIZONTAL
    children = {
        size = unitPlateSmall
        children = [
          mkUnitBg(unit)
          mkUnitSelectedGlow(unit, Computed(@() stateFlags.get() & S_HOVER))
          mkUnitImage(unit)
          mkUnitTexts(unit, loc(getUnitLocId(unit.name)))
          mkUnitInfo(unit)
        ]
      }
  }
}

registerHandler("onLvlPurchaseNoUnit",
  function onLvlPurchase(res, context) {
    closeExperienceWnd()
    if (res?.error != null)
      return
    openLvlUpWndIfCan()
    if (!levelInProgress.get())
      levelup_without_unit(context.campaign)
  })

function buyLevelNoUnitBtn(lvlInfo, cost, campaign) {
  let { level, starLevel, isStarProgress, nextLevelExp, exp } = lvlInfo
  return mkCustomButton(
    {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children = mkTextRow(
        loc("unitsTree/getLevel"),
        @(text) { rendObj = ROBJ_TEXT, text = utf8ToUpper(text) }.__update(isWidescreen ? fontTinyAccented : fontTiny),
        {
          ["{level}"] = mkPlayerLevel(level + 1, (isStarProgress ? starLevel + 1 : 0)), 
          ["{cost}"] = mkCurrencyComp(cost, GOLD) 
        }
      )
    },
    @() openMsgBoxPurchase({
      text = loc("shop/needMoneyQuestion_buy", { item = colorize(userlogTextColor, loc("unitsTree/campaignLevel")) }),
      price = {
        price = cost
        currencyId = GOLD
      },
      purchase = @() buy_player_level(campaign, level, nextLevelExp - exp, cost, { id = "onLvlPurchaseNoUnit", campaign }),
      bqInfo = mkBqPurchaseInfo(PURCH_SRC_HANGAR, PURCH_TYPE_PLAYER_LEVEL, (level + 1).tostring())
    }),
    PURCHASE)
}

let chooseUnitBlock = @() {
  watch = availableUnitsList
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = hdpx(50)
  padding = const [0,hdpx(50)]
  children = availableUnitsList.get().len() > 0
    ? [
        {
          rendObj = ROBJ_TEXT
          hplace = ALIGN_CENTER
          text = loc("mainmenu/choose_unit")
        }.__merge(fontSmallAccented)
        {
          halign = ALIGN_CENTER
          gap = hdpx(40)
          flow = FLOW_HORIZONTAL
          children = availableUnitsList.get().map(@(u) mkUnitPlate(u, function(){
            buyExpUnitName(u.name)
            setHangarUnit(u.name)
            closeExperienceWnd()
          }))
        }
      ]
    : [
        {
          size = const [hdpx(1000), SIZE_TO_CONTENT]
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          hplace = ALIGN_CENTER
          halign = ALIGN_CENTER
          text = loc("mainmenu/campaign_levelup/no_unit")
        }.__merge(fontSmallAccented)
        mkSpinnerHideBlock(Computed(@() levelInProgress.value != null),
          @() {
            watch = [playerLevelInfo, lvlUpCost, curCampaign]
            children = buyLevelNoUnitBtn(playerLevelInfo.get(), lvlUpCost.get(), curCampaign.get())
          },
          { size = [ flex(), defButtonHeight ], halign = ALIGN_CENTER })
      ]
}

let mkLevelBlock = levelBlock({ pos = [0, 0] }, {
  children = [
    {
      size = flex()
      rendObj = ROBJ_SOLID
      color = 0xFFFFFFFF
    }
    @(){
      watch = playerLevelInfo
      size = [pw(clamp(99.0 * (playerLevelInfo.get()?.exp ?? 0) / (playerLevelInfo.get()?.nextLevelExp ?? 1), 0, 99)), flex()]
      rendObj = ROBJ_SOLID
      color = playerExpColor
    }
  ]
}, true)

let necessaryPoints = @(){
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_RIGHT
  margin = const [0, hdpx(60), 0, 0]
  children = [
    @(){
      watch = playerLevelInfo
      rendObj = ROBJ_TEXT
      text = $"+{(playerLevelInfo.get()?.nextLevelExp ?? 0) - (playerLevelInfo.get()?.exp ?? 0)}"
      color = playerExpColor
    }.__merge(fontTinyAccented)
    {
      rendObj = ROBJ_IMAGE
      size = [expStarIconSize, expStarIconSize]
      color = playerExpColor
      image = Picture($"ui/gameuiskin#experience_icon.svg:{expStarIconSize}:{expStarIconSize}:P")
    }
  ]
}

let experienceWnd = @() modalWndBg.__merge({
  padding = const [0,0, hdpx(50), 0]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = hdpx(50)
  sound = { detach  = "menu_close" }
  children = [
    modalWndHeader(loc("mainmenu/campaign_levelup"))
    {
      halign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      children = [
        mkLevelBlock
        necessaryPoints
      ]
    }
    chooseUnitBlock
  ]
})

let experienceBuyingWnd = bgShaded.__merge({
  size = flex()
  key = expBuyWndUid
  hotkeys = [[btnBEscUp, { action = closeExperienceWnd }]]
  onClick = closeExperienceWnd
  children = experienceWnd
})


isExperienceWndOpen.subscribe(function(isOpened) {
  if (isOpened) {
    addModalWindow(experienceBuyingWnd)
    return
  }
  removeModalWindow(expBuyWndUid)
})