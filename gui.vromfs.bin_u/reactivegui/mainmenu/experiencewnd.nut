from "%globalsDarg/darg_library.nut" import *
let { gradTranspDoubleSideX, gradCircCornerOffset } = require("%rGui/style/gradients.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { decorativeLineBgMW, bgMW } = require("%rGui/style/stdColors.nut")
let { playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let Rand = require("%sqstd/rand.nut")
let { buyUnitsData } = require("%appGlobals/unitsState.nut")
let { mkUnitBg, mkUnitImage, mkUnitTexts, unitPlateSmall, mkUnitInfo, mkUnitSelectedGlow
} = require("%rGui/unit/components/unitPlateComp.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let openBuyExpWithUnitWnd = require("%rGui/levelUp/buyExpWithUnitWnd.nut")
let { isExperienceWndOpen } = require("expWndState.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { levelBlock } = require("%rGui/mainMenu/gamercard.nut")
let { playerExpColor } = require("%rGui/components/levelBlockPkg.nut")
let { setHangarUnit } = require("%rGui/unit/hangarUnit.nut")


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

let chooseUnitBlock = @() {
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
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
        setHangarUnit(u.name)
        closeExperienceWnd()
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

let experienceWndHeader = {
    rendObj = ROBJ_TEXT
    text = loc("mainmenu/campaign_levelup")
    padding = [ hdpx(24), 0 ]
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
    sound = { detach  = "menu_close" }
    children = [
      decorativeLine
      experienceWndHeader
      {
        margin = [hdpx(43), 0, 0, 0]
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