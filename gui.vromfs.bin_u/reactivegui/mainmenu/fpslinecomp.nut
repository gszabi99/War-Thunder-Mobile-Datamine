from "%globalsDarg/darg_library.nut" import *
from "app" import isShowDebugInterface, is_dev_version, is_app_loaded, get_base_game_version_str
from "dagor.system" import dgs_get_settings
from "eventbus" import eventbus_subscribe
from "replays" import get_replay_props
from "string" import format
from "%sqstd/string.nut" import capitalize
from "%appGlobals/clientState/clientState.nut" import isInBattle, isInMenu, battleSessionId, isInDebriefing
from "%appGlobals/updater/addonsState.nut" import hasAddons
from "%rGui/hudState.nut" import isPlayingReplay


const DEBUG_INTERFACE_SHIFT_PX = -hdpx(16)

let state = Watched({
  gpu = ""
  preset = ""
  sessionId = ""
  latency = -1
  latencyA = -1
  latencyR = -1
})

let gameVersion = Watched("")
let hasDebugInterfaceInMpSession = Watched(false)

function initSubscription() {
  if (is_dev_version() && !(dgs_get_settings()?.debug.showDebugInterface ?? true))
    return
  eventbus_subscribe("updateStatusString", @(s) state.set(state.get().__merge(s)))
  gameVersion.set(get_base_game_version_str())
  hasDebugInterfaceInMpSession.set(isShowDebugInterface())
}
if (is_app_loaded())
  initSubscription()
eventbus_subscribe("onAcesInitComplete", @(_) initSubscription())

let comps = {}
foreach (key in [ "gpu", "preset", "sessionId", "latency", "latencyA", "latencyR" ]) {
  let k = key
  comps[k] <- Computed(@() state.get()[k])
}
let { gpu, preset, sessionId, latency, latencyA, latencyR } = comps

let graphicsText = Computed(@() !(hasAddons.get()?.pkg_secondary_hq ?? true)  ? "Low Quality Textures"
  : preset.get() != "" ? $"Graphics: {capitalize(preset.get())}"
  : "")

let latencyText = Computed(@() latency.get() < 0 ? ""
  : latencyA.get() >= 0 && latencyR.get() >= 0
    ? format("%s:%5.1fms (A:%5.1fms R:%5.1fms)", loc("latency", "Latency"),
      latency.get(), latencyA.get(), latencyR.get())
  : format("%s:%5.1fms", loc("latency", "Latency"), latency.get())
)

let replaySessionId = Computed(@() isPlayingReplay.get() ? get_replay_props()?.sessionId ?? "" : "")

const gap = hdpx(10)

const defColor = 0xFFc0c0c0
const fadedColor = 0x70707070

let bottomShift = Computed(@() hasDebugInterfaceInMpSession.get() && sessionId.get() != ""
  ? DEBUG_INTERFACE_SHIFT_PX
  : 0)

let textStyle = {
  halign = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  color = defColor
}.__update(fontVeryVeryTinyShaded)

let graphicsComp = @() textStyle.__merge({
  watch = graphicsText
  text = graphicsText.get()
}, fontTinyShaded)

let gpuComp = @() textStyle.__merge({
  watch = gpu
  text = (gpu.get().len() > 0) ? $"GPU: {gpu.get()}" : ""
})

let gpuBigComp = @() textStyle.__merge({
  watch = gpu
  text = (gpu.get().len() > 0) ? $"GPU: {gpu.get()}" : ""
  color = fadedColor
}, fontVeryTinyShaded)

let sessionComp = @() textStyle.__merge({
  watch = [sessionId, replaySessionId]
  text = sessionId.get() != "" ? sessionId.get() : replaySessionId.get()
})

let versionComp = @() textStyle.__merge({
  watch = gameVersion
  text = gameVersion.get()
})

let lastBattleID = @() textStyle.__merge({
  watch = isInDebriefing
  text = isInDebriefing.get() && battleSessionId.get() > 0 ? battleSessionId.get() : null
})

let latencyComp = @() textStyle.__merge({
  watch = latencyText
  text = latencyText.get()
  monoWidth = "0"
})

let presetBattle = [
  graphicsComp
  gpuBigComp
  versionComp
  sessionComp
  latencyComp
]

let presetMenu = [
  gpuComp
  versionComp
  lastBattleID
]

let fpsLineComp = @() {
  watch = [bottomShift, isInBattle, isInMenu]
  flow = FLOW_HORIZONTAL
  vplace = ALIGN_BOTTOM
  valign = ALIGN_BOTTOM
  pos = [saBorders[0], bottomShift.get()]
  gap
  children = isInBattle.get() ? presetBattle
    : isInMenu.get() ? presetMenu
    : null
}

return fpsLineComp
