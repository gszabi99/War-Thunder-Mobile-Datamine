from "%globalsDarg/darg_library.nut" import *

let defLineColor = 0xFFFFFFFF
let borderWidth = hdpx(2)
let lineWidth = 2 * borderWidth
let pointSize = lineWidth + 2 * hdpx(3)
let blockPadding = hdpx(10)
let blockBgColor = 0x50000000

let mkLines = @(hints) {
  size = flex()
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth
  commands = hints.reduce(function(res, h) {
    if ("lines" not in h)
      return res
    if ("color" in h)
      res.append([VECTOR_COLOR, h?.color ?? defLineColor])
    res.append([VECTOR_LINE].extend(h.lines))
    return res
  }, [])
}

function mkHintBlock(hint) {
  let { lines = null, color = defLineColor, content = null, blockOvr = {} } = hint
  if (content == null)
    return null
  local pos = hint?.pos
  if (pos == null && lines != null) {
    pos = lines.slice(lines.len() - 2)
    pos = [pw(pos[0]), ph(pos[1])]
  }
  return {
    size = [0, 0]
    pos
    children = {
      rendObj = ROBJ_BOX
      borderWidth
      borderColor = color
      fillColor = blockBgColor
      padding = blockPadding
      children = content
    }.__update(blockOvr)
  }
}

function mkTgtPoint(hint) {
  let { lines = null, color = defLineColor, needTgtPoint = true } = hint
  if (lines == null || !needTgtPoint)
    return null
  return {
    size = [0, 0]
    pos = [pw(lines[0]), ph(lines[1])]
    children = {
      size = [pointSize, pointSize]
      rendObj = ROBJ_SOLID
      color
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
    }
  }
}

let mkScreenHints = @(hints) [mkLines(hints)]
  .extend(hints.map(mkTgtPoint))
  .extend(hints.map(mkHintBlock))

let mkScreenHeader = @(ovr) {
  rendObj = ROBJ_SOLID
  color = blockBgColor
  padding = blockPadding
}.__update(ovr)

return {
  mkScreenHints
  mkScreenHeader
}