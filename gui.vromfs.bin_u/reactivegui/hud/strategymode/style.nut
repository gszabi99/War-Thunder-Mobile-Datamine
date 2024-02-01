from "%globalsDarg/darg_library.nut" import *
let { NODE_SELF, NODE_ORDER_RETURN, NODE_ORDER_POINT, NODE_ORDER_ATTACK,
  NODE_ORDER_DEFEND, NODE_ORDER_HUNT
} = require("guiStrategyMode")
let supportPlaneConfig = require("%rGui/hud/supportPlaneConfig.nut")

const edgeColorDefault = 0x80000000
const edgeColorSelectedDefault = 0x80000000
const edgeColorPending = 0x40000000
const edgeButtonColor = 0x40808080

const iconColorDefault = 0xD0FFFFFF
const iconDebugWarning = "ui/gameuiskin#icon_primary_attention.svg"
const iconShip = "ui/gameuiskin#hud_ship_selection.svg"
const iconPoint = "ui/gameuiskin#data_mark_geo.svg"
const iconInsert = "ui/gameuiskin#data_mark_geo.svg"
const iconClear = "ui/gameuiskin#data_mark_geo.svg"
const iconAttack = "ui/gameuiskin#lb_battles_icon.svg"
const iconDefend = "ui/gameuiskin#data_mark_defence.svg"
const iconHunt = "ui/gameuiskin#hud_target_tracking.svg"

enum AIR_GROUP_TYPE {
  SHIP_SELF
  PLANE_FIGHTER
  PLANE_BOMBER
  PLANE_DIVE_BOMBER
  UNKNOWN
}

let nodesStyle = {
  [NODE_SELF] = {
    icon = iconShip
    color = iconColorDefault
    size = hdpx(65)
    border = true
    rotate = 45
    edgeColor = edgeColorDefault
    edgeColorSelected = edgeColorSelectedDefault
    valign = ALIGN_CENTER
  },
  [NODE_ORDER_RETURN] = {
    icon = iconShip
    color = iconColorDefault
    size = hdpx(100)
    border = false
    rotate = 0
    edgeColor = 0x80004000
    edgeColorSelected = edgeColorDefault
    valign = ALIGN_CENTER
  },
  [NODE_ORDER_POINT] = {
    icon = iconPoint
    color = iconColorDefault
    size = hdpx(100)
    border = false
    rotate = 0
    edgeColor = edgeColorDefault
    edgeColorSelected = edgeColorSelectedDefault
    valign = ALIGN_BOTTOM
  },
  [NODE_ORDER_ATTACK] = {
    icon = iconAttack
    color = 0xD0C04040
    size = hdpx(100)
    border = false
    rotate = 0
    edgeColor = edgeColorDefault
    edgeColorSelected = edgeColorSelectedDefault
    valign = ALIGN_BOTTOM
  },
  [NODE_ORDER_DEFEND] = {
    icon = iconDefend
    color = 0xD040C040
    size = hdpx(100)
    border = false
    rotate = 0
    edgeColor = edgeColorDefault
    edgeColorSelected = edgeColorSelectedDefault
    valign = ALIGN_BOTTOM
  },
  [NODE_ORDER_HUNT] = {
    icon = iconHunt
    color = 0xD0F0C080
    size = hdpx(100)
    border = false
    rotate = 0
    edgeColor = 0xC0402000
    edgeColorSelected = 0xC0603000
    valign = ALIGN_BOTTOM
  }
}

let nodesStyleUnknown = {
  icon = iconDebugWarning
  color = 0xFFFF00FF
  size = hdpx(100)
  border = true
  rotate = 0
  edgeColor = 0x80FF00FF
  edgeColorSelected = 0x80FF00FF
  valign = ALIGN_CENTER
}

let airGroupIcons = {
  [-1] = iconShip,
  [0] = supportPlaneConfig["EII_SUPPORT_PLANE"].image,
  [1] = supportPlaneConfig["EII_SUPPORT_PLANE_2"].image,
  [2] = supportPlaneConfig["EII_SUPPORT_PLANE_3"].image,
}

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

  iconDebugWarning
  iconShip
  iconPoint
  iconInsert
  iconClear
  iconAttack
  iconDefend
  iconHunt

  AIR_GROUP_TYPE

  airGroupIcons
  airGroupAttackIcons
}
