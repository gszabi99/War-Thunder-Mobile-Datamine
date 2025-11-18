from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { mkIcon } = require("%rGui/unitCustom/unitCustomCompsNew.nut")
let { getSkinPresentation } = require("%appGlobals/config/skinPresentation.nut")
let { respawnUnitInfo, respawnUnitSkins } = require("%appGlobals/clientState/respawnStateBase.nut")
let { isAutoSkin } = require("%rGui/unit/unitSettings.nut")
let { chooseAutoSkin, respawnSlots, selSlot, selectedSkins } = require("%rGui/respawn/respawnState.nut")
let { curLevelTags } = require("%rGui/unitCustom/unitSkins/levelSkinTags.nut")
let { selectColor, hoverColor } = require("%rGui/style/stdColors.nut")


let skinSize = hdpxi(110)
let skinBorderRadius = round(skinSize*0.2).tointeger()
let skinGap = hdpx(20)
let aTimeSelected = 0.2

let unitName = Computed(@() selSlot.get()?.name)

function refreshCurUnitAutoSkin() {
  let name = unitName.get()
  let { skins = {} } = selSlot.get()
  if (name != null && isAutoSkin(respawnUnitInfo.get()?.name) && !selectedSkins.get()?[name] && skins.len() > 0) {
    let skin = chooseAutoSkin(name, skins, respawnSlots.get()?.findvalue(@(s) s.name == name).skin)
    selectedSkins.mutate(@(s) s[name] <- skin)
  }
}

unitName.subscribe(@(_) refreshCurUnitAutoSkin())
respawnUnitSkins.subscribe(function(_) {
  selectedSkins.set({})
  refreshCurUnitAutoSkin()
})

let function skinBtn(skin) {
  let stateFlags = Watched(0)
  let isSelected = Computed(@() (selectedSkins.get()?[unitName.get()] ?? selSlot.get()?.skin ?? "") == skin)

  return @() {
    watch = [stateFlags, unitName]
    size = [skinSize, skinSize]
    rendObj = ROBJ_BOX
    fillColor = 0xFFFFFFFF
    borderRadius = skinBorderRadius
    image = Picture($"ui/gameuiskin#{getSkinPresentation(unitName.get(), skin).image}:{skinSize}:{skinSize}:P")
    xmbNode = {}
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags.set(sf)
    onClick = @() selectedSkins.mutate(@(skins) skins[unitName.get()] <- skin)
    transform = { scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.95, 0.95] : [1, 1] }
    children = [
      @() {
        watch = isSelected
        size = flex()
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#slot_border.svg:{skinSize}:{skinSize}:P")
        color = isSelected.get() ? selectColor : 0
        transitions = [{ prop = AnimProp.color, duration = aTimeSelected }]
      }
      @() {
        watch = stateFlags
        size = flex()
        rendObj = ROBJ_BOX
        fillColor = stateFlags.get() & S_HOVER ? hoverColor : 0
        borderRadius = skinBorderRadius
        image = Picture("ui/gameuiskin#hovermenu_shop_button_glow.avif")
        transitions = [{ prop = AnimProp.color, duration = aTimeSelected }]
        transform = { rotate = 180 }
      }
      @() {
        watch = isSelected
        size = flex()
        halign = ALIGN_LEFT
        valign = ALIGN_BOTTOM
        children = isSelected.get() ? mkIcon("ui/gameuiskin#back_icon.svg", { color = 0xFF78FA78 }) : null
      }
    ]
  }
}

let respawnSkins = @() {
  watch = [selSlot, curLevelTags, unitName]
  flow = FLOW_HORIZONTAL
  gap = skinGap
  children = (selSlot.get()?.skins ?? {}).keys().append("")
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
