from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let Rand = require("%sqstd/rand.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")
let { buy_player_level, levelup_without_unit, levelInProgress, registerHandler
} = require("%appGlobals/pServer/pServerApi.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { gradTranspDoubleSideX, gradCircCornerOffset } = require("%rGui/style/gradients.nut")
let { decorativeLineBgMW, bgMW, userlogTextColor } = require("%rGui/style/stdColors.nut")
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
let openBuyExpWithUnitWnd = require("%rGui/levelUp/buyExpWithUnitWnd.nut")
let { isExperienceWndOpen } = require("expWndState.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { levelBlock } = require("%rGui/mainMenu/gamercard.nut")
let { playerExpColor } = require("%rGui/components/levelBlockPkg.nut")
let { setHangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { PURCH_SRC_HANGAR, PURCH_TYPE_PLAYER_LEVEL, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")


let wndWidth = hdpx(1400)
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
          ["{level}"] = mkPlayerLevel(level + 1, (isStarProgress ? starLevel + 1 : 0)), //warning disable: -forgot-subst
          ["{cost}"] = mkCurrencyComp(cost, GOLD) //warning disable: -forgot-subst
        }
      )
    },
    @() openMsgBoxPurchase(
      loc("shop/needMoneyQuestion_buy", { item = colorize(userlogTextColor, loc("unitsTree/campaignLevel")) }),
      {
        price = cost
        currencyId = GOLD
      },
      @() buy_player_level(campaign, level, nextLevelExp - exp, cost, { id = "onLvlPurchaseNoUnit", campaign }),
      mkBqPurchaseInfo(PURCH_SRC_HANGAR, PURCH_TYPE_PLAYER_LEVEL, (level + 1).tostring())),
    PURCHASE)
}

let chooseUnitBlock = @() {
  watch = availableUnitsList
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = hdpx(50)
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
            openBuyExpWithUnitWnd(u.name)
            setHangarUnit(u.name)
            closeExperienceWnd()
          }))
        }
      ]
    : [
        {
          size = [hdpx(1000), SIZE_TO_CONTENT]
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

let decorativeLine = {
  rendObj = ROBJ_IMAGE
  image = gradTranspDoubleSideX
  color = decorativeLineBgMW
  size = [ flex(), hdpx(6) ]
}

let experienceWndHeader = {
  rendObj = ROBJ_TEXT
  text = loc("mainmenu/campaign_levelup")
}.__update(fontMedium)

let mkLevelBlock = @(exp, nextLevelExp) levelBlock({ pos = [0, 0] }, {
  children = [
    {
      size = flex()
      rendObj = ROBJ_SOLID
      color = 0xFFFFFFFF
    }
    {
      size = [pw(clamp(99.0 * exp / nextLevelExp, 0, 99)), flex()]
      rendObj = ROBJ_SOLID
      color = playerExpColor
    }
  ]
}, true)

let necessaryPoints = @(needExp){
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_RIGHT
  margin = [0, hdpx(60), 0, 0]
  children = [
    {
      rendObj = ROBJ_TEXT
      text = $"+{needExp}"
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

function experienceWnd(){
  let { exp, nextLevelExp } = playerLevelInfo.value
  return{
    watch = playerLevelInfo
    minWidth = wndWidth
    rendObj  =  ROBJ_9RECT
    color = bgMW
    image = gradTranspDoubleSideX
    texOffs = [gradCircCornerOffset, gradCircCornerOffset]
    screenOffs = [hdpx(350), hdpx(130)]
    flow = FLOW_VERTICAL
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    gap = hdpx(50)
    sound = { detach  = "menu_close" }
    children = [
      decorativeLine
      experienceWndHeader
      {
        halign = ALIGN_CENTER
        flow = FLOW_VERTICAL
        children = [
          mkLevelBlock(exp, nextLevelExp)
          necessaryPoints(nextLevelExp - exp)
        ]
      }
      chooseUnitBlock
      decorativeLine
    ]
  }
}

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