from "%globalsDarg/darg_library.nut" import *
let { deferOnce } = require("dagor.workcycle")

let lineSpeed = hdpx(2000)

let slotAABB = Watched(null)
let bulletsAABB = Watched({})
let selSlotLinesSteps = Watched(null)
slotAABB.subscribe(function(_) {
  bulletsAABB({})
  selSlotLinesSteps(null)
})

function calcSelSlotLines() {
  if (slotAABB.value == null || bulletsAABB.value.len() == 0)
    return null
  let list = bulletsAABB.value.values()
  let { t, b, r, l } = slotAABB.value
  let midY = (t + b) / 2
  let midX = (r + list[0].l) / 2
  let bMidY = list.map(@(bul) (bul.t + bul.b) / 2)
  return [
    [
      [l, midY, l, t],
      [l, midY, l, b],
    ],
    [
      [l, t, r, t],
      [l, b, r, b],
    ],
    [
      [r, t, r, midY],
      [r, b, r, midY],
    ],
    [[r, midY, midX, midY]],
    bMidY.map(@(y) [midX, midY, midX, y]),
    bMidY.map(@(y, idx) [midX, y, list[idx].l, y]),
  ]
}

let updateSelSlotLines = @() selSlotLinesSteps(calcSelSlotLines())
bulletsAABB.subscribe(@(_) deferOnce(updateSelSlotLines))


return {
  slotAABB
  bulletsAABB
  selSlotLinesSteps
  lineSpeed
}