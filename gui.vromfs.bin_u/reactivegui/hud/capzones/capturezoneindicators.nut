from "%globalsDarg/darg_library.nut" import *
from "wt.behaviors" import CaptureZone
from "%sqstd/math.nut" import round_by_value
from "%rGui/hud/capZones/capZones.nut" import capZoneCtr, getZoneIcon
from "%rGui/hud/capZones/capZonesState.nut" import capZones, capZonesCount
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


let zoneSize = evenPx(45)

function mkCapZoneIndicator(idx) {
  let zone = Computed(@() capZones.get()?[idx])
  return function() {
    local res = { watch = zone }
    if (zone.get() == null || !zone.get().hasWorldMarkers)
      return res
    let { id, iconIdx, distance } = zone.get()
    res.__update({
      behavior = CaptureZone
      zoneId = id
      stringToHide = "distance_string"
      transform = {}
      size = 0
      valign = ALIGN_BOTTOM
      halign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      gap = hdpx(10)
      children =[
        capZoneCtr(zone.get()).__update({
          key = $"capture_zone_indicator_{idx}"
          size = [zoneSize, zoneSize]
          image = getZoneIcon(iconIdx, zoneSize)
          opacity = 0.8
        })
        {
          key = "distance_string"
          hplace = ALIGN_CENTER
          rendObj = ROBJ_TEXT
          text = $"{round_by_value(distance, 0.01)} {loc("measureUnits/km_dist")}"
        }.__update(fontVeryTiny)
      ]
    })
    return res
  }
}


let captureZoneIndicators = @() {
  key = "capture-zone-indicator"
  watch = capZonesCount
  children = array(capZonesCount.get()).map(@(_, i) mkCapZoneIndicator(i))
  animations = wndSwitchAnim
}

return captureZoneIndicators
