from "%globalsDarg/darg_library.nut" import *
from "math" import round
from "%appGlobals/clientState/respawnStateBase.nut" import respawnUnitInfo, respawnUnitSkins
from "%appGlobals/config/skinPresentation.nut" import getSkinPresentation
from "%rGui/respawn/respawnState.nut" import chooseAutoSkin, respawnSlots, selSlot, selectedSkins
from "%rGui/style/stdAnimations.nut" import mkPressTransitionScale
from "%rGui/style/stdColors.nut" import selectColor, hoverColor
from "%rGui/unit/unitSettings.nut" import isAutoSkin
from "%rGui/unitCustom/unitCustomComps.nut" import mkIcon
from "%rGui/unitCustom/unitSkins/levelSkinTags.nut" import curLevelTags


const skinSize = hdpxi(90)
let skinBorderRadius = round(skinSize * 0.2).tointeger()
const skinGap = hdpx(16)
const aTimeSelected = 0.2
const colorTransition = [{ prop = AnimProp.color, duration = aTimeSelected }]

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

function skinBtn(skin) {
  let stateFlags = Watched(0)
  let isSelected = Computed(@() (selectedSkins.get()?[unitName.get()] ?? selSlot.get()?.skin ?? "") == skin)
  let borderImg = Picture($"ui/gameuiskin#slot_border.svg:{skinSize}:{skinSize}:P")
  let hoverGlowImg = Picture("ui/gameuiskin#hovermenu_shop_button_glow.avif")
  let backIcon = mkIcon("ui/gameuiskin#back_icon.svg", const { color = 0xFF78FA78 })

  return @() {
    watch = [stateFlags, unitName]
    size = const [skinSize, skinSize]
    rendObj = ROBJ_BOX
    fillColor = 0xFFFFFFFF
    borderRadius = skinBorderRadius
    image = Picture($"ui/gameuiskin#{getSkinPresentation(unitName.get(), skin).image}:{skinSize}:{skinSize}:P")
    xmbNode = {}
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags.set(sf)
    onClick = @() selectedSkins.mutate(@(skins) skins[unitName.get()] <- skin)
    children = [
      @() {
        watch = isSelected
        size = FLEX
        rendObj = ROBJ_IMAGE
        image = borderImg
        color = isSelected.get() ? selectColor : 0
        transitions = colorTransition
      }
      @() {
        watch = stateFlags
        size = FLEX
        rendObj = ROBJ_BOX
        fillColor = stateFlags.get() & S_HOVER ? hoverColor : 0
        borderRadius = skinBorderRadius
        image = hoverGlowImg
        transitions = colorTransition
        transform = const { rotate = 180 }
      }
      @() {
        watch = isSelected
        size = FLEX
        halign = ALIGN_LEFT
        valign = ALIGN_BOTTOM
        children = isSelected.get() ? backIcon : null
      }
    ]
    ...mkPressTransitionScale(stateFlags.get())
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
