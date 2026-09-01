from "%globalsDarg/darg_library.nut" import *
from "hudMessages" import subscribeHudEvents
from "%sqstd/datablock.nut" import convertBlk, isDataBlock
from "%sqstd/underscore.nut" import getSubArray


let subscribers = {}

function handleData(data) {
  if (isDataBlock(data))
    return convertBlk(data)
  return clone data
}

function onHudEvent(event_name, event_data = {}) {
  let data = handleData(event_data) 
  foreach (cb in subscribers?[event_name] ?? [])
    cb(data)
}

function initHudEventMgr() {
  subscribeHudEvents(this, onHudEvent)
}

let subscribeHudEvent = @(name, cb) getSubArray(subscribers, name).append(cb)

return {
  initHudEventMgr
  subscribeHudEvent
}
