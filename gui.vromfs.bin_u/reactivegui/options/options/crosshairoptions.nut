from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { eventbus_send } = require("eventbus")
let { isSettingsAvailable } = require("%appGlobals/loginState.nut")
let { get_hud_crosshair_type, set_hud_crosshair_type } = require("crosshair")
let { getHudConfigParameter } = require("%rGui/hud/hudConfigParameters.nut")

let btnH = hdpx(103)

let mkImage = @(img, size) {
  size = [flex(), btnH]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    size
    rendObj = ROBJ_IMAGE
    keepAspect = true
    image = img
  }
}

function mkImageContent(value) {
  function mkImageSize(path) {
    local parts = path.tostring().split(":")
    return [hdpx(parts?[1].tointeger() ?? flex()), hdpx(parts?[2].tointeger() ?? (btnH / 2))]
  }
  return mkImage(Picture($"ui/gameuiskin#{value}"), mkImageSize(value))
}

function mkCrosshairTypeValue(defValue, validate) {
  let getSaved = @() validate(get_hud_crosshair_type() ?? defValue)
  let value = Watched(isSettingsAvailable.get() ? getSaved() : validate(defValue))
  function updateSaved() {
    if (!isSettingsAvailable.get() || get_hud_crosshair_type() == value.get())
      return
    set_hud_crosshair_type(value.get())
    eventbus_send("saveProfile", {})
  }
  updateSaved()
  isSettingsAvailable.subscribe(function(_) {
    value.set(getSaved())
    updateSaved()
  })
  value.subscribe(@(_) updateSaved())
  return value
}

let aircraftCrosshairTypesList = getHudConfigParameter("crosshair")
let defaultIndex = 0
let currentCrosshairType = mkCrosshairTypeValue(defaultIndex,
  @(idx) aircraftCrosshairTypesList?[idx] ? idx : defaultIndex)
let crosshairType = {
  locId = $"options/crosshairType"
  ctrlType = OCT_LIST
  value = Computed(@() aircraftCrosshairTypesList?[currentCrosshairType.get()] ?? defaultIndex)
  list = aircraftCrosshairTypesList
  mkContentCtor = @(v, _, _) mkImageContent(v)
  setValue = @(value) currentCrosshairType.set(aircraftCrosshairTypesList.findindex(@(v) v == value))
}

return {
  crosshairOptions = [
    crosshairType
  ]
}