from "%globalsDarg/darg_library.nut" import *
let { gradTranspDoubleSideX, gradCircCornerOffset } = require("%rGui/style/gradients.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { decorativeLineBgMW, bgMW } = require("%rGui/style/stdColors.nut")
let { playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let Rand = require("%sqstd/rand.nut")
let { buyUnitsData } = require("%appGlobals/unitsState.nut")
let { mkUnitBg, mkUnitImage, mkUnitTexts, mkPlatoonPlateFrame, bgPlatesTranslate
} = require("%rGui/unit/components/unitPlateComp.nut")
let { getPlatoonOrUnitName } = require("%appGlobals/unitPresentation.nut")
let openBuyExpWithUnitWnd = require("%rGui/levelUp/buyExpWithUnitWnd.nut")
let { isExpirienceWndOpen } = require("expWndState.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { levelBlock } = require("%rGui/mainMenu/gamercard.nut")
let { mkGradRank } = require("%rGui/components/gradTexts.nut")

let unitPlateWidth = hdpx(310)
let unitPlateHeight = hdpx(130)

let wndWidth = hdpx(1400)
let expStarIconSize = hdpx(35)

let expBuyWndUid = "exp_buy_wnd_uid"

let closeExpirienceWnd = @() isExpirienceWndOpen(false)

let availableUnitsList = Computed(@() Rand.shuffle(buyUnitsData.value.canBuyOnLvlUp.values()))

let function mkPlatoonPlates(unit) {
  return {
    size = [ unitPlateWidth, unitPlateHeight ]
    children = unit.platoonUnits?.map(@(_, idx) {
      size = flex()
      transform = { translate = bgPlatesTranslate(3, idx, true) }
      children = [
        mkUnitBg(unit)
        mkPlatoonPlateFrame()
      ]
    })
  }
}

let function mkUnitPlate(unit, onClick) {
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
        size = [ unitPlateWidth, unitPlateHeight ]
        children = [
          mkPlatoonPlates(unit)
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
          mkGradRank(unit.mRank, {
           padding = hdpx(10)
           hplace = ALIGN_RIGHT
           vplace = ALIGN_BOTTOM
          })
          mkPlatoonPlateFrame()
        ]
      }
  }
}

let chooseShipBlock = @() {
  flow = FLOW_VERTICAL
  children = [
    {
      rendObj = ROBJ_TEXT
      hplace = ALIGN_CENTER
      text = loc("mainmenu/choose_unit")
      margin = [hdpx(100), 0, hdpx(50), 0]
    }.__merge(fontSmallAccented)
    @(){
      watch = availableUnitsList
      halign = ALIGN_CENTER
      padding = [0, hdpx(175), hdpx(50)]
      gap = hdpx(40)
      flow = FLOW_HORIZONTAL
      children = availableUnitsList.value.map(@(u) mkUnitPlate(u, function(){
        openBuyExpWithUnitWnd(u.name)
        closeExpirienceWnd()
      }))
    }
  ]
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

let curLevel = @(level) {
  rendObj = ROBJ_TEXT
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  text = " ".concat(loc("mainmenu/rank"),level)
}.__update(fontSmall)

let necessaryPoints = @(nextLevelExp, exp){
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  children = [
    {
      rendObj = ROBJ_TEXT
      text = "".concat("+",(nextLevelExp - exp))
      color = 0xFFFFB70B
    }.__merge(fontTinyAccented)
    {
      rendObj = ROBJ_IMAGE
      size = [expStarIconSize, expStarIconSize]
      color = 0xFFFFB70B
      image = Picture($"ui/gameuiskin#experience_icon.svg:{expStarIconSize}:{expStarIconSize}:P")
    }
  ]
}

let function expirienceWnd(){
  let { exp, nextLevelExp, level } = playerLevelInfo.value
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
    children = [
      decorativeLine
      expirienceWndHeader
      {
        flow = FLOW_VERTICAL
        children = [
          curLevel(level)
          levelBlock({pos = [hdpx(-60), 0]})
          necessaryPoints(nextLevelExp, exp)
        ]
      }
      chooseShipBlock
      decorativeLine
    ]
  }
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