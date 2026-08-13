from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/screenHintsLib.nut" import mkScreenHints

const bgImage = "ui/images/help/help_event_battle_royale.avif"
let bgSize = [3282, 1041]

let mkSizeByParent = @(size) [pw(100.0 * size[0] / bgSize[0]), ph(100.0 * size[1] / bgSize[1])]
let mkLines = @(lines) lines.map(@(v, i) 100.0 * v / bgSize[i % 2])

const hintBgColor = 0xCC052737
const mapIconColor = 0xFFFF9600
const pickupRedColor = 0xFFB50000
const pickupBlueColor = 0xFF1E60CC
const pickupGreenColor = 0xFF418B4C
const pickupYellowColor = 0xFFBEA00F

let mkTextarea = @(text, maxWidth, isFixedWidth = false) {
  maxWidth
  size = isFixedWidth
    ? [maxWidth, SIZE_TO_CONTENT]
    : null
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = 0xFFFFFFFF
  text
}.__update(fontTiny)

const markSz = evenPx(60)
const markInnerSz = evenPx(54)
const iconSz = evenPx(32)
let mkColorMark = @(color, icon) {
  size = markSz
  pos = const [hdpx(-75), hdpx(-12)]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#circle.svg:{markSz}:{markSz}")
  children = [
    {
      size = const [hdpx(7), hdpx(3)]
      pos = const [hdpx(33), 0]
      rendObj = ROBJ_SOLID
      color = 0xFFFFFFFF
    }
    {
      size = markInnerSz
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#circle.svg:{markInnerSz}:{markInnerSz}")
      color
    }
    {
      size = iconSz
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#{icon}:{iconSz}:{iconSz}:P")
      keepAspect = true
      color = mapIconColor
    }
  ]
}

const hintAreaW = hdpx(350)
const hintPickupW = hdpx(350)

const hintPickupsPosX = 3074
const airDropPosX = 1690
const airDropPosY = 25
const pickup1PosY = 25
const pickup2PosY = 368
const pickup3PosY = 710

const hintAreaPosX = 208
const hintAreaPosY = 25
const areaPosX = 230
const areaPosY = 400
const hintPickupIntroPosX = 208
const hintPickupIntroPosY = 1016

let hints = [
  {
    content = mkTextarea(loc("help/event/battleRoyale/area"), hintAreaW)
    pos = mkSizeByParent([hintAreaPosX, hintAreaPosY])
    bgColor = hintBgColor
    lines = mkLines([areaPosX, areaPosY, areaPosX, hintAreaPosY])
  }
  {
    content = mkTextarea(loc("help/event/battleRoyale/pickups"), hintAreaW)
    pos = mkSizeByParent([hintPickupIntroPosX, hintPickupIntroPosY])
    blockOvr = { vplace = ALIGN_BOTTOM }
    bgColor = hintBgColor
  }
  {
    content = {
      children = [
        mkTextarea(loc("help/event/battleRoyale/airDrop"), hintPickupW)
        mkColorMark(pickupRedColor, "br_pickup_apfsds.svg")
      ]
    }
    pos = mkSizeByParent([airDropPosX, airDropPosY])
    bgColor = hintBgColor
  }
  {
    content = {
      children = [
        mkTextarea(loc("help/event/battleRoyale/pickupCrew", { percent = 25 }), hintPickupW, true)
        mkColorMark(pickupBlueColor, "pickup_map_icon_crewskill.svg")
      ]
    }
    pos = mkSizeByParent([hintPickupsPosX, pickup1PosY])
    blockOvr = { hplace = ALIGN_RIGHT }
    bgColor = hintBgColor
  }
  {
    content = {
      children = [
        mkTextarea(loc("help/event/battleRoyale/pickupConsumables"), hintPickupW, true)
        mkColorMark(pickupGreenColor, "br_pickup_rep_heal.svg")
      ]
    }
    pos = mkSizeByParent([hintPickupsPosX, pickup2PosY])
    blockOvr = { hplace = ALIGN_RIGHT }
    bgColor = hintBgColor
  }
  {
    content = {
      children = [
        mkTextarea(loc("help/event/battleRoyale/pickupRadio"), hintPickupW, true)
        mkColorMark(pickupYellowColor, "br_pickup_arti_recon.svg")
      ]
    }
    pos = mkSizeByParent([hintPickupsPosX, pickup3PosY])
    blockOvr = { hplace = ALIGN_RIGHT }
    bgColor = hintBgColor
  }
]

function makeScreen() {
  return {
    size = const [sw(100), sh(100)]
    rendObj = ROBJ_SOLID
    color = 0xFF000000
    children = {
      size = [sw(100), sw(100) / bgSize[0] * bgSize[1]]
      pos = const [0, -sh(1.5)]
      rendObj = ROBJ_IMAGE
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      image = Picture(bgImage)
      children = mkScreenHints(hints)
    }
  }
}

return makeScreen