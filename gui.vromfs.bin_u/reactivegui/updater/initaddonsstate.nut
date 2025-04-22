from "%globalsDarg/darg_library.nut" import *
let logA = log_with_prefix("[ADDONS_INFO] ")
let { eventbus_subscribe } = require("eventbus")
let { DBGLEVEL } = require("dagor.system")
let { get_addons_size_async, get_addons_versions_async, is_addon_exists_in_game_folder_async
} = require("contentUpdater")
let { isEqual } = require("%sqstd/underscore.nut")
let { knownAddons } = require("%appGlobals/updater/addons.nut")
let { addonsExistInGameFolder, isAddonsExistInGameFolderActual, addonsVersions, isAddonsVersionsActual,
  addonsSizes, isAddonsSizesActual
} = require("%appGlobals/updater/addonsState.nut")
let { isGameUpdatedOnLogin } = require("%appGlobals/loginState.nut")


let MB = 1 << 20

function onGetAddonsExistInGameFolder(evt) {
  if (!isEqual(addonsExistInGameFolder.get(), evt)) {
    addonsExistInGameFolder.set(clone evt)
    logA("Get addons in game folder: ", ", ".join(addonsExistInGameFolder.get().filter(@(v) v).keys().sort()))
  }
  else
    logA("Get addons in game folder: unchanged")
  isAddonsExistInGameFolderActual.set(true)
}
eventbus_subscribe("getIsAddonsExistInGameFolder", onGetAddonsExistInGameFolder)
addonsExistInGameFolder.whiteListMutatorClosure(onGetAddonsExistInGameFolder)

function requestAddonsExistInGameFolder() {
  if (knownAddons.len() == 0)
    return
  logA("Request addons in game folder")
  is_addon_exists_in_game_folder_async("getIsAddonsExistInGameFolder", knownAddons.keys())
}
if (!isAddonsExistInGameFolderActual.get())
  requestAddonsExistInGameFolder()
isAddonsExistInGameFolderActual.subscribe(@(v) v ? null : requestAddonsExistInGameFolder())


function onGetAddonsVersions(evt) {
  if (!isEqual(addonsVersions.get(), evt)) {
    addonsVersions.set(clone evt)
    logA("Get addons versions: ",
      ", ".join(addonsVersions.get().keys().sort().map(@(a) $"{a} {addonsVersions.get()[a]}")))
  }
  else
    logA("Get addons versions: unchanged")
  isAddonsVersionsActual.set(true)
}
eventbus_subscribe("getAllAddonsVersionsEvent", onGetAddonsVersions)
addonsVersions.whiteListMutatorClosure(onGetAddonsVersions)

function requestAddonsVersions() {
  if (knownAddons.len() == 0)
    return
  logA("Request addons versions")
  get_addons_versions_async("getAllAddonsVersionsEvent", knownAddons.keys())
}
if (!isAddonsVersionsActual.get())
  requestAddonsVersions()
isAddonsVersionsActual.subscribe(@(v) v ? null : requestAddonsVersions())


function onGetAddonsSizes(evt) {
  if (!isEqual(addonsSizes.get(), evt)) {
    addonsSizes.set(clone evt)

    local messageArr = [ "Get addons sizes:" ]
    if (DBGLEVEL > 0) {
      let addons = addonsSizes.get().keys().sort()
      let addonsCount = addons.len()
      for (local idx = 0; idx < addonsCount; idx += 5) {
        let chunk = addons.slice(idx, idx + 5)
        messageArr.append(", ".join(chunk.map(function(a) {
          let size = addonsSizes.get()[a]
          let mb = (size + (MB / 2)) / MB
          return $"{a}: {mb}MB ({size})"
        })))
      }
    }
    else
      messageArr.append($"Received {addonsSizes.get().len()} addons")
    logA("\n".join(messageArr))
  }
  else
    logA("Get addons sizes: unchanged")
  isAddonsSizesActual.set(true)
}
eventbus_subscribe("getAllAddonsSizesEvent", onGetAddonsSizes)
addonsSizes.whiteListMutatorClosure(onGetAddonsSizes)

function requestAddonsSizes() { 
  if (knownAddons.len() == 0)
    return
  logA("Request addons sizes")
  get_addons_size_async("getAllAddonsSizesEvent", knownAddons.keys())
}
if (!isAddonsSizesActual.get())
  requestAddonsSizes()
isAddonsSizesActual.subscribe(@(v) v ? null : requestAddonsSizes())

isGameUpdatedOnLogin.subscribe(function(v) {
  if (!v)
    return
  isAddonsExistInGameFolderActual.set(false)
  isAddonsVersionsActual.set(false)
})
