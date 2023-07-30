let DataBlock = require("DataBlock")

let configParameters = {
  degreeRemainingHealthPlayer = 1.0
  targetSelectionRelativeSize = 0.3
  distanceViewMultiplier = 1.0
  changeDmPanelColorDependingOnHp = false
  showDamageLog = false
}

local isInited = false

let function initOnce() {
  let blk = DataBlock()
  if (!blk.tryLoad("wtm/config/hud.blk"))
    return

  isInited = true
  foreach (key, value in configParameters)
    configParameters[key] = blk?[key] ?? value
}

let function getHudConfigParameter(id) {
  if (!isInited)
    initOnce()

  return configParameters[id]
}

return {
  getHudConfigParameter
}

