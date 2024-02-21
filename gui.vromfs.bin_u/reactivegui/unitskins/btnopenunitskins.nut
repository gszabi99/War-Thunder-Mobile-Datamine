from "%globalsDarg/darg_library.nut" import *
let { openUnitSkins } = require("unitSkinsState.nut")
let { unseenSkins } = require("unseenSkins.nut")
let { baseUnit } = require("%rGui/unitDetails/unitDetailsState.nut")
let { mkCustomButton, buttonStyles } = require("%rGui/components/textButton.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")


let iconSize = hdpxi(80)

let mkSkinsBtnContent = {
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = [
    {
      size = [iconSize, iconSize]
      rendObj = ROBJ_IMAGE
      keepAspect = true
      image = Picture($"ui/gameuiskin#skin_selection_icon.svg:{iconSize}:{iconSize}:P")
    }
    {
      rendObj = ROBJ_TEXT
      text = loc("skins/select")
    }.__update(fontSmallShaded)
  ]
}

return {
  children = [
    mkCustomButton(mkSkinsBtnContent, openUnitSkins, buttonStyles.PRIMARY)
    @() {
      watch = [unseenSkins, baseUnit]
      margin = hdpx(10)
      hplace = ALIGN_RIGHT
      children = baseUnit.get()?.name in unseenSkins.get() ? priorityUnseenMark : null
    }
  ]
}
