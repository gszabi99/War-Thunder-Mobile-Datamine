from "%globalsDarg/darg_library.nut" import *
let { gradTranspDoubleSideX } = require("%rGui/style/gradients.nut")

let rowGap = hdpx(27)
let resultLineWidth = hdpx(1450)
let resultLineHeight = hdpx(9)
let lineGlowHeight = 10 * resultLineHeight
let lineGlowWidth = (201.0 / 84.0 * lineGlowHeight).tointeger()

let resultTextAnimTime = 0.6
let glowAnimTime = 1.0
let glowAppearAnimTime = 0.2

let missionResultTitleAnimTime = max(resultTextAnimTime, glowAnimTime)

let missionResultParamsByType = {
  victory = {
    text = @(_) loc("debriefing/victory")
    color = 0xFFFFB70B
    animTextColor = 0xFFFFDA83
  }
  defeat = {
    text = @(_) loc("debriefing/defeat")
    color = 0xFFFB5F28
    animTextColor = 0xFFFFA07F
  }
  inProgress = {
    text = @(campaign) loc(campaign == "tanks" ? "debriefing/yourPlatoonDestroyed" : "debriefing/yourShipDestroyed")
    color = 0xFFFFFFFF
    animTextColor =  0xFFFFFFFF
  }
  deserter = {
    text = @(_) loc("debriefing/deserter")
    color = 0xFFFB5F28
    animTextColor = 0xFFFFA07F
  }
  disconnect = {
    text = @(_) loc("matching/CLIENT_ERROR_CONNECTION_CLOSED")
    color = 0XFFFFA406
    animTextColor = 0XFFFFA406
  }
  unknown = {
    text = @(_) loc("debriefing/dataNotReceived")
    color =  0xFFFFFFFF
    animTextColor =  0xFFFFFFFF
  }
}

let mkMissionResultText = @(needAnim, missionResult, campaign) {
  rendObj = ROBJ_TEXT
  color = missionResult.color
  text = missionResult.text(campaign)
  transform = !needAnim ? null : {}
  animations = !needAnim ? null : [
    {
      prop = AnimProp.scale, from = [1.0, 1.0], to = [1.3, 1.3],
      duration = resultTextAnimTime, play = true, easing = CosineFull
    }
    {
      prop = AnimProp.color, from = missionResult.color, to = missionResult.animTextColor,
      duration = resultTextAnimTime, play = true, easing = CosineFull
    }
  ]
}.__update(fontBig)

let mkMissionResultLine = @(needAnim, missionResult) {
  size = [resultLineWidth, resultLineHeight]
  hplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = gradTranspDoubleSideX
  color = missionResult.color
  children = !needAnim ? null : {
    size = [lineGlowWidth, lineGlowHeight]
    vplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = Picture("!ui/gameuiskin#line_glow.avif")
    opacity = 0.0
    transform = {}
    animations = [
      {
        prop = AnimProp.translate, from = [-0.5 * lineGlowWidth, 0], to = [resultLineWidth - lineGlowWidth, 0],
        duration = glowAnimTime, play = true
      }
      {
        prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = glowAppearAnimTime,
        play = true
      }
      {
        prop = AnimProp.opacity, from = 1.0, to = 1.0,
        duration = glowAnimTime - 2 * glowAppearAnimTime,
        delay = glowAppearAnimTime, play = true
      }
      {
        prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = glowAppearAnimTime,
        delay = glowAnimTime - glowAppearAnimTime, play = true
      }
    ]
  }
}

let function mkMissionResultTitle(debrData, needAnim) {
  let { isWon = false, isFinished = false, isDeserter = false, isDisconnected = false, campaign = "" } = debrData
  let missionResult = debrData == null ? missionResultParamsByType.unknown
    : isDisconnected ? missionResultParamsByType.disconnect
    : isDeserter ? missionResultParamsByType.deserter
    : !isFinished ? missionResultParamsByType.inProgress
    : isWon ? missionResultParamsByType.victory
    : missionResultParamsByType.defeat
  return {
    size = [flex(), SIZE_TO_CONTENT]
    margin = [0, 0, hdpx(32), 0]
    children = [
      {
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        hplace = ALIGN_CENTER
        gap = rowGap
        children = [
          mkMissionResultText(needAnim, missionResult, campaign)
          mkMissionResultLine(needAnim, missionResult)
        ]
      }
    ]
  }
}

return {
  mkMissionResultTitle
  missionResultTitleAnimTime
}
