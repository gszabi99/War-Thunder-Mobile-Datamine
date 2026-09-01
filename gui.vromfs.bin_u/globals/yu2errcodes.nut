import "auth_wt" as auth_wt
from "types" import Integer


let { YU2_HOST_RESOLVE, YU2_TIMEOUT, YU2_SSL_ERROR } = auth_wt

let yu2Names = {}
foreach(id, val in auth_wt)
  if (val instanceof Integer && id.startswith("YU2_"))
    yu2Names[val] <- id

return {
  getYu2CodeName = @(code) yu2Names?[code] ?? $"YU2_{code}"
  yu2BadConnectionCodes = [YU2_TIMEOUT, YU2_HOST_RESOLVE, YU2_SSL_ERROR]
    .reduce(@(res, v) res.$rawset(v, true), {})
}