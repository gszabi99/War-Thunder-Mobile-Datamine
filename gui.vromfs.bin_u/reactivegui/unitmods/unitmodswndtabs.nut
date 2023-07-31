from "%globalsDarg/darg_library.nut" import *
let { mkTabs } = require("%rGui/components/tabs.nut")
let { mods, unitMods } = require("unitModsState.nut")

let contentMargin = hdpx(20)
let defImage = "ui/gameuiskin#upgrades_tools_icon.avif:P"

let tabH = hdpx(184)
let tabW = hdpx(460)

let function tabData(tab, ovr = {}) {
  let { id = "", locId  = "" } = tab
  let tabImage = Computed(function() {
    let curCatImage = unitMods.value.findindex(@(v, mod) v && mods.value?[mod].group == id)
    return curCatImage ? $"ui/gameuiskin#{curCatImage}.avif:O:P" : defImage
  })

  return {
    id
    content = {
      size = [tabW, tabH]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = [
        @() {
          watch = tabImage
          size = flex()
          rendObj = ROBJ_IMAGE
          image = Picture(tabImage.value)
          fallbackImage = Picture(defImage)
          keepAspect = KEEP_ASPECT_FILL
          imageHalign = ALIGN_LEFT
          imageValign = ALIGN_BOTTOM
        }

        {
          maxWidth = tabW - contentMargin * 2
          vplace = ALIGN_TOP
          hplace = ALIGN_RIGHT
          margin = [contentMargin - hdpx(10), contentMargin]
          rendObj = ROBJ_TEXT
          text = loc(locId)
          fontFx = FFT_GLOW
          fontFxFactor = 48
          fontFxColor = 0xFF000000
          behavior = Behaviors.Marquee
          delay = 1
          speed = hdpx(50)
        }.__update(fontSmall)
      ]
    }.__update(ovr)
  }
}

return {
  mkModsCategories = @(tabs, curTabId) mkTabs(tabs.map(@(t) tabData(t)), curTabId)
  tabH
  tabW
}
