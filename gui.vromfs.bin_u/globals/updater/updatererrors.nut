import "contentUpdater" as contentUpdater
from "types" import Integer


let errorNames = {}
foreach(id, val in contentUpdater)
  if (!(val instanceof Integer))
    continue
  else if (id.startswith("UPDATER_ERROR"))
    errorNames[val] <- id

return {
  getErrorName = @(v) errorNames?[v] ?? v
}
