from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
from "crosshair" import get_hud_crosshair_type, set_hud_crosshair_type
from "eventbus" import eventbus_send
from "%appGlobals/loginState.nut" import isSettingsAvailable
from "%rGui/hud/hudConfigParameters.nut" import getHudConfigParameter


const btnH = hdpx(103)

let aircraftCrosshairTypesList = getHudConfigParameter("crosshairAir")
const defaultIndex = 0

let mkImage = @(img, size) {
  size = const [FLEX, btnH]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    size
    rendObj = ROBJ_IMAGE
    keepAspect = true
    image = img
  }
}

let getCrosshairIconCfg = memoize(function(id) {
  local parts = id.split(":")
  return {
    size = [oddPx(parts?[1].tointeger() ?? 23), oddPx(parts?[2].tointeger() ?? 23)]
    icon = $"ui/gameuiskin#{parts[0]}"
  }
})

function mkImageContent(value) {
  let { icon, size } = getCrosshairIconCfg(value)
  return mkImage(Picture(icon), size)
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

let currentCrosshairType = mkCrosshairTypeValue(defaultIndex,
  @(idx) aircraftCrosshairTypesList?[idx] ? idx : defaultIndex)
let currentCrosshairIconCfg = Computed(@() getCrosshairIconCfg(aircraftCrosshairTypesList[currentCrosshairType.get()]))

let crosshairType = {
  locId = $"options/crosshairType"
  ctrlType = OCT_LIST
  value = currentCrosshairType
  list = aircraftCrosshairTypesList.map(@(_, idx) idx)
  mkContentCtor = @(v, _, _) mkImageContent(aircraftCrosshairTypesList?[v])
  columnsMaxCustom = 6
}

return {
  crosshairOptions = [
    crosshairType
  ]
  currentCrosshairIconCfg
}