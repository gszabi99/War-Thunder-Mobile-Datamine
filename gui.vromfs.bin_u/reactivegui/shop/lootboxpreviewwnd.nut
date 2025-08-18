from "%globalsDarg/darg_library.nut" import *
let { getLootboxName, lootboxPreviewBg } = require("%appGlobals/config/lootboxPresentation.nut")
let { registerScene, setSceneBg, setSceneBgFallback } = require("%rGui/navState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { lootboxPreviewContent } = require("%rGui/shop/lootboxPreviewContent.nut")
let { previewLootbox, isLootboxPreviewOpen, closeLootboxPreview } = require("%rGui/shop/lootboxPreviewState.nut")

let defaultBgImage = "ui/images/event_bg.avif"
let bgImage = keepref(Computed(@() lootboxPreviewBg?[previewLootbox.get()?.name] ?? defaultBgImage))

let wndHeaderGap = hdpx(30)
let wndHeader = {
  size = [flex(), gamercardHeight]
  valign = ALIGN_CENTER
  children = [
    backButton(closeLootboxPreview)
    @() {
      watch = previewLootbox
      rendObj = ROBJ_TEXT
      size = FLEX_H
      halign = ALIGN_CENTER
      color = 0xFFFFFFFF
      text = getLootboxName(previewLootbox.get()?.name)
      margin = const [0, 0, 0, hdpx(15)]
    }.__update(fontBig)
  ]
}

let lootboxPreviewWnd = @() {
  key = isLootboxPreviewOpen
  watch = previewLootbox
  size = flex()
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

let sceneId = "lootboxPreviewWnd"
registerScene(sceneId, lootboxPreviewWnd, closeLootboxPreview, isLootboxPreviewOpen)
setSceneBgFallback(sceneId, defaultBgImage)
setSceneBg(sceneId, bgImage.get())
bgImage.subscribe(@(v) setSceneBg(sceneId, v))
