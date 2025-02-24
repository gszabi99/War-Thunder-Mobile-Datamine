let auth_wt = require("auth_wt")
let { YU2_HOST_RESOLVE, YU2_TIMEOUT, YU2_SSL_ERROR } = auth_wt

let yu2Names = {}
foreach(id, val in auth_wt)
  if (type(val) == "integer" && id.startswith("YU2_"))
    yu2Names[val] <- id

return {
  getYu2CodeName = @(code) yu2Names?[code] ?? $"YU2_{code}"
  yu2BadConnectionCodes = [YU2_TIMEOUT, YU2_HOST_RESOLVE, YU2_SSL_ERROR]
    .reduce(@(res, v) res.$rawset(v, true), {})
}