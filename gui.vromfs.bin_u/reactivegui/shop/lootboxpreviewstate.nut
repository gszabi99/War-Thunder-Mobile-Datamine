from "%globalsDarg/darg_library.nut" import *
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { scenesOrder } = require("%rGui/navState.nut")


let previewLootboxId = mkWatched(persist, "previewLootboxId", null)
let previewLootbox = Computed(@() serverConfigs.value?.lootboxesCfg?[previewLootboxId.value].__merge({ name = previewLootboxId.value }) ?? {})

let isInsideEvent = Computed(@() scenesOrder.value.findindex(@(v) v == "eventWnd") == (scenesOrder.value.len() - 1))
let isLootboxPreviewOpen = Computed(@() previewLootboxId.value != null && !isInsideEvent.value)
let isEmbeddedLootboxPreviewOpen = Computed(@() previewLootboxId.value != null && isInsideEvent.value)

return {
  previewLootboxId
  previewLootbox
  isLootboxPreviewOpen
  isEmbeddedLootboxPreviewOpen
  closeLootboxPreview = @() previewLootboxId(null)
}
