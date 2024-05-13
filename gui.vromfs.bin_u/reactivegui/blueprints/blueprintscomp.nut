from "%globalsDarg/darg_library.nut" import *
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")

let iconSizeBlueprint = [hdpx(137), hdpx(50)]

function blueprintsInfo(unit) {
  let deltaBluepints = Computed(@() (serverConfigs.get()?.allBlueprints?[unit.name].targetCount ?? 0) - (servProfile.get()?.blueprints?[unit.name] ?? 0))
  return @(){
    watch = [serverConfigs, myUnits]
    size = flex()
    children = unit.name in serverConfigs.get()?.allBlueprints && unit.name not in myUnits.get()
      ? {
        size = [flex(), SIZE_TO_CONTENT]
        padding = [hdpx(100), 0,0,0]
        valign = ALIGN_TOP
        children = [
          @() {
            watch = deltaBluepints
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            maxWidth = hdpx(260)
            halign = ALIGN_LEFT
            hplace = ALIGN_LEFT
            text = "\n".concat(
              loc("blueprints/desc", {n = deltaBluepints.get()}),
              loc(getUnitLocId(unit))
            )
          }.__update(fontTinyAccented)
          {
            size = iconSizeBlueprint
            rendObj = ROBJ_IMAGE
            hplace = ALIGN_RIGHT
            image = Picture($"ui/unitskin#blueprint_default.avif:{iconSizeBlueprint[0]}:{iconSizeBlueprint[1]}:P")
          }
        ]
      }
      : null
    }
}

return {
  blueprintsInfo
}