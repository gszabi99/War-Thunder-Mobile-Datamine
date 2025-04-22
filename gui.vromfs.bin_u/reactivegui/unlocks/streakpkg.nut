from "%globalsDarg/darg_library.nut" import *
let { streakPresentation } = require("%appGlobals/config/streakPresentation.nut")
let { format } = require("string")

let multiStageUnlockIdConfig = {
  multi_kill_air =    { [2] = "double_kill_air",    [3] = "triple_kill_air",    def = "multi_kill_air" }
  multi_kill_ship =   { [2] = "double_kill_ship",   [3] = "triple_kill_ship",   def = "multi_kill_ship" }
  multi_kill_ground = { [2] = "double_kill_ground", [3] = "triple_kill_ground", def = "multi_kill_ground" }
}

function getMultiStageUnlockId(unlockId, repeatInARow) {
  if (unlockId not in multiStageUnlockIdConfig)
    return unlockId

  let config = multiStageUnlockIdConfig[unlockId]
  return config?[repeatInARow] ?? config?.def ?? unlockId
}

function getUnlockLocText(unlockId, repeatInARow) {
  local text = loc($"streaks/{unlockId}")
  if (repeatInARow != null)
    text = format(text, repeatInARow)
  return text
}

function getUnlockDescLocText(unlockId, repeatInARow) {
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

function mkStackImage(imgData, override = {}) {
  let { img, params = {} } = imgData
  return mkImage(img, params.__update(override))
}

function mkStreakIcon(unlockId, mSize, numParam = null) {
  let streak = streakPresentation(unlockId)
  let { bgImage = null, stackImages = [], numberCtor = null } = streak
  let children = []
  if (bgImage)
    children.append(mkImage(bgImage))
  children.extend(stackImages.map(@(imgData) mkStackImage(imgData)))
  if (numParam != null && numberCtor)
    children.append(mkStackImage(numberCtor(numParam)))
  return @() {
    vplace = ALIGN_CENTER
    size = [mSize, mSize]
    children
  }
}

let mkStreakWithMultiplier = @(unlockId, mult, mSize, numParam = null) {
  size = [mSize, mSize]
  children = [
    mkStreakIcon(unlockId, mSize, numParam)
    mult <= 1 ? null
      : {
          rendObj = ROBJ_TEXT
          text = mult
          halign = ALIGN_CENTER
          pos = [mSize * 0.8, mSize * 0.8]
        }.__update(fontVeryTinyAccented)
  ]
}

let prepareStreaksArray = @(streaks) streaks.reduce(function(res, val, id) {
    let { stages = {}, completed, wp } = val
    let isMulti = id in multiStageUnlockIdConfig
    let hasStages = stages.len() > 0
    if (hasStages && isMulti) {
      let perUnlock = wp / completed
      stages.each(function(value, stageStr) {
        let stage = stageStr.tointeger()
        let unlockId = getMultiStageUnlockId(id, stage)
        res.append({ id = unlockId, wp = perUnlock * value, stage, completed = value })
      })
    }
    else if (hasStages && !isMulti){
      local stage = stages.reduce(@(result, _value, stageStr) max(result, stageStr.tointeger()), 0)
      res.append(val.__merge({ id, stage }))
    }
    else if (!hasStages && isMulti) 
      res.append({ id = getMultiStageUnlockId(id, completed + 1), stage = completed + 1, wp })
    else
      res.append(val.__merge({ id }))
    return res
  }, [])

return {
  multiStageUnlockIdConfig
  mkStreakIcon
  mkStreakWithMultiplier
  getMultiStageUnlockId
  getUnlockLocText
  getUnlockDescLocText
  prepareStreaksArray
}
