from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/screenHintsLib.nut" import mkScreenHints

let bgImage = "ui/images/help/help_event_battle_royale.avif"
let bgSize = [3282, 1041]

let mkSizeByParent = @(size) [pw(100.0 * size[0] / bgSize[0]), ph(100.0 * size[1] / bgSize[1])]
let mkLines = @(lines) lines.map(@(v, i) 100.0 * v / bgSize[i % 2])

let hintBgColor = 0xCC052737

let mkTextarea = @(text, maxWidth, ovr = {}) {
  maxWidth
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = 0xFFFFFFFF
  text
}.__update(fontTiny, ovr)

let hintPickupIntroW = hdpx(350)
let hintPickupW = hdpx(570)
let hintAreaW = hdpx(300)
let hintFfaW = hdpx(400)

let hintPickupsPosY = 25
let pickup1PosX = 1196
let pickup1PosY = 404
let pickup2PosX = 2148
let pickup2PosY = 280

let hintAreaPosX = 3075
let hintAreaPosY = 460
let areaPosX = 2982
let areaPosY = 326

let hints = [
  {
    content = mkTextarea(loc("help/event/battleRoyale/pickups"), hintPickupIntroW)
    pos = mkSizeByParent([208, hintPickupsPosY])
    bgColor = hintBgColor
  }
  {
    content = mkTextarea(loc("help/event/battleRoyale/pickupCrew", { percent = 50 }), hintPickupW)
    pos = mkSizeByParent([990, hintPickupsPosY])
    bgColor = hintBgColor
    lines = mkLines([pickup1PosX, pickup1PosY, pickup1PosX, 167])
  }
  {
    content = mkTextarea(loc("help/event/battleRoyale/pickupConsumables"), hintPickupW)
    pos = mkSizeByParent([2065, hintPickupsPosY])
    bgColor = hintBgColor
    lines = mkLines([pickup2PosX, pickup2PosY, pickup2PosX, 170])
  }
  {
    content = mkTextarea(loc("help/event/battleRoyale/area"), hintAreaW)
    pos = mkSizeByParent([hintAreaPosX, hintAreaPosY])
    bgColor = hintBgColor
    blockOvr = { hplace = ALIGN_RIGHT }
    lines = mkLines([areaPosX, areaPosY, areaPosX, hintAreaPosY])
  }
  {
    content = mkTextarea(loc("help/event/battleRoyale/noTeams"), hintFfaW)
    pos = mkSizeByParent([834, 858])
    bgColor = hintBgColor
    blockOvr = { hplace = ALIGN_CENTER, vplace = ALIGN_CENTER }
  }
]

function makeScreen() {
  return {
    size = const [sw(100), sh(100)]
    rendObj = ROBJ_SOLID
    color = 0xFF000000
    children = {
      size = [sw(100), sw(100) / bgSize[0] * bgSize[1]]
      pos = [0, -sh(1.5)]
      rendObj = ROBJ_IMAGE
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      image = Picture(bgImage)
      children = mkScreenHints(hints)
    }
  }
}

return makeScreen