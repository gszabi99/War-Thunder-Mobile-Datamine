from "%globalsDarg/darg_library.nut" import *
let { CaptureZone } = require("wt.behaviors")
let { capZones, capZonesCount } = require("%rGui/hud/capZones/capZonesState.nut")
let { capZoneCtr, getZoneIcon } = require("%rGui/hud/capZones/capZones.nut")
let { round_by_value } = require("%sqstd/math.nut")

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
  watch = capZonesCount
  children = array(capZonesCount.get()).map(@(_, i) mkCapZoneIndicator(i))
}

return captureZoneIndicators
