from "%globalsDarg/darg_library.nut" import *
let { CaptureZone } = require("wt.behaviors")
let { capZones, capZonesCount } = require("capZonesState.nut")
let { capZoneCtr, getZoneIcon } = require("capZonesList.ui.nut")
let { round_by_value } = require("%sqstd/math.nut")

let zoneSize = evenPx(45)

function mkCapZoneIndicator(idx) {
  let zone = Computed(@() capZones.value?[idx])
  return function() {
    local res = { watch = zone }
    if (zone.value == null)
      return res
    let { id, iconIdx, distance } = zone.value
    res.__update({
      behavior = CaptureZone
      zoneId = id
      stringToHide = "distance_string"
      transform = {}
      size = [0, 0]
      valign = ALIGN_BOTTOM
      halign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      gap = hdpx(10)
      children =[
        capZoneCtr(zone.value).__update({
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
  children = array(capZonesCount.value).map(@(_, i) mkCapZoneIndicator(i))
}

return captureZoneIndicators
