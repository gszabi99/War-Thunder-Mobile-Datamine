let DataBlock = require("DataBlock")

let configParameters = {
  degreeRemainingHealthPlayer = 1.0
  targetSelectionRelativeSize = 0.3
  distanceViewMultiplier = 1.0
  changeDmPanelColorDependingOnHp = false
  showDamageLog = false
  crosshair = []
}

let customLoad = {
  function crosshair(key, blk) {
    configParameters[key] = blk?.crosshair % "pictureTpsView"
  }
}

local isInited = false

function initOnce() {
  let blk = DataBlock()
  if (!blk.tryLoad("wtm/config/hud.blk"))
    return

  isInited = true
  foreach (key, value in configParameters) {
    if (key in customLoad)
      customLoad[key](key, blk)
    else
      configParameters[key] = blk?[key] ?? value
  }
}

function getHudConfigParameter(id) {
  if (!isInited)
    initOnce()

  return configParameters[id]
}

return {
  getHudConfigParameter
}
