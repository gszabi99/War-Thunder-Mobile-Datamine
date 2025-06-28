from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { tankTagsOrder, getTagName } = require("%appGlobals/config/skins/skinTags.nut")
let { getSkinPresentation } = require("%appGlobals/config/skinPresentation.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { textButtonCommon, textButtonBright } = require("%rGui/components/textButton.nut")
let { closeWndBtn } = require("%rGui/components/closeWndBtn.nut")
let { mkSkinCustomTags } = require("%rGui/unit/unitSettings.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")


let wndUid = "changeSkinTagWnd"
let close = @() removeModalWindow(wndUid)

let gap = hdpx(20)
let skinSize = hdpxi(110)
let skinBorderRadius = round(skinSize * 0.2).tointeger()

let content = @(curTag, setTag) @() {
  watch = curTag
  size = FLEX_H
  padding = gap
  flow = FLOW_VERTICAL
  gap
  children = tankTagsOrder.map(@(tag)
    (tag == curTag.get() ? textButtonCommon : textButtonBright)(
      getTagName(tag),
      function() {
        close()
        setTag(tag)
      },
      { ovr = { size = const [flex(), hdpx(100)] } }))
}

function changeSkinTagWnd(unitName, skinName) {
  let { skinCustomTags, setSkinCustomTags } = mkSkinCustomTags(Watched(unitName))
  let { tag, image } = getSkinPresentation(unitName, skinName)
  let curTag = Computed(@() skinCustomTags.get()?[skinName] ?? tag)
  function setTag(t) {
    if (t != curTag.get())
      setSkinCustomTags(skinCustomTags.get().__merge({ [skinName] = t }))
  }

  addModalWindow(bgShaded.__merge({
    key = wndUid
    size = flex()
    stopHotkeys = true
    hotkeys = [[btnBEscUp, { action = close }]]
    children = {
      size = const [hdpx(700), SIZE_TO_CONTENT]
      stopMouse = true
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      rendObj = ROBJ_SOLID
      color = 0xF01E1E1E
      flow = FLOW_VERTICAL
      children = [
        {
          size = FLEX_H
          flow = FLOW_HORIZONTAL
          valign = ALIGN_CENTER
          padding = [gap, gap, 0, gap]
          gap
          children = [
            {
              size = [skinSize, skinSize]
              rendObj = ROBJ_BOX
              fillColor = 0xFFFFFFFF
              borderRadius = skinBorderRadius
              image = Picture($"ui/gameuiskin#{image}:{skinSize}:{skinSize}:P")
            }
            {
              size = FLEX_H
              rendObj = ROBJ_TEXTAREA
              behavior = Behaviors.TextArea
              text = loc("skins/chooseSkinTag")
            }.__update(fontSmall)
            closeWndBtn(close, { valign = ALIGN_TOP })
          ]
        }
        content(curTag, setTag)
      ]
    }
  }))
}

return changeSkinTagWnd