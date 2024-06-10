from "%globalsDarg/darg_library.nut" import *
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")

let iconSizeBlueprint = [hdpx(70), hdpx(70)]

function blueprintsInfo(unit) {
  let deltaBluepints = Computed(@() (serverConfigs.get()?.allBlueprints?[unit.name].targetCount ?? 0) - (servProfile.get()?.blueprints?[unit.name] ?? 0))
  return @(){
    watch = [serverConfigs, myUnits]
    size = flex()
    children = unit.name in serverConfigs.get()?.allBlueprints && unit.name not in myUnits.get()
      ? {
        size = [flex(), SIZE_TO_CONTENT]
        padding = [hdpx(150), 0,0,0]
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        children = [
          @() {
            watch = deltaBluepints
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            maxWidth = defButtonMinWidth
            halign = ALIGN_LEFT
            hplace = ALIGN_LEFT
            text = "\n".concat(
              loc("blueprints/desc", {n = deltaBluepints.get()}),
              loc(getUnitLocId(unit))
            )
          }.__update(fontTinyAccented)
          {size = flex()}
          {
            margin = hdpx(30)
            size = iconSizeBlueprint
            rendObj = ROBJ_IMAGE
            hplace = ALIGN_RIGHT
            image = Picture($"ui/unitskin#blueprint_default_small.avif:{iconSizeBlueprint[0]}:{iconSizeBlueprint[1]}:P")
            transform = {
              rotate = -10
            }
          }
        ]
      }
      : null
    }
}

return {
  blueprintsInfo
}