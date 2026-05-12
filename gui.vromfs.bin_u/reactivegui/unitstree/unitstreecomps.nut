from "%globalsDarg/darg_library.nut" import *
let { mkFlagImage, unitPlateSmall } = require("%rGui/unit/components/unitPlateComp.nut")
let { selectedLineVertSolid } = require("%rGui/components/selectedLine.nut")
let { gradTexSize, mkGradientCtorRadial } = require("%rGui/style/gradients.nut")
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { mkPriorityUnseenMarkWatch, priorityUnseenMarkFeature } = require("%rGui/components/unseenMark.nut")
let { curCampaignUnseenBranches } = require("%rGui/unitsTree/unseenBranches.nut")
let { selectColor } = require("%rGui/style/stdColors.nut")


let flagSize = evenPx(70)
let flagSizeBig = evenPx(90)
let flagGap = hdpx(5)
let flagsWidth = flagSize * 2 + flagGap
let unitPlateSize = unitPlateSmall
let platesGap = [hdpx(28), hdpx(56)]
let blockSize = [unitPlateSize[0] + platesGap[0], unitPlateSize[1] + platesGap[1]]
let btnSize = [SIZE_TO_CONTENT, hdpxi(70)]
let flagTreeOffset = hdpxi(60)
let gamercardOverlap = hdpx(55)
let infoPanelWidth = hdpx(650)

let flagBgColor = 0xFF000000

let gradient = mkBitmapPictureLazy(gradTexSize, gradTexSize / 4,
  mkGradientCtorRadial(0xFFFFFFFF, 0, gradTexSize / 2, gradTexSize / 2, 0, 0))

let flagBg = @(isSelected) @() {
  watch = isSelected
  key = {}
  size = flex()
  rendObj = ROBJ_IMAGE
  image = gradient()
  color = isSelected.get() ? selectColor : flagBgColor
  opacity = 0.7
  transform = {}
  transitions = [{ prop = AnimProp.color, duration = 0.3, easing = InOutQuad }]
}

let function mkTreeNodesFlag(height, country, curCountry, onClick, showUnseenMark, needBlink) {
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
            size = flex()
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
      curCampaignUnseenBranches.get()?[country] ? priorityUnseenMarkFeature.__update({ vplace = ALIGN_TOP, hplace = ALIGN_RIGHT })
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
