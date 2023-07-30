let loc = require("dagor.localize").loc
let { secondsToTimeFormatString, roundTime } = require("%sqstd/time.nut")

let timeSubst = [ "days", "hours", "minutes", "seconds" ].map(@(v) [ v, loc($"measureUnits/{v}") ]).totable()
let secondsToTimeAbbrString = @(t) secondsToTimeFormatString(t < 3600 ? t : (t / 60 * 60)).subst(timeSubst)
let secondsToHoursLoc = @(time) secondsToTimeFormatString(roundTime(time)).subst(timeSubst)

return {
  secondsToTimeAbbrString
  secondsToHoursLoc
}
