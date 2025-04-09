from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { mkScreenHints } = require("%rGui/components/screenHintsLib.nut")
let { gradRadial } = require("%rGui/style/gradients.nut")

let bgImage = "ui/images/help/help_event_pirates.avif"
let bgSize = [3282, 1041]

let mkSizeByParent = @(size) [pw(100.0 * size[0] / bgSize[0]), ph(100.0 * size[1] / bgSize[1])]
let mkLines = @(lines) lines.map(@(v, i) 100.0 * v / bgSize[i % 2])

let whiteColor = 0xFFFFFFFF
let transpColor = 0x00000000
let hintBgColor = 0xCC052737

let mkTextarea = @(text, maxWidth, ovr = {}) {
  maxWidth
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = 0xFFFFFFFF
  text
}.__update(fontTiny, ovr)

let mkImg = @(sizeX, sizeY, icon, color, ovr) {
  rendObj = ROBJ_IMAGE
  size = [sizeX, sizeY]
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  image = Picture($"{icon}:{sizeX}:{sizeY}")
  keepAspect = KEEP_ASPECT_FIT
  color
}.__update(ovr)

let icoSize = hdpx(60)
let icoShadeSize = (icoSize * 1.6).tointeger()
let icoPosX = (icoSize * -1.4).tointeger()
let icoPosY = (icoSize * -0.2).tointeger()

let iconShade = mkImg(icoShadeSize, icoShadeSize, "", hintBgColor, { image = gradRadial })

let mkTextareaWithIcon = @(text, icon, maxWidth)
  mkTextarea(text, maxWidth, {
    children = {
      size = [icoSize, icoSize]
      hplace = ALIGN_LEFT
      vplace = ALIGN_TOP
      pos = [icoPosX, icoPosY]
      children = [
        iconShade
        mkImg(icoSize, icoSize, icon, whiteColor, {})
      ]
    }
  })

let fireCircleSz = hdpx(90)
let ammoArcH = round(fireCircleSz * 1.86).tointeger()
let ammoArcW = round(ammoArcH * 0.5).tointeger()
let ammoArcPosX = round(fireCircleSz * -0.73).tointeger()
let ammoArcPosY = round(fireCircleSz * -0.1).tointeger()
let ammoCircleSz = round(ammoArcH * 0.27).tointeger()
let ammoCircleActiveSz = round(ammoArcH * 0.32).tointeger()
let ammo1PosX = round(ammoArcH * 0.08).tointeger()
let ammo1PosY = round(ammoArcH * -0.34).tointeger()
let ammo2PosX = round(ammoArcH * -0.09).tointeger()
let ammo2PosY = round(ammoArcH * -0.015).tointeger()
let ammo3PosX = round(ammoArcH * -0.01).tointeger()
let ammo3PosY = round(ammoArcH * 0.34).tointeger()
let circleOutlineWidth = hdpx(1.5)
let circleOutlineActiveWidth = hdpx(3)

let mkOutline = @(size, color, lineWidth) {
  size = [size, size]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_VECTOR_CANVAS
  fillColor = transpColor
  lineWidth
  color
  commands = [ [VECTOR_ELLIPSE, 50, 50, 50, 50] ]
}

let mkCircledIcon = @(size, outlineColor, outlineWidth, imgSize, icon, icoOvr = {}, ovr = {}) {
  size = [size, size]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_PROGRESS_CIRCULAR
  image = Picture($"ui/gameuiskin#hud_bg_round_bg.svg:{size}:{size}:P")
  fgColor = 0x80177274
  bgColor = 0x26000000
  fValue = 1.0
  children = [
    mkOutline(size, outlineColor, outlineWidth)
    mkImg(imgSize, imgSize, icon, whiteColor, icoOvr)
  ]
}.__update(ovr)

let ammoCfg = [
  {
    icon = "ui/gameuiskin#hud_ammo_pirate_knipel.svg"
    posX = ammo1PosX
    posY = ammo1PosY
    active = [ false, false ]
  },
  {
    icon = "ui/gameuiskin#hud_ammo_pirate_fire.svg"
    posX = ammo2PosX
    posY = ammo2PosY
    active = [ false, true ]
  },
  {
    icon = "ui/gameuiskin#hud_ammo_pirate_cannonball.svg"
    posX = ammo3PosX
    posY = ammo3PosY
    active = [ true, false ]
  },
]

function mkFireAndWeaponsComp(pos, isRight) {
  let arcImgOvr = {
    pos = [ ammoArcPosX, ammoArcPosY ]
    keepAspect = KEEP_ASPECT_FIT
    imageHalign = ALIGN_LEFT
    imageValign = ALIGN_CENTER
    flipX = true
    children = ammoCfg.map(function(c) {
      let { icon, posX, posY, active } = c
      let isActive = active[isRight ? 1 : 0]
      let outlineColor = isActive ? 0xFFDBDBDD : whiteColor
      let size = isActive ? ammoCircleActiveSz : ammoCircleSz
      let outlineWidth = isActive ? circleOutlineActiveWidth : circleOutlineWidth
      let imgSize = round(size * 0.7).tointeger()
      return mkCircledIcon(size, outlineColor, outlineWidth, imgSize, icon, {}, { pos = [posX, posY] })
    })
  }
  let imgSize = round(fireCircleSz * 0.74).tointeger()
  let ovr = { fValue = isRight ? 1.0 : 0.6 }
  let icoOvr = isRight ? {} : { flipX = true, color = 0x80808080 }
  return {
    size = [0, 0]
    pos
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      mkCircledIcon(fireCircleSz, whiteColor, circleOutlineWidth, imgSize, "ui/gameuiskin#hud_pirate_attack.svg", icoOvr, ovr)
      mkImg(ammoArcW, ammoArcH, "ui/gameuiskin#hud_pirate_ammo_bg.svg", whiteColor, arcImgOvr)
    ]
  }
}

let fireRX = 2682
let fireRY = 712
let fireLX = 2400
let fireLY = 787
let hintFireLShiftY = 240

let hintW = hdpx(400)
let hintAmmoW = hdpx(350)

let hintAmmoX = 2480
let hintAmmo1Y = 300
let hintAmmo2Y = hintAmmo1Y + 20


let bgItems = [
  mkFireAndWeaponsComp(mkSizeByParent([fireRX, fireRY]), true)
  mkFireAndWeaponsComp(mkSizeByParent([fireLX, fireLY]), false)
]

let pointAimX = 2090
let pointAimY = 410
let hintAimPosX = 920

let hints = [
  {
    content = mkTextarea(loc("help/event/pirates/lead"), hintW)
    pos = mkSizeByParent([hintAimPosX, 300])
    bgColor = hintBgColor
    blockOvr = { hplace = ALIGN_RIGHT }
    lines = mkLines([pointAimX, pointAimY, hintAimPosX, pointAimY])
  }
  {
    content = mkTextarea(loc("help/event/pirates/aim"), hintW)
    pos = mkSizeByParent([hintAimPosX, 665])
    bgColor = hintBgColor
    blockOvr = { hplace = ALIGN_RIGHT }
    lines = mkLines([pointAimX, pointAimY, hintAimPosX, 790])
  }
  {
    content = mkTextareaWithIcon(loc("help/event/pirates/chainShot", { percent = 60 }),
      "ui/gameuiskin#hud_ammo_pirate_knipel.svg",
      hintAmmoW)
    pos = mkSizeByParent([hintAmmoX, hintAmmo1Y])
    bgColor = hintBgColor
    blockOvr = { vplace = ALIGN_BOTTOM }
  }
  {
    content = mkTextareaWithIcon(loc("help/event/pirates/explosiveCore"),
      "ui/gameuiskin#hud_ammo_pirate_fire.svg",
      hintAmmoW)
    pos = mkSizeByParent([hintAmmoX, hintAmmo2Y])
    bgColor = hintBgColor
  }
  {
    content = mkTextarea(loc("help/event/pirates/shootR"), hdpx(320))
    pos = mkSizeByParent([2535, fireLY + hintFireLShiftY])
    bgColor = hintBgColor
    blockOvr = { hplace = ALIGN_LEFT, vplace = ALIGN_BOTTOM }
    lines = mkLines([fireRX, fireRY + fireCircleSz, fireRX, fireLY + hintFireLShiftY - 92])
  }
  {
    content = mkTextarea(loc("help/event/pirates/shootL"), hdpx(500))
    pos = mkSizeByParent([fireLX + 85, fireLY + hintFireLShiftY])
    bgColor = hintBgColor
    blockOvr = { hplace = ALIGN_RIGHT, vplace = ALIGN_BOTTOM }
    lines = mkLines([fireLX, fireLY + fireCircleSz, fireLX, fireLY + hintFireLShiftY - 92])
  }
]

function makeScreen() {
  return {
    size = [sw(100), sh(100)]
    rendObj = ROBJ_SOLID
    color = 0xFF000000
    children = {
      size = [sw(100), sw(100) / bgSize[0] * bgSize[1]]
      pos = [0, -sh(1.5)]
      rendObj = ROBJ_IMAGE
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      image = Picture(bgImage)
      children = (clone bgItems).extend(mkScreenHints(hints))
    }
  }
}

return makeScreen