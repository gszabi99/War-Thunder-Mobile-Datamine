from "%globalsDarg/darg_library.nut" import *
let { gradTranspDoubleSideX, gradCircCornerOffset } = require("%rGui/style/gradients.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { decorativeLineBgMW, bgMW } = require("%rGui/style/stdColors.nut")
let { playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { mkLevelBg, mkProgressLevelBg, maxLevelStarChar, playerExpColor,
  levelProgressBorderWidth, rotateCompensate } = require("%rGui/components/levelBlockPkg.nut")
let Rand = require("%sqstd/rand.nut")
let { buyUnitsData, rankToReqPlayerLvl } = require("%appGlobals/unitsState.nut")
let { unitPlateWidth, unitPlateHeight, unitSelUnderlineFullHeight,
  mkUnitBg, mkUnitImage, mkUnitTexts, mkPlateText } = require("%rGui/unit/components/unitPlateComp.nut")
let { getPlatoonOrUnitName } = require("%appGlobals/unitPresentation.nut")
let openBuyExpWithUnitWnd = require("%rGui/levelUp/buyExpWithUnitWnd.nut")
let { isExpirienceWndOpen } = require("expWndState.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")

let wndWidth = hdpx(1400)
let levelSquareWidth = hdpx(100)
let levelLineWidth = hdpx(600)
let levelLineHeight = hdpx(15)
let generalProgressLineWidth = levelSquareWidth + levelLineWidth
let generalProgressLineHeight = hdpx(150)
let expStarIconSize = hdpx(50)

let expBuyWndUid = "exp_buy_wnd_uid"

let closeExpirienceWnd = @() isExpirienceWndOpen(false)

let availableUnitsList = Computed(@() Rand.shuffle(buyUnitsData.value.canBuyOnLvlUp.values()))
let unitsPlateCombinedW = unitPlateWidth + unitSelUnderlineFullHeight

let function mkUnitPlate(unit, onClick) {
  if (unit == null)
    return null
  let stateFlags = Watched(0)
  let levelUnit = rankToReqPlayerLvl.value?[unit.rank] ?? 0
  return @() {
    watch = stateFlags
    size = [ unitsPlateCombinedW, unitPlateHeight ]
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags(sf)
    onClick
    sound = {
      click  = "choose"
    }
    flow = FLOW_HORIZONTAL
    children = {
        size = [ unitPlateWidth, unitPlateHeight ]
        children = [
          mkUnitBg(unit)
          stateFlags.value & S_HOVER
            ? @() {
                size = flex()
                rendObj = ROBJ_IMAGE
                image = Picture("ui/gameuiskin#hovermenu_shop_button_glow.avif")
                color = 0xFF50C0FF
              }
            : null
          mkUnitImage(unit)
          mkUnitTexts(unit, getPlatoonOrUnitName(unit, loc))
          {
            vplace = ALIGN_BOTTOM
            children = mkPlateText(" ".concat(loc("mainmenu/rank"), levelUnit.tostring()),{
              color = 0xFF9C9EA0
              margin = [0,0,hdpx(10),hdpx(10)]
            }.__update(fontSmall))
          }
        ]
      }
  }
}

let chooseShipBlock = @() {
  watch = availableUnitsList
  halign = ALIGN_CENTER
  padding = [0,hdpx(350),hdpx(50),0]
  flow = FLOW_HORIZONTAL
  children = availableUnitsList.value.map(@(u) mkUnitPlate(u, function(){
    openBuyExpWithUnitWnd(u.name)
    closeExpirienceWnd()
  }))
}

let decorativeLine = {
  rendObj = ROBJ_IMAGE
  image = gradTranspDoubleSideX
  color = decorativeLineBgMW
  size = [ flex(), hdpx(6) ]
}

let expirienceWndHeader = {
    rendObj = ROBJ_TEXT
    text = loc("mainmenu/campaign_levelup")
    padding = [ hdpx(24), 0 ]
}.__update(fontMedium)


let function progressLine() {
  let { exp, nextLevelExp, level } = playerLevelInfo.value
  let levelBg = mkLevelBg()
  let isMaxLevel = nextLevelExp == 0
  return {
    size = [generalProgressLineWidth, generalProgressLineHeight]
    children = [
      {
        hplace = ALIGN_LEFT
        vplace = ALIGN_CENTER
        size = [levelSquareWidth, levelSquareWidth]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = [
          mkProgressLevelBg({
            key = playerLevelInfo.value
            pos = [levelSquareWidth * rotateCompensate, 0]
            size = [levelLineWidth, levelLineHeight]
            children = {
              size = [((levelLineWidth - levelProgressBorderWidth * 2)
                * clamp(exp, 0, nextLevelExp) / nextLevelExp).tointeger(),
              flex()]
              rendObj = ROBJ_SOLID
              color = playerExpColor
            }
          })
          levelBg
          {
            rendObj = ROBJ_TEXT
            key = playerLevelInfo.value
            text = isMaxLevel ? maxLevelStarChar : level
          }.__update(fontBig)
        ]
      }
      {
        rendObj = ROBJ_TEXT
        hplace = ALIGN_RIGHT
        vplace = ALIGN_TOP
        text = " ".concat(loc("mainmenu/rank"),level)
      }.__merge(fontMedium)
      {
        flow = FLOW_HORIZONTAL
        hplace = ALIGN_RIGHT
        vplace = ALIGN_BOTTOM
        children = [
          {
            key = playerLevelInfo.value
            rendObj = ROBJ_TEXT
            text = "".concat("+",(nextLevelExp - exp))
            color = 0xFFFFB70B
          }.__merge(fontMedium)
          {
            rendObj = ROBJ_IMAGE
            size = [expStarIconSize, expStarIconSize]
            color = 0xFFFFB70B
            image = Picture($"ui/gameuiskin#experience_icon.svg:{expStarIconSize}:{expStarIconSize}:P")
          }
        ]
      }
    ]
  }
}

let expirienceWnd = {
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
  children = [
    decorativeLine
    expirienceWndHeader
    progressLine
    {
      rendObj = ROBJ_TEXT
      text = loc("mainmenu/choose_unit")
      margin = [hdpx(200), 0, hdpx(50), 0]
    }.__merge(fontSmallAccented)
    chooseShipBlock
    decorativeLine
  ]
}

let expirienceBuyingWnd = bgShaded.__merge({
  size = flex()
  key = expBuyWndUid
  hotkeys = [[btnBEscUp, { action = closeExpirienceWnd }]]
  onClick = closeExpirienceWnd
  children = expirienceWnd
})


isExpirienceWndOpen.subscribe(function(isOpened) {
  if (isOpened) {
    addModalWindow(expirienceBuyingWnd)
    return
  }
  removeModalWindow(expBuyWndUid)
})