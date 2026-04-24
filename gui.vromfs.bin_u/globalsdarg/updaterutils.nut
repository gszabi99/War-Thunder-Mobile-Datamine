from "%globalsDarg/darg_library.nut" import *
let { round_by_value } = require("%sqstd/math.nut")
let { secondsToTimeSimpleString } = require("%sqstd/time.nut")

let KB = 1 << 10
let MB = 1 << 20
let GB = 1 << 30

let totalSizeText = @(bytes) bytes > 10 * GB ? "".concat(round_by_value(bytes.tofloat() / GB, 0.1), loc("measureUnits/GB"))
  : bytes > 10 * MB ? "".concat((bytes + (MB / 2)) / MB, loc("measureUnits/MB"))
  : bytes > 500 * KB ? "".concat(round_by_value(bytes.tofloat() / MB, 0.1), loc("measureUnits/MB"))
  : bytes > KB ? "".concat((bytes + (KB / 2)) / KB, loc("measureUnits/KB"))
  : "".concat(bytes == 0 ? 0 : 1, loc("measureUnits/KB"))

let speedWithText = @(speed, locId) "".concat(round_by_value(speed, 0.1), loc(locId))
let getDSpeedText = @(dspeed)
  dspeed > 0.5 * GB ? speedWithText(dspeed.tofloat() / GB, "updater/dspeed/gb")
    : dspeed > 0.5 * MB ? speedWithText(dspeed.tofloat() / MB, "updater/dspeed/mb")
    : dspeed > 0.5 * KB ? speedWithText(dspeed.tofloat() / KB, "updater/dspeed/kb")
    : speedWithText(dspeed, "updater/dspeed/b")

let getDownloadInfoText = @(downloadSize, etaSec, dspeed)
  comma.join([
    downloadSize <= 0 ? "" : totalSizeText(downloadSize)
    dspeed <= 0 || etaSec <= 0 ? "" : secondsToTimeSimpleString(etaSec)
    dspeed <= 0 ? "" : getDSpeedText(dspeed)
  ], true)

return {
  getDownloadInfoText
  totalSizeText
  KB
  MB
  GB
}