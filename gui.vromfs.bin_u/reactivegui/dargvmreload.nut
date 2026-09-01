from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import deferOnce
from "eventbus" import eventbus_subscribe
from "reactiveGuiCommand" import reloadDargUiScript


let reloadDarg = @() reloadDargUiScript(false)



eventbus_subscribe("reloadDargVM", function(v) {
  log("Request reloadDargVM: ", v?.msg)
  deferOnce(reloadDarg)
})

eventbus_subscribe("on_renderer_settings_applied", function(evt) {
  if (evt.need_reload)
    deferOnce(reloadDarg)
})
