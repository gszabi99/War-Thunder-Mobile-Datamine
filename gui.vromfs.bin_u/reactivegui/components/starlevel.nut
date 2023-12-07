from "%globalsDarg/darg_library.nut" import *

let function mkStarLevelCtor(starSize) {
  let star = {
    size = [starSize, starSize]
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#icon_party_leader.svg:{starSize}:{starSize}:P")
    color = 0xFFFFE224
  }
  return @(level, ovr = {}) level <= 0 ? null
    : {
        flow = FLOW_HORIZONTAL
        gap = -0.3 * starSize
        children = array(level, star)
      }.__update(ovr)
}

return {
  starLevelTiny = mkStarLevelCtor(evenPx(26))
  starLevelSmall = mkStarLevelCtor(evenPx(36))
  starLevelMedium = mkStarLevelCtor(evenPx(42))
}