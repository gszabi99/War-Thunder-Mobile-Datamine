from "%globalsDarg/darg_library.nut" import *
from "app" import is_dev_version
from "dagor.fs" import read_text_from_file_on_disk, file_exists
from "%rGui/components/backButton.nut" import backButton
import "%rGui/components/scrollbar.nut" as scrollbar
from "%rGui/navState.nut" import registerScene
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


let licenseFileName = is_dev_version() ? "LICENSE-aces-dev" : "LICENSE-aces"

let isLicenseOpened = mkWatched(persist, "isLicenseOpened", false)
let closeLicenseWnd = @() isLicenseOpened.set(false)
let openLicenseWnd = @() isLicenseOpened.set(true)

let wndHeader = {
  size = FLEX_H
  valign = ALIGN_CENTER
  children = [
    backButton(closeLicenseWnd)
    {
      rendObj = ROBJ_TEXT
      size = FLEX_H
      halign = ALIGN_CENTER
      color = 0xFFFFFFFF
      text = loc("options/license")
      margin = const [0, 0, 0, hdpx(15)]
    }.__update(fontBig)
  ]
}

let mkLicenseContent = @() scrollbar.makeSideScroll({
  size = const [hdpx(1500), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = file_exists(licenseFileName) ? read_text_from_file_on_disk(licenseFileName) : ""
}.__update(fontMediumShaded))


let licenseWnd = @() bgShaded.__merge({
  key = {}
  size = FLEX
  padding = saBordersRv
  flow = FLOW_VERTICAL
  gap = hdpx(20)
  children = [
    wndHeader
    mkLicenseContent()
  ]
  animations = wndSwitchAnim
})

registerScene("licenseScene", licenseWnd, closeLicenseWnd, isLicenseOpened)

return { openLicenseWnd, licenseFileName }