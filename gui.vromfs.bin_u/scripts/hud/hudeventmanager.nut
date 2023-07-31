from "%scripts/dagui_library.nut" import *
let { subscribeHudEvents } = require("hudMessages")
//checked for explicitness
#no-root-fallback
#explicit-this

let u = require("%sqStdLibs/helpers/u.nut")
let { send_foreign } = require("eventbus")
let { DM_HIT_RESULT_NONE } = require("hitCamera")
let { Callback } = require("%sqStdLibs/helpers/callback.nut")

local subscribers = {}
local eventsStack = [] //for debug top event

::g_hud_event_manager <- {
  subscribers
  eventsStack

  function init() {
    subscribeHudEvents(this, this.onHudEvent)
    this.reset()
  }

  function reset() {
    subscribers = {}
  }

  function subscribe(event_name, callback_fn, context = null) {
    let cb = Callback(callback_fn, context)
    if (u.isArray(event_name))
      foreach (evName in event_name)
        this.pushCallback(evName, cb)
    else
      this.pushCallback(event_name, cb)
  }

  function pushCallback(event_name, callback_obj) {
    if (!(event_name in subscribers))
      subscribers[event_name] <- []

    subscribers[event_name].append(callback_obj)
  }

  function onHudEvent(event_name, event_data = {}) {
    let data = this.handleData(event_data) //todo: better to send direct event from native code to eventbus instead of this conversion
    send_foreign(event_name, data)
    if (!(event_name in subscribers))
      return

    eventsStack.append(event_name)

    let eventSubscribers = subscribers[event_name]
    for (local i = eventSubscribers.len() - 1; i >= 0; i--)
      if (!eventSubscribers[i].isValid())
        eventSubscribers.remove(i)

    for (local i = 0; i < eventSubscribers.len(); i++)
      eventSubscribers[i](data)

    eventsStack.pop()
  }

  function handleData(data) {
    if (u.isDataBlock(data))
      return ::buildTableFromBlk(data)
    return clone data
  }

  function getCurHudEventName() {
    return eventsStack.len() ? eventsStack.top() : null
  }
}

::on_hit_camera_event <- @(mode, result = DM_HIT_RESULT_NONE, info = {}) // called from client
  send_foreign("hitCamera", { mode, result, info })
