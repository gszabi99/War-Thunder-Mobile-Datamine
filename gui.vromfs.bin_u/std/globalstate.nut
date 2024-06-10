from "modules" import on_module_unload
from "nestdb" import ndbRead, ndbWrite, ndbDelete, ndbExists
from "eventbus" import eventbus_send_foreign, eventbus_subscribe
from "dagor.debug" import logerr
from "json" import parse_json, object_to_json_string
from "dagor.memtrace" import get_quirrel_object_size, set_huge_alloc_threshold

//let {logerr} = require("%sqstd/log.nut")()

//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!So that there is no record in nestdb on shutdown!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!eventbus event app.shutdown is required!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

let { Watched } = require("frp")
const EVT_NEW_DATA = "GLOBAL_PERMANENT_STATE.newDataAvailable"
let registered = {}


function readNewData(name){
  if (name in registered) {
    let {key, watched} = registered[name]
    watched(ndbRead(key))
  }
//  else
//    println($"requested data for unknown subscriber '{name}'")
// it spamming too much, but without info about VM logs are useless
}

function globalWatched(name, ctor=null) {
  assert(name not in registered, $"Global persistent state duplicate registration: {name}")
  let key = ["GLOBAL_PERSIST_STATE", name]
  local val
  if (ndbExists(key)) {
    val = ndbRead(key)
  }
  else {
    val = ctor?()
    ndbWrite(key, val)
  }
  let res = Watched(val)
  registered[name] <- {key, watched=res}
  function update(value) {
    ndbWrite(key, value)
    res(value)
    eventbus_send_foreign(EVT_NEW_DATA, name)
  }
  res.whiteListMutatorClosure(readNewData)
  res.whiteListMutatorClosure(update)
  return {
    [name] = res,
    [$"{name}Update"] = update
  }
}

eventbus_subscribe(EVT_NEW_DATA, readNewData)


local uniqueKey = null
function setUniqueNestKey(key) {
  assert(!ndbExists(key), $"key {key} is not unique")
  assert(type(key)=="string", $"setUniqueNestKey failed: {key} is not string")
  uniqueKey = key
  ndbWrite(key, true)
}

local isExiting = false
let mkPersistOnHardReloadKey = @(key) uniqueKey==null
  ? $"PERSIST_ON_RELOAD_DATA__{key}"
  : $"PERSIST_ON_RELOAD_DATA__{uniqueKey}__{key}"

eventbus_subscribe("app.shutdown", @(_) isExiting = true)

let persistOnHardReloadData = persist("PERSIST_ON_RELOAD_DATA", @() {})
let usedKeysForPersist = {}
let _big_datas = persist("_big_datas", @() {})

let size_threshold_to_store_as_big_data = 100 << 10
on_module_unload(function(is_closing) {
  if (isExiting) {
    print("App exiting, not writing PersistentOnReload data")
  }
  else if (is_closing) {
    print("Scripts unloading for hard reload, writing PersistentOnReload data")
    foreach (key, val in persistOnHardReloadData) {
      try {
        local is_big_data = false
        local info = ""
        if (key in _big_datas) {
          info = "manually set to store as big data"
          is_big_data = true
       }
       else if (get_quirrel_object_size(val) > size_threshold_to_store_as_big_data) {
          is_big_data = true
          info = $"store as big data as size is bigger than {size_threshold_to_store_as_big_data}"
       }
        if (is_big_data) {
          println($"store compressed version in hard reload storage for: {key}, {info}")
        }
        ndbWrite(mkPersistOnHardReloadKey(key), {data = is_big_data ? object_to_json_string(val) : val, is_big_data = !!is_big_data })
      }
      catch(e){
        println($"ERROR: on hard reload storage {key} = {type(val)}")
        println(e)
        logerr($"ERROR: on hard reload storage save: {key}")
      }
    }
  }
  else {
    println("Scripts unloading for hot reload")
  }
  if (uniqueKey != null) {
    if (ndbExists(uniqueKey))
      ndbDelete(uniqueKey)
    uniqueKey = null
  }
})

function hardPersistWatched(key, def=null, store_as_big_data = null) {
  assert(key not in usedKeysForPersist, @() $"super persistent {key} already registered")
  if (store_as_big_data)
    _big_datas[key] <- store_as_big_data
  let ndbKey = mkPersistOnHardReloadKey(key)
  usedKeysForPersist[key] <- null
  local val
  let isInNdb = ndbExists(ndbKey)
  if (key in persistOnHardReloadData) {
    val = persistOnHardReloadData[key]
    if (isInNdb)
      ndbDelete(ndbKey)
  }
  else if (isInNdb) { //on hard reload
    let stored = ndbRead(ndbKey)
    let prevSize = set_huge_alloc_threshold(66560 << 10)
    try {
      let {is_big_data=null, data=null} = stored
      if (is_big_data) {
        val = parse_json(data)
        //shrink_object(val)
      }
      else
        val = data
    }
    catch(e) {
      println(e)
      logerr($"ERROR: on hard reload storage load: {key}")
    }
    set_huge_alloc_threshold(prevSize)
    ndbDelete(ndbKey)
  }
  else {
    val = def
  }
  persistOnHardReloadData[key] <- val
  let res = Watched(val)
  res.subscribe(@(v) persistOnHardReloadData[key] <- v)
  return res
}

//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!So that there is no record in nestdb on shutdown!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!eventbus event app.shutdown is required!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
return {
  globalWatched
  hardPersistWatched
  setUniqueNestKey
}