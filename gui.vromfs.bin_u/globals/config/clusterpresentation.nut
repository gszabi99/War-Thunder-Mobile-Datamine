from "%globalScripts/logs.nut" import *
from "dagor.localize" import loc, doesLocTextExist


let namingRemap = {
  US = "NA"
  RU = "CIS"
}

function getClusterName(id) {
  let locId = $"cluster/{namingRemap?[id] ?? id}"
  return doesLocTextExist(locId) ? loc(locId) : id
}

function getClusterFullName(id) {
  let locId = $"cluster/{namingRemap?[id] ?? id}/full"
  return doesLocTextExist(locId) ? loc(locId) : getClusterName(id)
}

return {
  getClusterName
  getClusterFullName
}
