from "%globalsDarg/darg_library.nut" import *
let { subscribe } = require("eventbus")
let { format } = require("string")
let { isPlatformSony, isPlatformXboxOne, is_android
} = require("%appGlobals/clientState/platform.nut")

let state = Watched({
  fps = -1
  ping = -1
  pl = -1
  sessionId = ""
  latency = -1
  latencyA = -1
  latencyR = -1
})
subscribe("updateStatusString", @(s) state(s))

let comps = {}
foreach (key in ["ping", "pl", "sessionId", "latency", "latencyA", "latencyR"]) {
  let k = key
  comps[k] <- Computed(@() state.value[k])
}
let { ping, pl, sessionId, latency, latencyA, latencyR } = comps
let needSessionInfo = Computed(@() ping.value >= 0)

let fpsText = Computed(function() {
  let fps = (state.value.fps + 0.5).tointeger()
  if (fps < 10000 && fps > 0)
    return $"FPS: {fps}"
  return ""
})
let latencyText = Computed(@() latency.value < 0 ? ""
  : latencyA.value >= 0 && latencyR.value >= 0
    ? format("%s:%5.1fms (A:%5.1fms R:%5.1fms)", loc("latency", "Latency"),
      latency.value, latencyA.value, latencyR.value)
  : format("%s:%5.1fms", loc("latency", "Latency"), latency.value)
)

let gap = hdpx(10)

let defColor         = 0xFFc0c0c0
let fpsColor         = 0x70707070
let qualityColorEpic = fpsColor
let qualityColorGood = fpsColor
let qualityColorOkay = 0x705A5A10
let qualityColorPoor = 0x70701C1C

let textStyle = {
  halign = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  color = defColor
}.__update(fontVeryVeryTiny)

let function getPingColor(pingV) {
  if (pingV <= 50)
    return qualityColorEpic
  if (pingV <= 100)
    return qualityColorGood
  if (pingV <= 300)
    return qualityColorOkay
  return qualityColorPoor
}

let function getPacketlossColor(plV) {
  if (plV <= 1)
    return qualityColorEpic
  if (plV <= 10)
    return qualityColorGood
  if (plV <= 20)
    return qualityColorOkay
  return qualityColorPoor
}

let isAllowedFpsForPlatform = !isPlatformSony && !isPlatformXboxOne && !is_android
let fpsComp = isAllowedFpsForPlatform
  ? @() textStyle.__merge({
      watch = fpsText
      text = fpsText.value
      color = fpsColor
    })
  : null

let sessionComp = @() {
  watch = needSessionInfo
  flow = FLOW_HORIZONTAL
  gap
  children = needSessionInfo.value
    ? [
        @() textStyle.__merge({
          watch = ping
          text = $"Ping: {ping.value}"
          color = getPingColor(ping.value)
        })
        @() textStyle.__merge({
          watch = pl
          text = $"PL: {pl.value}%"
          color = getPacketlossColor(pl.value)
        })
        @() textStyle.__merge({
          watch = sessionId
          text = sessionId.value
        })
    ]
    : null
}

let latencyComp = @() textStyle.__merge({
  watch = latencyText
  text = latencyText.value
})

let fpsLineComp = {
  flow = FLOW_HORIZONTAL
  vplace = ALIGN_BOTTOM
  gap
  children = [
    fpsComp
    sessionComp
    latencyComp
  ]
}

return fpsLineComp
