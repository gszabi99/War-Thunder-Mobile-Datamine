from "%globalsDarg/darg_library.nut" import *
let { subPresetUnlocksComplete, currentSubPresetState, selectedPointId } = require("%rGui/event/treeEvent/treeEventState.nut")
let { mkLineCmds, mkLineCmdsOutline, mkLineColor, mkPoint, mkBgElement
} = require("%rGui/event/treeEvent/treeEventComps.nut")


let mapPoints = @(points, pointSize) {
  size = flex()
  children = points.reduce(@(acc, value, id) acc.append(mkPoint(value.__merge({ id }), pointSize)), [])
}

let bgElements = @(presetBgElems) {
  size = flex()
  children = presetBgElems.map(mkBgElement)
}

let mapBackground = @(img, onClick) img == "" ? null
  : {
      size = flex()
      behavior = Behaviors.Button
      onClick
      touchMarginPriority = TOUCH_BACKGROUND
      rendObj = ROBJ_IMAGE
      image = Picture($"{img}:0:P")
      keepAspect = true
    }

let mapLines = @(points, size, lines) function() {
  let commands = []
  foreach (line in lines) {
    commands.append(mkLineColor(line.to, subPresetUnlocksComplete.get()))
    commands.extend(mkLineCmds(line, points, size))
  }

  return {
    watch = subPresetUnlocksComplete
    size = flex()
    rendObj = ROBJ_VECTOR_CANVAS
    commands = mkLineCmdsOutline(commands)
  }
}

function subMapContainer() {
  let preset = currentSubPresetState.get()
  if (preset == null)
    return { watch = currentSubPresetState }
  let mapSize = preset.mapSize.map(hdpx)
  return {
    watch = currentSubPresetState
    size = mapSize
    children = [
      mapBackground(preset.bg, @() selectedPointId.set(null))
      bgElements(preset.bgElements)
      mapLines(preset.points, preset.mapSize, preset.lines)
      mapPoints(preset.points, preset.pointSize)
    ]
  }
}

return { subMapContainer }
