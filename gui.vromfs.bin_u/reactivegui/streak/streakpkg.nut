from "%globalsDarg/darg_library.nut" import *
let { streakPresentation } = require("streakPresentation.nut")
let { format } = require("string")

let multiStageUnlockIdConfig = {
  multi_kill_air =    { [2] = "double_kill_air",    [3] = "triple_kill_air",    def = "multi_kill_air" }
  multi_kill_ship =   { [2] = "double_kill_ship",   [3] = "triple_kill_ship",   def = "multi_kill_ship" }
  multi_kill_ground = { [2] = "double_kill_ground", [3] = "triple_kill_ground", def = "multi_kill_ground" }
}

let function getMultiStageUnlockId(unlockId, repeatInARow) {
  if (unlockId not in multiStageUnlockIdConfig)
    return unlockId

  let config = multiStageUnlockIdConfig[unlockId]
  return config?[repeatInARow] ?? config?.def ?? unlockId
}

let function getUnlockLocText(unlockId, repeatInARow) {
  local text = loc($"streaks/{unlockId}")
  if (repeatInARow != null)
    text = format(text, repeatInARow)
  return text
}

let function getUnlockDescLocText(unlockId, repeatInARow) {
  local text = loc($"streaks/{unlockId}/desc")
  if (repeatInARow != null)
    text = format(text, repeatInARow)
  return text
}

let mkImage = @(path, override = {}) {
  rendObj = ROBJ_IMAGE
  size = flex()
  image = Picture(path)
}.__update(override)

let function mkStackImage(imgData, override = {}) {
  let { img, params = {} } = imgData
  return mkImage(img, params.__update(override))
}

let function mkStreakIcon(unlockId, mSize) {
  let streak = streakPresentation(unlockId)
  let { bgImage = null, stackImages = [] } = streak
  return @() {
    vplace = ALIGN_CENTER
    size = [mSize, mSize]
    children = (bgImage == null ? [] : [mkImage(bgImage)])
      .extend(stackImages.map(@(imgData) mkStackImage(imgData)))
  }
}

let mkStreakWithMultiplier = @(unlockId, mult, mSize) {
  size = [mSize, mSize]
  children = [
    mkStreakIcon(unlockId, mSize)
    mult <= 1 ? null
      : {
          rendObj = ROBJ_TEXT
          text = mult
          halign = ALIGN_CENTER
          pos = [mSize * 0.8, mSize * 0.8]
        }
  ]
}


return {
  multiStageUnlockIdConfig
  mkStreakIcon
  mkStreakWithMultiplier
  getMultiStageUnlockId
  getUnlockLocText
  getUnlockDescLocText
}
