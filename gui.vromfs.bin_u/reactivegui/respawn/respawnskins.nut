from "%globalsDarg/darg_library.nut" import *
let { checkIcon } = require("%rGui/unitSkins/unitSkinsComps.nut")
let { getSkinPresentation } = require("%appGlobals/config/skinPresentation.nut")
let { respawnUnitSkins, respawnUnitInfo } = require("%appGlobals/clientState/respawnStateBase.nut")
let { isAutoSkin } = require("%rGui/unit/unitSettings.nut")
let { chooseAutoSkin, respawnSlots, selSlot, selectedSkins } = require("%rGui/respawn/respawnState.nut")
let { curLevelTags } = require("%rGui/unitSkins/levelSkinTags.nut")


let skinSize = hdpxi(110)
let skinGap = hdpx(20)
let selectedColor = 0x8052C4E4
let aTimeSelected = 0.2

let unitName = Computed(@() selSlot.get()?.name)

unitName.subscribe(function(v) {
  if (v != null && isAutoSkin(respawnUnitInfo.get()?.name) && !selectedSkins.get()?[v] && (respawnUnitSkins.get()?.len() ?? 0) > 0) {
    let skin = chooseAutoSkin(v, respawnUnitSkins.get(), respawnSlots.get()?.findvalue(@(s) s.name == v).skin)
    selectedSkins.mutate(@(skins) skins[v] <- skin)
  }
})

let function skinBtn(skin) {
  let stateFlags = Watched(0)
  let isSelected = Computed(@() (selectedSkins.get()?[unitName.get()] ?? selSlot.get()?.skin ?? "") == skin)

  return @() {
    watch = [stateFlags, unitName]
    rendObj = ROBJ_MASK
    image = Picture($"ui/gameuiskin#slot_mask.svg:{skinSize}:{skinSize}:P")
    xmbNode = {}
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags(sf)
    onClick = @() selectedSkins.mutate(@(skins) skins[unitName.get()] <- skin)
    transform = { scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.95, 0.95] : [1, 1] }
    children = [
      @() {
        watch = unitName
        size = [skinSize, skinSize]
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#{getSkinPresentation(unitName.get(), skin).image}:{skinSize}:{skinSize}:P")
      }
      @() {
        watch = isSelected
        size = flex()
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#slot_border.svg:{skinSize}:{skinSize}:P")
        color = isSelected.get() ? selectedColor : 0
        transitions = [{ prop = AnimProp.color, duration = aTimeSelected }]
      }
      @() {
        watch = stateFlags
        size = flex()
        rendObj = ROBJ_IMAGE
        image = Picture("ui/gameuiskin#hovermenu_shop_button_glow.avif")
        color = stateFlags.get() & S_HOVER ? selectedColor : 0
        transitions = [{ prop = AnimProp.color, duration = aTimeSelected }]
        transform = { rotate = 180 }
      }
      @() {
        watch = isSelected
        size = flex()
        halign = ALIGN_LEFT
        valign = ALIGN_BOTTOM
        children = isSelected.get() ? checkIcon : null
      }
    ]
  }
}

let respawnSkins = @() {
  watch = [respawnUnitSkins, selSlot, curLevelTags, unitName]
  flow = FLOW_HORIZONTAL
  gap = skinGap
  children = respawnUnitSkins.get().keys().append("")
    .sort(@(a, b) (b == (selSlot.get()?.skin ?? "")) <=> (a == (selSlot.get()?.skin ?? ""))
      || curLevelTags.get()?[getSkinPresentation(unitName.get(), b).tag]
        <=> curLevelTags.get()?[getSkinPresentation(unitName.get(), a).tag]
      || getSkinPresentation(unitName.get(), a).tag
        <=> getSkinPresentation(unitName.get(), b).tag)
    .map(@(v) skinBtn(v))
}

return {
  respawnSkins
  skinSize
  skinGap
}
