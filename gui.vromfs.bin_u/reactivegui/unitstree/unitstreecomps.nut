from "%globalsDarg/darg_library.nut" import *
from "%darg/helpers/bitmap.nut" import mkBitmapPictureLazy
from "%rGui/components/selectedLine.nut" import selectedLineVertSolid
from "%rGui/components/unseenMark.nut" import mkPriorityUnseenMarkWatch, priorityUnseenMarkFeature
from "%rGui/style/gradients.nut" import gradTexSize, mkGradientCtorRadial
from "%rGui/style/stdColors.nut" import selectColor
from "%rGui/unit/components/unitPlateComp.nut" import mkFlagImage, unitPlateSmall
from "%rGui/unitsTree/unseenBranches.nut" import curCampaignUnseenBranches


let flagSize = evenPx(70)
let flagSizeBig = evenPx(90)
const flagGap = hdpx(5)
let flagsWidth = flagSize * 2 + flagGap
let unitPlateSize = unitPlateSmall
let platesGap = [hdpx(28), hdpx(56)]
let blockSize = [unitPlateSize[0] + platesGap[0], unitPlateSize[1] + platesGap[1]]
let btnSize = [SIZE_TO_CONTENT, hdpxi(70)]
const flagTreeOffset = hdpxi(60)
const gamercardOverlap = hdpx(55)
const infoPanelWidth = hdpx(650)

const flagBgColor = 0xFF000000

let gradient = mkBitmapPictureLazy(gradTexSize, gradTexSize / 4,
  mkGradientCtorRadial(0xFFFFFFFF, 0, gradTexSize / 2, gradTexSize / 2, 0, 0))

let flagBg = @(isSelected) @() {
  watch = isSelected
  key = {}
  size = FLEX
  rendObj = ROBJ_IMAGE
  image = gradient()
  color = isSelected.get() ? selectColor : flagBgColor
  opacity = 0.7
  transform = {}
  transitions = [{ prop = AnimProp.color, duration = 0.3, easing = InOutQuad }]
}

function mkTreeNodesFlag(height, country, curCountry, onClick, showUnseenMark, needBlink) {
  let isSelected = Computed(@() curCountry.get() == country)
  return @() {
    watch = [needBlink, isSelected, curCampaignUnseenBranches]
    size = [flagsWidth, height]
    behavior = Behaviors.Button
    onClick
    sound = { click = "choose" }
    children = [
      flagBg(isSelected)
      selectedLineVertSolid(isSelected)
      !needBlink.get() || isSelected.get() ? null
        : {
            key = {}
            size = FLEX
            rendObj = ROBJ_IMAGE
            vplace = ALIGN_TOP
            image = gradient()
            color = 0x40FFFFFF
            opacity = 0
            transform = {}
            animations = [
              {
                prop = AnimProp.opacity, from = 0.0, to = 0.3, duration = 1,
                easing = CosineFull, play = true, loop = true, globalTimer = true, loopPause = 1
              }
            ]
          }
      mkFlagImage(country, country == "legacy" ? flagSizeBig : flagSize, { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER })
      curCampaignUnseenBranches.get()?[country] ? priorityUnseenMarkFeature.__merge({ vplace = ALIGN_TOP, hplace = ALIGN_RIGHT })
        : mkPriorityUnseenMarkWatch(showUnseenMark, { vplace = ALIGN_TOP, hplace = ALIGN_RIGHT })
    ]
  }
}

let bgLight = {
  rendObj = ROBJ_SOLID
  color = 0x33FFFFFF
  brightness = 0.2
}

return {
  mkTreeNodesFlag
  flagSize
  flagsWidth
  btnSize
  bgLight

  flagTreeOffset
  gamercardOverlap
  platesGap
  unitPlateSize
  blockSize
  infoPanelWidth
}
