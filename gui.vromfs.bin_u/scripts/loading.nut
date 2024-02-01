from "%scripts/dagui_library.nut" import *

let { loading_is_in_progress, loading_is_finished, loading_press_apply } = require("loading")
let { isInLoadingScreen, isMissionLoading } = require("%appGlobals/clientState/clientState.nut")
let { setInterval, clearTimer } = require("dagor.workcycle")
let loadRootScreen = require("%scripts/loadRootScreen.nut")
let { eventbus_subscribe } = require("eventbus")

function checkFinishLoading() {
  if (loading_is_finished())
    loading_press_apply()
  isInLoadingScreen.update(loading_is_in_progress())
}

isInLoadingScreen.subscribe(@(v) v ? null : clearTimer(checkFinishLoading))

eventbus_subscribe("gui_start_loading", function gui_start_loading(payload) {
  let isMission = payload?["showBriefing"] ?? false
  isMissionLoading.update(isMission)
  isInLoadingScreen.update(true)
  clearTimer(checkFinishLoading)
  setInterval(0.05, checkFinishLoading)
  loadRootScreen()
})

eventbus_subscribe("onGuiFinishLoading", @(_) checkFinishLoading())
