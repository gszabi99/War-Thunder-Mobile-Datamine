from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { openUnitSkins } = require("unitSkinsState.nut")
let { unseenSkins } = require("unseenSkins.nut")
let { mkCustomButton, buttonStyles, mergeStyles } = require("%rGui/components/textButton.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")


let iconSize = hdpxi(80)

let skinsBtnContent = {
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
      text = utf8ToUpper(loc("skins/skin"))
    }.__update(fontSmallShaded)
  ]
}

let mkBtnStyle = @(minWidth) mergeStyles(buttonStyles.PRIMARY, { ovr = { minWidth } })

let mkBtnOpenUnitSkins = @(unitW, minWidth) {
  children = [
    mkCustomButton(skinsBtnContent, openUnitSkins, mkBtnStyle(minWidth))
    @() {
      watch = [unitW, unseenSkins]
      margin = hdpx(10)
      hplace = ALIGN_RIGHT
      children = unitW.get()?.name in unseenSkins.get() ? priorityUnseenMark : null
    }
  ]
}

return mkBtnOpenUnitSkins