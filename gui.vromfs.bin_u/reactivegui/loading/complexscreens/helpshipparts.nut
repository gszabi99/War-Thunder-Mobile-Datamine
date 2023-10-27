from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")

let bgImage = "!ui/images/help/help_parts_ship.avif"
let bgSize = [3282, 1041]

let imgSize = hdpxi(32)
let lineWidth = evenPx(4)
let borderWidth = hdpx(2)
let blockPadding = hdpx(10)
let pointSize = lineWidth + 2 * hdpxi(3)
let offsetX = 40
let bottomRowY = 846
let topRowY = 260
let adaptiveFont = isWidescreen ? fontTiny : fontVeryTiny
let fillColor = 0x8015191C

let mkSizeByParent = @(size) [pw(100.0 * size[0] / bgSize[0]), ph(100.0 * size[1] / bgSize[1])]
let mkLines = @(lines) lines.map(@(v, i) 100.0 * v / bgSize[i % 2])

let mkIcon = @(img) {
  size = [imgSize, imgSize]
  margin = [0, 0, 0, 0.2 * imgSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"{img}:{imgSize}:{imgSize}")
  keepAspect = KEEP_ASPECT_FIT
}

let mkText = @(text) {
  rendObj = ROBJ_TEXT
  text
  color = 0xFFFFFFFF
}.__update(adaptiveFont)

let mkRow = @(children) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children
}

let mkCol = @(children) {
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children
}

let turretY1 = 590
let turretY2 = topRowY
let turretHint = {
  header = "help/mainTurrets"
  color = 0xFFA8A3FF
  content = mkCol([
      mkRow([mkText($"{loc("fire_chance")}{colon}5%"), mkIcon("ui/gameuiskin#hud_debuff_fire.svg")])
      mkRow([mkText($"{loc("shop/shotFreq")}{colon}-50%"), mkIcon("ui/gameuiskin#hud_debuff_weapon.svg")])
    ])
}

let ammoY1 = 740
let ammoY2 = 590
let ammoHint = {
  header = "help/ship/ammo_storage"
  color = 0xFFC958CD
  content = mkRow([mkText(loc("help/explosion_damage")), mkIcon("ui/gameuiskin#dmg_ship_explosion.svg")])
}

let elevatorY1 = 665
let elevatorY2 = 425
let elevatorHint = {
  header = "dmg_msg_short/ship_elevator"
  color = 0xFFF94984
  content = mkRow([mkText($"{loc("shop/shotFreq")}{colon}-50%"), mkIcon("ui/gameuiskin#hud_debuff_weapon.svg")])
}

let hints = [
  turretHint.__merge({
    lines = mkLines([900, turretY1, 900, turretY2])
    pos = mkSizeByParent([900 + offsetX, turretY2])
    blockOvr = { hplace = ALIGN_RIGHT, vplace = ALIGN_BOTTOM }
  })
  turretHint.__merge({
    lines = mkLines([2350, turretY1, 2350, turretY2])
    pos = mkSizeByParent([2350 - offsetX, turretY2])
    blockOvr = { vplace = ALIGN_BOTTOM }
  })
  elevatorHint.__merge({
    lines = mkLines([830, elevatorY1, 830, elevatorY2])
    pos = mkSizeByParent([830 + offsetX, elevatorY2])
    blockOvr = { hplace = ALIGN_RIGHT, vplace = ALIGN_BOTTOM }
  })
  elevatorHint.__merge({
    lines = mkLines([2420, elevatorY1, 2420, elevatorY2])
    pos = mkSizeByParent([2420 - offsetX, elevatorY2])
    blockOvr = { vplace = ALIGN_BOTTOM }
  })
  ammoHint.__merge({
    lines = mkLines([925, ammoY1, 680, ammoY1, 680, ammoY2])
    pos = mkSizeByParent([680 + offsetX, ammoY2])
    blockOvr = { hplace = ALIGN_RIGHT, vplace = ALIGN_BOTTOM, fillColor }
  })
  ammoHint.__merge({
    lines = mkLines([2335, ammoY1, 2565, ammoY1, 2565, ammoY2])
    pos = mkSizeByParent([2565 - offsetX, ammoY2])
    blockOvr = { vplace = ALIGN_BOTTOM, fillColor }
  })
  {
    header = "help/funnels"
    color = 0xFF00FF00
    content = mkRow([mkText($"{loc("shop/max_speed")} -25%"),
      mkIcon("ui/gameuiskin#hud_arrow_stat_up.svg").__update({ transform = { rotate = 180 } })])
    lines = mkLines([1760, 504, 1630, 504, 1630, 450])
    pos = mkSizeByParent([1630 + offsetX, 450])
    blockOvr = { hplace = ALIGN_RIGHT, vplace = ALIGN_BOTTOM, fillColor }
  }
  {
    header = "help/bowSuperstructure"
    color = 0xFFFFF15B
    content = mkCol([
      mkRow([mkText($"{loc("fire_chance")}{colon}5%"), mkIcon("ui/gameuiskin#hud_debuff_fire.svg")])
      mkRow([mkText(loc("help/loss_of_control")), mkIcon("ui/gameuiskin#hud_debuff_control.svg")])
    ])
    lines = mkLines([1940, 420, 1940, topRowY])
    blockOvr = { hplace = ALIGN_CENTER, vplace = ALIGN_BOTTOM, fillColor }
  }
  {
    header = "dmg_msg_short/ship_steering_gear"
    color = 0xFF00FFA2
    content = mkRow([mkText(loc("help/loss_of_control")), mkIcon("ui/gameuiskin#hud_debuff_control.svg")])
    lines = mkLines([500, 758, 500, bottomRowY])
    pos = mkSizeByParent([600, bottomRowY])
    blockOvr = { hplace = ALIGN_CENTER }
  }
  {
    header = "help/ship/torpedo_tubes"
    color = 0xFFFFA22A
    content = mkCol([
      mkRow([mkText($"{loc("shop/shotFreq")}{colon}-50%"), mkIcon("ui/gameuiskin#hud_debuff_weapon.svg")])
      mkRow([mkText(loc("help/explosion_damage")), mkIcon("ui/gameuiskin#dmg_ship_explosion.svg")])
    ])
    lines = mkLines([1358, 626, 1358, bottomRowY])
    pos = mkSizeByParent([1245, bottomRowY])
    blockOvr = { hplace = ALIGN_CENTER }
  }
  {
    header = "help/ship/engines"
    color = 0xFFF96649
    content = mkRow([mkText($"{loc("shop/max_speed")} -50%"), mkIcon("ui/gameuiskin#dmg_ship_engine.svg")])
    lines = mkLines([1757, 696, 1757, bottomRowY])
    pos = mkSizeByParent([1900, bottomRowY])
    blockOvr = { hplace = ALIGN_CENTER }
  }
  {
    header = "help/bottomCompartments"
    color = 0xFF4AD5E2
    content = mkRow([mkText(loc("flooding")), mkIcon("ui/gameuiskin#dmg_ship_breach.svg")])
    lines = mkLines([2717, 746, 2717, bottomRowY])
    pos = mkSizeByParent([2600, bottomRowY])
    blockOvr = { hplace = ALIGN_CENTER }
  }
  {
    header = "help/ship/auxTurrets"
    color = 0xFF4AAfE2
    content = mkCol([
      mkRow([mkText($"{loc("fire_chance")}{colon}5%"), mkIcon("ui/gameuiskin#hud_debuff_fire.svg")])
      mkRow([mkText($"{loc("shop/shotFreq")}{colon}-50%"), mkIcon("ui/gameuiskin#hud_debuff_weapon.svg")])
    ])
    lines = mkLines([1250, 590, 1100, 460, 1100, topRowY])
    pos = mkSizeByParent([1290, topRowY])
    blockOvr = { hplace = ALIGN_CENTER, vplace = ALIGN_BOTTOM, fillColor }
  }
]

let allLines = {
  size = flex()
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth
  commands = hints.reduce(function(res, h) {
    if ("lines" not in h)
      return res
    if ("color" in h)
      res.append([VECTOR_COLOR, h.color])
    res.append([VECTOR_LINE].extend(h.lines))
    return res
  }, [])
}

let mkHeader = @(header, color) {
  margin = hdpx(5)
  maxWidth = hdpx(430)
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = utf8ToUpper(loc(header))
  color = color
  halign = ALIGN_CENTER
}.__update(adaptiveFont)

let function mkHintBlock(hint) {
  let { lines = null, color = 0xFFFFFFFF, header = null, content = null, blockOvr = {} } = hint
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
      halign = ALIGN_CENTER
      padding = blockPadding
      flow = FLOW_VERTICAL
      children = [
        header != null ? mkHeader(header, color) : null
        content
      ]
    }.__update(blockOvr)
  }
}

let function mkTgtPoint(hint) {
  let { lines = null, color = 0xFFFFFFFF } = hint
  if (lines == null)
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

function makeScreen() {
  return {
    size = [sw(100), sh(100)]
    rendObj = ROBJ_SOLID
    color = 0xFF000000
    children = {
      size = [sw(100), sw(100).tofloat() / bgSize[0] * bgSize[1]]
      pos = [0, -sh(1.5)]
      rendObj = ROBJ_IMAGE
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      image = Picture(bgImage)
      children = [allLines]
        .extend(hints.map(mkTgtPoint))
        .extend(hints.map(mkHintBlock))
    }
  }
}

return makeScreen
