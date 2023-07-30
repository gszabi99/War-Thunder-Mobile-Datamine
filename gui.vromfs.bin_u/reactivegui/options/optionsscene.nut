from "%globalsDarg/darg_library.nut" import *
let { contentOffset, contentWidth, tabW } = require("optionsStyle.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let backButton = require("%rGui/components/backButton.nut")

let { registerScene } = require("%rGui/navState.nut")
let { isAuthorized } = require("%appGlobals/loginState.nut")
let soundOptions = require("options/soundOptions.nut")
let graphicOptions = require("options/graphicOptions.nut")
let { langOptions } = require("options/langOptions.nut")
let { controlsOptions } = require("options/controlsOptions.nut")
let mkOption = require("mkOption.nut")
let mkOptionsTabs = require("mkOptionsTabs.nut")
let accountPage = require("accountPage.nut")
let { mkBitmapPicture } = require("%darg/helpers/bitmap.nut")
let { lerpClamped } = require("%sqstd/math.nut")


let isOpened = mkWatched(persist, "isOpened", false)
let curTabIdx = mkWatched(persist, "curTabIdx", 0)
let close = @() isOpened(false)
let backBtn = backButton(close)
isAuthorized.subscribe(@(_) isOpened(false))

let backButtonHeight = hdpx(60)
let gapBackButton = hdpx(50)
let topAreaSize = saBorders[1] + backButtonHeight + gapBackButton
let gradientHeightBottom = hdpxi(256)
let gradientHeightTop = min(topAreaSize, gradientHeightBottom)

let tabs = [ // id, locId, image, options, content
  {
    locId = "options/sound"
    image = "ui/gameuiskin#menu_sound.svg"
    options = soundOptions
  }
  {
    locId = "options/graphicsParameters"
    image = "ui/gameuiskin#menu_graph.svg"
    options = graphicOptions
  }
  {
    id = "account"
    locId = "options/account"
    image = "ui/gameuiskin#menu_account.svg"
    content = accountPage
  }
  {
    locId = "profile/language"
    image = "ui/gameuiskin#menu_lang.svg"
    options = langOptions
  }
  {
    locId = "mainmenu/btnControls"
    image = "ui/gameuiskin#menu_controls.svg"
    options = controlsOptions
  }
]

let pageHeight = sh(100)
let pageMask = mkBitmapPicture(2, (pageHeight / 10).tointeger(),
  function(params, bmp) {
    let { w, h } = params
    let gradStart1 = gradientHeightBottom * h / pageHeight
    let gradStart2 = h - (gradientHeightTop / 10).tointeger()
    for (local y = 0; y < h; y++) {
      let v = y < gradStart1 ? lerpClamped(0, gradStart1, 0.0, 1.0, y)
      : y > gradStart2 ? lerpClamped(gradStart2, h - 1, 1.0, 0.0, y)
      : 1.0
      let part = (v * v * 0xFF + 0.5).tointeger()
      let color = Color(part, part, part, part)
      for (local x = 0; x < w; x++)
        bmp.setPixel(x, y, color)
    }
  })

let mkVerticalPannableArea = @(content, override) {
  flow = FLOW_VERTICAL
  clipChildren = true
  children = {
    size = flex()
    behavior = Behaviors.Pannable
    rendObj = ROBJ_MASK
    image = pageMask
    flow = FLOW_VERTICAL
    children = [
    { size = [flex(), topAreaSize] }
    content
    { size = [flex(), gradientHeightBottom] }
  ]
  }
}.__update(override)

let function curOptionsContent() {
  let tab = tabs?[curTabIdx.value]
  return tab?.content ?
    {
      watch = curTabIdx
      size = [contentWidth, flex()]
      children = {
        pos = [contentOffset, 0]
        key = tab
        size = flex()
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        children = tab?.content
        animations = wndSwitchAnim
      }
    }
  : mkVerticalPannableArea(
    {
      pos = [contentOffset, 0]
      key = tab
      size = [contentWidth, SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      children = tab?.options.filter(@(v) v != null).map(mkOption)
      animations = wndSwitchAnim
    },
    {
      watch = curTabIdx
      size = [sw(100) - tabW - saBorders[1], sh(100)]
      pos = [0, -topAreaSize]
    })
}

let tabsList = mkOptionsTabs(tabs, curTabIdx)

let optionsScene = bgShaded.__merge({
  key = {}
  size = flex()
  padding = saBordersRv

  flow = FLOW_VERTICAL
  gap = hdpx(50)
  children = [
    backBtn
    {
      size = flex()
      flow = FLOW_HORIZONTAL
      children = [
        tabsList
        curOptionsContent
      ]
    }
  ]
  animations = wndSwitchAnim
})

registerScene("optionsScene", optionsScene, close, isOpened)

return function(pageId = null) {
  if (pageId != null)
    curTabIdx(tabs.findindex(@(v) v?.id == pageId) ?? curTabIdx.value)
  isOpened(true)
}
