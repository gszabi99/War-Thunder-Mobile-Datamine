from "%globalsDarg/darg_library.nut" import *
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { lootboxesCfg } = require("%rGui/event/eventLootboxes.nut")


let openConfig = mkWatched(persist, "openConfig", null)
let previewLootboxId = Computed(@() openConfig.value?.id)
let previewLootbox = Computed(@() serverConfigs.value?.lootboxesCfg?[previewLootboxId.value]
  .__merge({ name = previewLootboxId.value }, lootboxesCfg?[previewLootboxId.value] ?? {}) ?? {})

let isLootboxPreviewOpen = Computed(@() previewLootboxId.value != null && !openConfig.value?.isEmbedded)
let isEmbeddedLootboxPreviewOpen = Computed(@() previewLootboxId.value != null && !!openConfig.value?.isEmbedded)

return {
  openLootboxPreview = @(id) openConfig({ id })
  openEmbeddedLootboxPreview = @(id) openConfig({ id, isEmbedded = true })
  closeLootboxPreview = @() openConfig(null)
  previewLootboxId
  previewLootbox
  isLootboxPreviewOpen
  isEmbeddedLootboxPreviewOpen
}
