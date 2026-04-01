from "%globalsDarg/darg_library.nut" import *
from "%globalsDarg/fontScale.nut" import scaleFontWithTransform
from "%rGui/components/currencyStyles.nut" import CS_COMMON
from "%rGui/textFormatByLang.nut" import decimalFormat
from "%rGui/hud/localMPlayer.nut" import mySpawnScore, addMPlayerUpdater, removeMPlayerUpdater
from "%rGui/respawn/respawnState.nut" import isUseSpawnScore


let hudStyle = CS_COMMON.__merge({ fontStyle = fontSmallShaded })

let scoreUpdater = {
  size = 0 
  key = "spawnScoreBalanceUpdater"
  onAttach = @() addMPlayerUpdater("spawnScoreBalance")
  onDetach = @() removeMPlayerUpdater("spawnScoreBalance")
}

let mkSpawnScore = @(value, style, ovr = {}, addChild = null) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = style.iconGap
  children = [
    {
      size = style.iconSize
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#icon_spawn_points.svg:{style.iconSize}:P")
      keepAspect = true
      children = addChild
    }
    {
      rendObj = ROBJ_TEXT
      text = decimalFormat(value)
      color = style.textColor
    }.__update(style.fontStyle)
  ]
}.__update(ovr)

let mkSpawnScoreBalance = @(style = CS_COMMON) @() !isUseSpawnScore.get()
  ? { watch = isUseSpawnScore }
  : mkSpawnScore(mySpawnScore.get(), style,
      { watch = [mySpawnScore, isUseSpawnScore] },
      scoreUpdater)

function mkHudSpawnScore(scale, valueW) {
  let font = scaleFontWithTransform(hudStyle.fontStyle, scale)
  let size = (hudStyle.iconSize * scale + 0.5).tointeger()
  let gap = (hudStyle.iconGap * scale + 0.5).tointeger()
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap
    children = [
      {
        size
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#icon_spawn_points.svg:{size}:P")
        keepAspect = true
        children = scoreUpdater
      }
      @() {
        watch = valueW
        rendObj = ROBJ_TEXT
        text = decimalFormat(valueW.get())
        color = hudStyle.textColor
      }.__update(font)
    ]
  }
}

return {
  mkSpawnScore
  mkSpawnScoreBalance
  spawnScoreBalance = mkSpawnScoreBalance(CS_COMMON)
  spawnScoreEditView = mkHudSpawnScore(1.0, Watched(900))
  hudSpawnScoreCtor = @(scale) mkHudSpawnScore(scale, mySpawnScore)
}