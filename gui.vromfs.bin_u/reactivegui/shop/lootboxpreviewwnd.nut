from "%globalsDarg/darg_library.nut" import *
let { registerScene } = require("%rGui/navState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { getLootboxName } = require("%rGui/unlocks/rewardsView/lootboxPresentation.nut")
let { lootboxPreviewContent } = require("lootboxPreviewContent.nut")
let { previewLootbox, isLootboxPreviewOpen, closeLootboxPreview } = require("lootboxPreviewState.nut")


let wndHeaderGap = hdpx(30)
let wndHeader = {
  size = [flex(), gamercardHeight]
  valign = ALIGN_CENTER
  children = [
    backButton(closeLootboxPreview)
    @() {
      watch = previewLootbox
      rendObj = ROBJ_TEXT
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      color = 0xFFFFFFFF
      text = getLootboxName(previewLootbox.value?.name, previewLootbox.value?.meta.event)
      margin = [0, 0, 0, hdpx(15)]
    }.__update(fontBig)
  ]
}

let lootboxPreviewWnd = @() {
  key = isLootboxPreviewOpen
  watch = previewLootbox
  size = flex()
  rendObj = ROBJ_IMAGE
  keepAspect = KEEP_ASPECT_FILL
  image = Picture("ui/images/event_bg.avif")
  color = 0xFFFFFFFF
  children = {
    size = flex()
    padding = saBordersRv
    flow = FLOW_VERTICAL
    gap = wndHeaderGap
    children = [
      wndHeader
      lootboxPreviewContent(previewLootbox.get())
    ]
  }
  animations = wndSwitchAnim
}

registerScene("lootboxPreviewWnd", lootboxPreviewWnd, closeLootboxPreview, isLootboxPreviewOpen)
