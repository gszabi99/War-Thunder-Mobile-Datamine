from "%globalsDarg/darg_library.nut" import *
let { NODE_SELF, NODE_ORDER_RETURN, NODE_ORDER_POINT, NODE_ORDER_ATTACK,
  NODE_ORDER_DEFEND, NODE_ORDER_HUNT, NODE_ORDER_ORBIT
} = require("guiStrategyMode")
let supportPlaneConfig = require("%rGui/hud/supportPlaneConfig.nut")

const edgeColorDefault = 0x40000000
const edgeColorSelectedDefault = 0x40000000
const edgeColorPending = 0x40000000
const edgeButtonColor = 0x40808080

const iconColorDefault = 0xFFFFFFFF
const iconShip = "ui/gameuiskin#hud_ship_selection.svg"
const iconPoint = "ui/gameuiskin#data_mark_geo.svg"
const iconInsert = "ui/gameuiskin#data_mark_geo.svg"
const iconClear = "ui/gameuiskin#data_mark_geo.svg"
const iconAttack = "ui/gameuiskin#lb_battles_icon.svg"
const iconDefend = "ui/gameuiskin#data_mark_defence.svg"
const iconHunt = "ui/gameuiskin#hud_target_tracking.svg"
const debugIconWarning = "ui/gameuiskin#icon_primary_attention.svg"
const debugTextColor = 0x40404040

local airGroupButtonWidth = hdpx(320)
local airGroupButtonHeight = shHud(8)

enum AIR_GROUP_TYPE {
  SHIP_SELF
  PLANE_FIGHTER
  PLANE_BOMBER
  PLANE_DIVE_BOMBER
  UNKNOWN
}

let nodesStyleUnknown = {
  icon = debugIconWarning
  color = 0xFFFF00FF
  size = hdpx(100)
  padding = 0
  border = true
  rotate = 0
  opacity = 1
  edgeColor = 0x80FF00FF
  edgeColorSelected = 0x80FF00FF
  valign = ALIGN_CENTER
}

let nodesStyle = {
  [NODE_SELF] = {
    icon = iconShip
    color = iconColorDefault
    size = hdpx(65)
    padding = hdpx(30)
    border = true
    rotate = 45
    opacity = 0.75
    edgeColor = edgeColorDefault
    edgeColorSelected = edgeColorSelectedDefault
    valign = ALIGN_BOTTOM
  },
  [NODE_ORDER_RETURN] = {
    icon = iconShip
    color = iconColorDefault
    size = hdpx(100)
    padding = hdpx(20)
    border = false
    rotate = 0
    opacity = 0.75
    edgeColor = 0x80004000
    edgeColorSelected = 0x80004000
    valign = ALIGN_BOTTOM
  },
  [NODE_ORDER_POINT] = {
    icon = iconPoint
    color = iconColorDefault
    size = hdpx(100)
    padding = hdpx(10)
    border = false
    rotate = 0
    opacity = 1
    edgeColor = edgeColorDefault
    edgeColorSelected = edgeColorSelectedDefault
    valign = ALIGN_BOTTOM
  },
  [NODE_ORDER_ATTACK] = {
    icon = iconAttack
    color = 0xFFC04040
    size = hdpx(100)
    padding = hdpx(20)
    border = false
    rotate = 0
    opacity = 0.75
    edgeColor = edgeColorDefault
    edgeColorSelected = edgeColorSelectedDefault
    valign = ALIGN_TOP
  },
  [NODE_ORDER_DEFEND] = {
    icon = iconDefend
    color = 0xFF40C040
    size = hdpx(100)
    padding = hdpx(20)
    border = false
    rotate = 0
    opacity = 0.75
    edgeColor = edgeColorDefault
    edgeColorSelected = edgeColorSelectedDefault
    valign = ALIGN_TOP
  },
  [NODE_ORDER_HUNT] = {
    icon = iconHunt
    color = 0xFFF0C080
    size = hdpx(100)
    padding = hdpx(5)
    border = false
    rotate = 0
    opacity = 0.75
    edgeColor = 0xC0402000
    edgeColorSelected = 0xC0603000
    valign = ALIGN_TOP
  },
  [NODE_ORDER_ORBIT] = {
    icon = iconPoint
    color = 0xFFF0C080
    size = hdpx(100)
    padding = hdpx(5)
    border = false
    rotate = 0
    opacity = 0.75
    edgeColor = 0xC0402000
    edgeColorSelected = 0xC0603000
    valign = ALIGN_TOP
  }
}

let airGroupIcons = supportPlaneConfig.reduce(@(res, v, i) res.$rawset(i, v.image),
  { [-1] = iconShip })

let airGroupAttackIcons = {
  [AIR_GROUP_TYPE.SHIP_SELF] = iconAttack,
  [AIR_GROUP_TYPE.PLANE_FIGHTER] = iconAttack,
  [AIR_GROUP_TYPE.PLANE_BOMBER] = "ui/gameuiskin#hud_bomb.svg",
  [AIR_GROUP_TYPE.PLANE_DIVE_BOMBER] = "ui/gameuiskin#hud_torpedo.svg",
}

function getNodeStyle(nodeType) {
  local style = nodesStyle?[nodeType] ?? nodesStyleUnknown
  return style
}

return {
  getNodeStyle

  edgeColorDefault
  edgeColorSelectedDefault
  edgeColorPending
  edgeButtonColor

  iconShip
  iconPoint
  iconInsert
  iconClear
  iconAttack
  iconDefend
  iconHunt

  debugIconWarning
  debugTextColor

  AIR_GROUP_TYPE

  airGroupIcons
  airGroupAttackIcons
  airGroupButtonWidth
  airGroupButtonHeight
}
