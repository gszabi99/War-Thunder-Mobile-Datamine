from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *

let { isGameAutoUpdateVisible, isGameAutoUpdateEnabled, gameAutoUpdateList } = require("gameAutoUpdateOption.nut")

let autoUpdateSetting = {
  locId = "options/autoUpdate"
  ctrlType = OCT_LIST
  value = isGameAutoUpdateEnabled
  list = gameAutoUpdateList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
}

return {
  systemOptions = [
    isGameAutoUpdateVisible ? autoUpdateSetting : null
  ]
}