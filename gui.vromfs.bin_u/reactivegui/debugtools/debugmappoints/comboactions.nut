from "%globalsDarg/darg_library.nut" import *
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { transformInProgress, ELEM_POINT, ELEM_LINE, ELEM_BG, addLine, changeLine, presetLines,
  tuningPoints, tuningBgElems
} = require("%rGui/debugTools/debugMapPoints/mapEditorState.nut")
let { getClosestSegment } = require("%rGui/event/treeEvent/segmentMath.nut")


let bgElemIdxToId = @(id) id in tuningPoints.get() ? id
  : (tuningBgElems.get()?[id].id ?? "")

let lineCreatorCfg = {
  info = "Hold Shift and click on other point or bgElem to create new line"
  shiftInfo = "Click other point or bgElem to create new line"
  function process(idFrom, findObject, _) {
    if (transformInProgress.get() != null)
      return false
    let { id = null } = findObject(@(o) o.eType == ELEM_POINT || o.eType == ELEM_BG)
    if (id == null || id == idFrom)
      return true

    let extFrom = bgElemIdxToId(idFrom)
    let extTo = bgElemIdxToId(id)
    let errorStr = (extFrom == "" || extTo == "") ? "Bg elem used for line should have not empty id"
      : addLine(extFrom, extTo)
    if (errorStr != "")
      openFMsgBox({ text = errorStr })
    return true
  }
}

let shiftActions = {
  [ELEM_POINT] = lineCreatorCfg,
  [ELEM_BG] = lineCreatorCfg.__merge({ isFit = @(id) bgElemIdxToId(id) != "" }),

  [ELEM_LINE] = {
    info = "Hold Shift and click on the map to add midpoint to selected line"
    shiftInfo = "Click on the map to add midpoint to selected line"
    function process(lineIdx, _, getMapRelCoords) {
      let line = clone presetLines.get()?[lineIdx]
      if (line == null)
        return false
      let [x, y] = getMapRelCoords()
      let midpoints = clone (line?.midpoints ?? [])

      local mIdx = 0
      if (midpoints.len() > 0) {
        let allPoints = clone midpoints
        let { from, to } = line
        let p1 = tuningPoints.get()?[from].pos
        let p2 = tuningPoints.get()?[to].pos
        if (p1 != null)
          allPoints.insert(0, p1)
        if (p2 != null)
          allPoints.append(p2)
        let cIdx = getClosestSegment(allPoints, x, y).idx
        if (cIdx >= 0)
          mIdx = cIdx + (p1 == null ? 1 : 0)
      }

      midpoints.insert(mIdx, [(x + 0.5).tointeger(), (y + 0.5).tointeger()])

      line.midpoints <- midpoints
      changeLine(lineIdx, line)

      return true
    }
  }
}

return {
  shiftActions
}