from "%globalsDarg/darg_library.nut" import *
let { fabs } = require("math")
let { capZones, capZonesCount } = require("capZonesState.nut")
let { localMPlayerTeam } = require("%appGlobals/clientState/clientState.nut")
let { teamBlueColor, teamRedColor } = require("%rGui/style/teamColors.nut")


let zoneSizeBase = evenPx(50)
let bigZoneMul = 2
let neutralColor = 0xFFFFFFFF
const MP_TEAM_NEUTRAL = 0

let getZoneIcon = @(i, size)
  Picture($"ui/gameuiskin#basezone_small_mark_{('a' + i).tochar()}.svg:{size}:{size}")

let zoneColor = @(team, localTeam) team == MP_TEAM_NEUTRAL ? neutralColor
  : team == localTeam ? teamBlueColor
  : teamRedColor

function capZoneCtr(zone) {
  let res = {}
  let { mpTimeX100 } = zone
  let progress = fabs(0.01 * mpTimeX100)
  let team = mpTimeX100 == 0 ? MP_TEAM_NEUTRAL : mpTimeX100 > 0 ? 2 : 1
  let teamColor = zoneColor(team, localMPlayerTeam.value)
  let isClockwise = team == localMPlayerTeam.value || team == MP_TEAM_NEUTRAL
  return res.__update({
    rendObj = ROBJ_PROGRESS_CIRCULAR
    keepAspect = true
    fgColor = isClockwise ? teamColor : neutralColor
    bgColor = isClockwise ? neutralColor : teamColor
    fValue = isClockwise ? progress : (1.0 - progress)
    transitions = [
      { prop = AnimProp.scale, duration = 0.5, easing = InOutQuad }
      { prop = AnimProp.opacity, duration = 0.5, easing = InOutQuad }
    ]
  })
}

function mkCapZone(idx, zoneSize) {
  let zone = Computed(@() capZones.get()?[idx])
  return function() {
    local res = { watch = [zone, localMPlayerTeam] }
    if (zone.value == null)
      return res
    let { iconIdx, watchedHeroInZone } = zone.value
    res.__update(
      capZoneCtr(zone.value).__update({
        size = [zoneSize, zoneSize]
        image = getZoneIcon(iconIdx, zoneSize * bigZoneMul)
        transform = {
          pivot = [0.5, 0],
          scale = watchedHeroInZone ? [bigZoneMul, bigZoneMul] : [1.0, 1.0]
        }
      }))
    return res
  }
}

function capZonesList(scale) {
  let zoneSize = scaleEven(zoneSizeBase, scale)
  return @() {
    key = "capture_zones"
    watch = capZonesCount
    size = capZonesCount.value > 0 ? [SIZE_TO_CONTENT, zoneSize * bigZoneMul] : null
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    children = array(capZonesCount.get()).map(@(_, i) mkCapZone(i, zoneSize))
  }
}

let capZonesEditView = {
  size = [SIZE_TO_CONTENT, zoneSizeBase * bigZoneMul]
  flow = FLOW_HORIZONTAL
  gap = hdpx(10)
  children = array(3).map(@(_, i) i != 1
    ? {
        rendObj = ROBJ_IMAGE
        size = [zoneSizeBase, zoneSizeBase]
        image = getZoneIcon(i, zoneSizeBase)
      }
    : {
        rendObj = ROBJ_IMAGE
        size = [zoneSizeBase, zoneSizeBase]
        image = getZoneIcon(i, zoneSizeBase * bigZoneMul)
        transform = {
          pivot = [0.5, 0],
          scale = [bigZoneMul, bigZoneMul]
        }
      })
}

return {
  capZonesList
  capZoneCtr
  getZoneIcon
  capZonesEditView
}