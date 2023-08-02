from "%globalsDarg/darg_library.nut" import *
let { subscribe } = require("eventbus")
let { isShowDebugInterface, is_app_loaded } = require("app")
let { format } = require("string")
let { toUpper } = require("%sqstd/string.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let hasAddons = require("%appGlobals/updater/hasAddons.nut")

let state = Watched({
  gpu = ""
  preset = ""
  sessionId = ""
  latency = -1
  latencyA = -1
  latencyR = -1
})

let initSubscription = @() isShowDebugInterface() ? null
  : subscribe("updateStatusString", @(s) state(state.value.__merge(s)))
if (is_app_loaded())
  initSubscription()
subscribe("onAcesInitComplete", @(_) initSubscription())

let comps = {}
foreach (key in [ "gpu", "preset", "sessionId", "latency", "latencyA", "latencyR" ]) {
  let k = key
  comps[k] <- Computed(@() state.value[k])
}
let { gpu, preset, sessionId, latency, latencyA, latencyR } = comps

let graphicsText = Computed(@() !(hasAddons.value?.pkg_secondary_hq ?? true)  ? "Low Quality Textures"
  : preset.value != "" ? $"Graphics: {toUpper(preset.value, 1)}"
  : "")

let latencyText = Computed(@() latency.value < 0 ? ""
  : latencyA.value >= 0 && latencyR.value >= 0
    ? format("%s:%5.1fms (A:%5.1fms R:%5.1fms)", loc("latency", "Latency"),
      latency.value, latencyA.value, latencyR.value)
  : format("%s:%5.1fms", loc("latency", "Latency"), latency.value)
)

let gap = hdpx(10)

let defColor = 0xFFc0c0c0
let fadedColor = 0x70707070

let textStyle = {
  halign = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  color = defColor
}.__update(fontVeryVeryTiny)

let graphicsComp = @() textStyle.__merge({
  watch = graphicsText
  text = graphicsText.value
}, fontTiny)

let gpuComp = @() textStyle.__merge({
  watch = gpu
  text = (gpu.value.len() > 0) ? $"GPU: {gpu.value}" : ""
  color = fadedColor
}, fontVeryTiny)

let sessionComp = @() textStyle.__merge({
  watch = sessionId
  text = sessionId.value
})

let latencyComp = @() textStyle.__merge({
  watch = latencyText
  text = latencyText.value
})

let fpsLineCompChildren = [
  graphicsComp
  gpuComp
  sessionComp
  latencyComp
]

let fpsLineComp = @() {
  watch = isInBattle
  flow = FLOW_HORIZONTAL
  vplace = ALIGN_BOTTOM
  valign = ALIGN_BOTTOM
  pos = [saBorders[0], 0]
  gap
  children = isInBattle.value ? fpsLineCompChildren : null
}

return fpsLineComp
