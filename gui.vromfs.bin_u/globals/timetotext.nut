let { loc } = require("dagor.localize")
let { parse_unix_time } = require("dagor.iso8601")
let { fabs } = require("math")
let { format } =  require("string")
let { secondsToTimeFormatString, roundTime } = require("%sqstd/time.nut")

let timeSubst = [ "days", "hours", "minutes", "seconds" ].map(@(v) [ v, loc($"measureUnits/{v}") ]).totable()
let secondsToTimeAbbrString = @(t) secondsToTimeFormatString(t < 3600 ? t : (t / 60 * 60)).subst(timeSubst)
let secondsToHoursLoc = @(time) secondsToTimeFormatString(roundTime(time)).subst(timeSubst)

let parseCache = {}
function parseUnixTimeCached(timeStr) {
  if (timeStr not in parseCache)
    parseCache[timeStr] <- parse_unix_time(timeStr)
  return parseCache[timeStr]
}

function preciseSecondsToString(value, canShowZeroMinutes = true) {
  value = value != null ? value.tofloat() : 0.0
  let sign = value >= 0 ? "" : loc("ui/minus")
  local ms = (fabs(value) * 1000.0 + 0.5).tointeger()
  let mm = ms / 60000
  let ss = ms % 60000 / 1000
  ms = ms % 1000

  if (!canShowZeroMinutes && mm == 0)
    return format("%s%d.%03d", sign, ss, ms)

  return format("%s%d:%02d.%03d", sign, mm, ss, ms)
}

return {
  secondsToTimeAbbrString
  secondsToHoursLoc
  parseUnixTimeCached
  preciseSecondsToString
}
