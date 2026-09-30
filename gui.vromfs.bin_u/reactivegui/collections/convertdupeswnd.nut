from "%globalsDarg/darg_library.nut" import *
from "dagor.time" import get_time_msec
from "dagor.workcycle" import deferOnce, resetTimeout
from "%sqstd/string.nut" import utf8ToUpper
from "%sqstd/underscore.nut" import prevIfEqual
from "%appGlobals/loginState.nut" import isLoggedIn
from "%appGlobals/pServer/pServerApi.nut" import collectionInProgress, convert_collection_doubles, registerHandler
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%rGui/collections/collectionComps.nut" import mkConvertionInfoBlock, infoGap
from "%rGui/collections/collectionsState.nut" import activeCollectionsCfg
from "%rGui/components/buttonStyles.nut" import defButtonHeight
from "%rGui/components/modalWindows.nut" import addModalWindowWithHeader, removeModalWindow
from "%rGui/components/spinner.nut" import mkSpinnerHideBlock
from "%rGui/components/textButton.nut" import textButtonPrimary
from "%rGui/controlsMenu/gpActBtn.nut" import EMPTY_ACTION
from "%rGui/shop/autoOpenLootboxes.nut" import lootboxes, canOpenWithWindow


const WND_UID = "convert_dupes"
const ERROR_RETRY_SEC = 60
let errorTimeById = mkWatched(persist, "errorTimeById", {})
let openedId = mkWatched(persist, "openedId", null)

let close = @() openedId.set(null)

let canOpenConvertWnd = Computed(@() canOpenWithWindow.get()
  && lootboxes.get().roulette.len() == 0
  && lootboxes.get().silent.len() == 0)

let dupesReady = Computed(function(prev) {
  let res = []
  let { collections = {} } = servProfile.get()
  foreach (id, cfg in activeCollectionsCfg.get()) {
    let { dblRewardProgress, dblRewards } = cfg
    if (dblRewardProgress <= 0 || dblRewards.len() == 0)
      continue
    let total = (collections?[id].curDblProgress ?? 0) / dblRewardProgress
    if (total > 0)
      res.append({ id, total })
  }

  res.sort(@(a, b) b.total <=> a.total || a.id <=> b.id)
  return prevIfEqual(prev, res.map(@(v) v.id))
})

let readyToOpenCollectionId = keepref(Computed(@() !canOpenConvertWnd.get() || openedId.get() != null ? null
  : dupesReady.get().findvalue(@(cId) cId not in errorTimeById.get())))
let shouldCloseWnd = keepref(Computed(@() openedId.get() != null
  && (!dupesReady.get().contains(openedId.get()) || openedId.get() in errorTimeById.get())))

let convertionInfoBlock = @() mkConvertionInfoBlock(openedId.get(),
  activeCollectionsCfg.get()?[openedId.get()],
  servProfile.get()?.collections[openedId.get()].curDblProgress ?? 0,
  { watch = [openedId, activeCollectionsCfg, servProfile] })

function convertOpenedCollectionDupes() {
  if (openedId.get() != null)
    convert_collection_doubles(openedId.get(), { id = "onCollectionConvert", cId = openedId.get() })
}

registerHandler("onCollectionConvert", function(result, context) {
  let { cId } = context
  if (result?.error != null)
    errorTimeById.mutate(@(v) v.$rawset(cId, get_time_msec()))
  else if (cId in errorTimeById.get())
    errorTimeById.mutate(@(v) v.$rawdelete(cId))
})

function updateErrorsTimer() {
  let curTime = get_time_msec()
  local nextTime = null
  let timesUpdate = {}
  foreach (cId, time in errorTimeById.get()) {
    let next = time + ERROR_RETRY_SEC * 1000
    if (next <= get_time_msec()) {
      if (dupesReady.get().contains(cId)) {
        convert_collection_doubles(cId, { id = "onCollectionConvert", cId })
        timesUpdate[cId] <- curTime
      }
      else
        timesUpdate[cId] <- null
    }
    else
      nextTime = min(nextTime ?? next, next)
  }

  if (timesUpdate.len() != 0)
    errorTimeById.set(errorTimeById.get().__merge(timesUpdate).filter(@(v) v != null))
  if (nextTime != null)
    resetTimeout(max(1, 0.001 * (nextTime - curTime)), updateErrorsTimer)
}
errorTimeById.subscribe(@(_) updateErrorsTimer())

isLoggedIn.subscribe(@(_) errorTimeById.set({}))

let openImpl = @() addModalWindowWithHeader(WND_UID,
  loc("collection/duplicateConvert/header"),
  {
    minWidth = hdpx(1000)
    padding = infoGap
    flow = FLOW_VERTICAL
    gap = infoGap
    halign = ALIGN_CENTER
    children = [
      convertionInfoBlock
      mkSpinnerHideBlock(Computed(@() collectionInProgress.get() != null),
        textButtonPrimary(utf8ToUpper(loc("shop/vip/get_rewards")), convertOpenedCollectionDupes, { hotkeys = ["^J:X"] }),
        {
          size = [ FLEX, defButtonHeight ]
          halign = ALIGN_CENTER
        })
    ]
  },
  EMPTY_ACTION)

function open() {
  if (readyToOpenCollectionId.get() == null)
    return
  openedId.set(readyToOpenCollectionId.get())
  openImpl()
}

if (shouldCloseWnd.get())
  close()
if (readyToOpenCollectionId.get())
  deferOnce(open)
if (openedId.get() != null)
  openImpl()
shouldCloseWnd.subscribe(@(v) v ? close() : null)
readyToOpenCollectionId.subscribe(@(_) deferOnce(open))
openedId.subscribe(@(v) v == null ? removeModalWindow(WND_UID) : null)
