from "%scripts/dagui_library.nut" import *
let { subscribeHudEvents } = require("hudMessages")
let { convertBlk, isDataBlock } = require("%sqstd/datablock.nut")
let { eventbus_send_foreign, eventbus_subscribe } = require("eventbus")
let { DM_HIT_RESULT_NONE } = require("hitCamera")
let { Callback } = require("%sqStdLibs/helpers/callback.nut")

local subscribers = {}
local eventsStack = [] 

let g_hud_event_manager = {
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
    if (type(event_name) == "array")
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
    let data = this.handleData(event_data) 
    eventbus_send_foreign(event_name, data)
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
    if (isDataBlock(data))
      return convertBlk(data)
    return clone data
  }

  function getCurHudEventName() {
    return eventsStack.len() ? eventsStack.top() : null
  }
}

eventbus_subscribe("on_hit_camera_event", @(event)
  eventbus_send_foreign("hitCamera", { mode=event.mode, result = event.result ?? DM_HIT_RESULT_NONE , info = event?.info ?? {}})
)

return {
  g_hud_event_manager
}