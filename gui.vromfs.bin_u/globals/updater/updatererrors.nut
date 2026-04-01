let contentUpdater = require("contentUpdater")

let errorNames = {}
foreach(id, val in contentUpdater)
  if (type(val) != "integer")
    continue
  else if (id.startswith("UPDATER_ERROR"))
    errorNames[val] <- id

return {
  getErrorName = @(v) errorNames?[v] ?? v
}
