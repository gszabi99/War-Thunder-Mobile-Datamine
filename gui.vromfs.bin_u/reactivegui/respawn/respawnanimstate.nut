from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import deferOnce


const lineSpeed = hdpx(1000)

let slotAABB = Watched(null)
let bulletsAABB = Watched({})
let selSlotLinesSteps = Watched(null)
let bulletsViewportAABB = Watched(null)
let bulletsScrolled = Watched(false)

let bulletsScrollHandler = ScrollHandler()
let bulletsScrollOffset = keepref(Computed(@() bulletsScrollHandler.elem?.getScrollOffsY() ?? 0.0))

let moveAabbY = @(aabb, offs) { l = aabb.l, r = aabb.r, t = aabb.t + offs, b = aabb.b + offs }

slotAABB.subscribe(function(_) {
  bulletsAABB.set({})
  selSlotLinesSteps.set(null)
  bulletsViewportAABB.set(null)
  bulletsScrolled.set(false)
  bulletsScrollHandler.scrollToY(0)
})
bulletsScrollOffset.subscribe(@(offs) offs != 0 ? bulletsScrolled.set(true) : null)

function calcSelSlotLines() {
  if (slotAABB.get() == null || bulletsAABB.get().len() == 0)
    return null
  let list = bulletsAABB.get().values()
  let { t, b, r } = slotAABB.get()
  let midY = (t + b) / 2
  let leftX = list[0].l 
  let midX = (r + leftX) / 2
  let offs = bulletsScrollOffset.get()
  let vp = bulletsViewportAABB.get()
  let trueY = list.map(function(bul) {
    let s = moveAabbY(bul, -offs)
    return (s.t + s.b) / 2
  })
  let busY = vp == null ? trueY : trueY.map(@(y) clamp(y, vp.t, vp.b))
  let visibleY = vp == null ? trueY : trueY.filter(@(y) y >= vp.t && y <= vp.b)
  return [
    [[r, midY, midX, midY]],
    busY.map(@(y) [midX, midY, midX, y]),
    visibleY.map(@(y) [midX, y, leftX, y]),
  ]
}

let updateSelSlotLines = @() selSlotLinesSteps.set(calcSelSlotLines())
foreach (w in [bulletsAABB, bulletsScrollOffset, bulletsViewportAABB])
  w.subscribe(@(_) deferOnce(updateSelSlotLines))

return {
  slotAABB
  bulletsAABB
  selSlotLinesSteps
  lineSpeed
  bulletsScrollHandler
  bulletsScrollOffset
  bulletsViewportAABB
  bulletsScrolled
  moveAabbY
}
