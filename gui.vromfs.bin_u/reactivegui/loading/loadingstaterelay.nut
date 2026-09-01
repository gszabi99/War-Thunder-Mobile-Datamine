from "dagor.workcycle" import setInterval, clearTimer
from "eventbus" import eventbus_subscribe
from "loading" import loading_is_in_progress, loading_is_finished, loading_press_apply
from "%appGlobals/clientState/clientState.nut" import isInLoadingScreen, isMissionLoading




function checkFinishLoading() {
  if (loading_is_finished())
    loading_press_apply()
  isInLoadingScreen.set(loading_is_in_progress())
}

isInLoadingScreen.subscribe(@(v) v ? null : clearTimer(checkFinishLoading))

eventbus_subscribe("gui_start_loading", function(payload) {
  isMissionLoading.set(payload?["showBriefing"] ?? false)
  isInLoadingScreen.set(true)
  clearTimer(checkFinishLoading)
  setInterval(0.05, checkFinishLoading)
})

eventbus_subscribe("onGuiFinishLoading", @(_) checkFinishLoading())


if (isInLoadingScreen.get())
  setInterval(0.05, checkFinishLoading)
