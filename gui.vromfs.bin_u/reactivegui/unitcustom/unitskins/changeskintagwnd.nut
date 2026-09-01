from "%globalsDarg/darg_library.nut" import *
from "math" import round
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/config/skinPresentation.nut" import getSkinPresentation
from "%appGlobals/config/skins/skinTags.nut" import tankTagsOrder, getTagName
from "%rGui/components/closeWndBtn.nut" import closeWndBtn
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/textButton.nut" import textButtonCommon, textButtonPrimary
from "%rGui/controlsMenu/gpActBtn.nut" import btnBEscUp
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/unit/unitSettings.nut" import mkSkinCustomTags


const wndUid = "changeSkinTagWnd"
let close = @() removeModalWindow(wndUid)

const gap = hdpx(20)
const skinSize = hdpxi(110)
let skinBorderRadius = round(skinSize * 0.2).tointeger()

let content = @(curTag, setTag) @() {
  watch = curTag
  size = FLEX_H
  padding = gap
  flow = FLOW_VERTICAL
  gap
  children = tankTagsOrder.map(@(tag)
    (tag == curTag.get() ? textButtonCommon : textButtonPrimary)(
      utf8ToUpper(getTagName(tag)),
      function() {
        close()
        setTag(tag)
      },
      { ovr = { size = const [FLEX, hdpx(100)] } }))
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
    size = FLEX
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
          padding = const [gap, gap, 0, gap]
          gap
          children = [
            {
              size = skinSize
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