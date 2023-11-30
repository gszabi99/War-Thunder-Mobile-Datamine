let { loc } = require("dagor.localize")
let { parse_unix_time } = require("dagor.iso8601")
let { secondsToTimeFormatString, roundTime } = require("%sqstd/time.nut")

let timeSubst = [ "days", "hours", "minutes", "seconds" ].map(@(v) [ v, loc($"measureUnits/{v}") ]).totable()
let secondsToTimeAbbrString = @(t) secondsToTimeFormatString(t < 3600 ? t : (t / 60 * 60)).subst(timeSubst)
let secondsToHoursLoc = @(time) secondsToTimeFormatString(roundTime(time)).subst(timeSubst)

let parseCache = {}
let function parseUnixTimeCached(timeStr) {
  if (timeStr not in parseCache)
    parseCache[timeStr] <- parse_unix_time(timeStr)
  return parseCache[timeStr]
}

return {
  secondsToTimeAbbrString
  secondsToHoursLoc
  parseUnixTimeCached
}
