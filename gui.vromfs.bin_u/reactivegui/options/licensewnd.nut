from "%globalsDarg/darg_library.nut" import *
from "app" import is_dev_version
let { registerScene } = require("%rGui/navState.nut")
let { read_text_from_file_on_disk = null, file_exists } = require("dagor.fs")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let scrollbar = require("%rGui/components/scrollbar.nut")
let { backButton } = require("%rGui/components/backButton.nut")

let licenseFileName = is_dev_version() ? "LICENSE-aces-dev" : "LICENSE-aces"

let isLicenseOpened = mkWatched(persist, "isLicenseOpened", false)
let closeLicenseWnd = @() isLicenseOpened.set(false)
let openLicenseWnd = @() isLicenseOpened.set(true)

let wndHeader = {
  size = [flex(), SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  children = [
    backButton(closeLicenseWnd)
    {
      rendObj = ROBJ_TEXT
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      color = 0xFFFFFFFF
      text = loc("options/license")
      margin = [0, 0, 0, hdpx(15)]
    }.__update(fontBig)
  ]
}

let mkLicenseContent = @() scrollbar.makeSideScroll({
  size = [hdpx(1500), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = file_exists(licenseFileName) ? read_text_from_file_on_disk?(licenseFileName) : ""
}.__update(fontMediumShaded))


let licenseWnd = @() bgShaded.__merge({
  key = {}
  size = flex()
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