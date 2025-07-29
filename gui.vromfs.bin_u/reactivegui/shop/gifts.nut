from "%globalsDarg/darg_library.nut" import *
let logG = log_with_prefix("[GIFTS] ")
let { get_time_msec } = require("dagor.time")
let { resetTimeout, setInterval, clearTimer } = require("dagor.workcycle")
let { register_command } = require("console")
let { get_cur_circuit_name } = require("app")
let { get_network_block } = require("blkGetters")
let { get_user_info } = require("auth_wt")
let { minutesToSeconds, secondsToMilliseconds } = require("%sqstd/time.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { isInDebriefing } = require("%appGlobals/clientState/clientState.nut")
let { isInQueue } = require("%appGlobals/queueState.nut")
let { isInMenuNoModals } = require("%rGui/mainMenu/mainMenuState.nut")
let { openMsgBox, msgBoxText } = require("%rGui/components/msgBox.nut")
let { isTutorialActive } = require("%rGui/tutorial/tutorialWnd/tutorialWndState.nut")
let { requestData } = require("%rGui/shop/httpRequest.nut")


let INTERVAL_BETWEEN_REQUESTS_SEC = minutesToSeconds(30)
let INTERVAL_BETWEEN_REQUESTS_MSEC = secondsToMilliseconds(INTERVAL_BETWEEN_REQUESTS_SEC)

const NO_ANSWER_TIMEOUT_SEC = 60

let giftSize = hdpx(150)

enum GIFT_ACTION {
  INFO = "info"
  ACTIVATE = "activate"
  DELETE = "delete"
}

let requestMadeTime = hardPersistWatched("gift.requestMadeTime", 0)
let isGiftInfoRequested = hardPersistWatched("gift.isGiftInfoRequested", false)
let actualGifts = hardPersistWatched("gift.actualGifts", [])

let resetRequestedFlag = @() isGiftInfoRequested.set(false)

let createGiftRequestParams = @(action, giftId = null)
  $"token={get_user_info().token}&act={action}&game=wtm&lang={loc("current_lang")}{giftId == null ? "" : $"&id={giftId}"}"

function makeGiftRequest(onSuccess, onFailure, action = GIFT_ACTION.INFO, giftId = null) {
  let giftsURL = get_network_block()?[get_cur_circuit_name()].giftsURL
  if (giftsURL == null) {
    log("Empty gifts URL: ", get_network_block()?[get_cur_circuit_name()])
    logerr($"Empty gifts url for circuit /*{get_cur_circuit_name()}*/")
    onFailure({ ["error"] = "Empty gifts url" })
    return
  }
  requestData(giftsURL, createGiftRequestParams(action, giftId), onSuccess, onFailure)
}

let getGiftsInfo = @()
  makeGiftRequest(
    function(data) {
      resetRequestedFlag()
      actualGifts.set(data?.gifts ?? [])
      logG("Request for gifts info completed successfully")
    },
    function(errData) {
      resetRequestedFlag()
      actualGifts.set([])
      logG($"Error while getting gifts info - {errData?.error}")
    }
  )

function requestGiftsInfo(force = false) {
  if (!isLoggedIn.get())
    return
  let currTimeMsec = get_time_msec()

  if (!force && (isGiftInfoRequested.get() ||
      (requestMadeTime.get() > 0 && (currTimeMsec - requestMadeTime.get() < INTERVAL_BETWEEN_REQUESTS_MSEC))))
    return
  isGiftInfoRequested.set(true)
  getGiftsInfo()
  requestMadeTime.set(currTimeMsec)
  resetTimeout(NO_ANSWER_TIMEOUT_SEC, resetRequestedFlag)
}

function sendGiftsAnswer(giftId, action) {
  actualGifts.set([])
  makeGiftRequest(
    function(_) {
      requestGiftsInfo(true)
      logG($"Sending gift[{giftId}] answer[{action}] completed successfully")
    },
    function(errData) {
      logG($"Error while sending gift[{giftId}] answer[{action}] - {errData?.error}")
      openMsgBox({
        uid = $"gifts_error_{giftId}"
        title = loc("msgbox/appearError")
        text = loc("msg/questionTryAgain")
        buttons = [
          { id = "later", isCancel = true }
          { id = "repeat", styleId = "PRIMARY", isDefault = true, cb = @() requestGiftsInfo(true) }
        ]
      })
    },
    action,
    giftId
  )
}

requestGiftsInfo()
isLoggedIn.subscribe(@(v) v ? requestGiftsInfo() : null)
requestMadeTime.subscribe(function(_) {
  clearTimer(requestGiftsInfo)
  setInterval(INTERVAL_BETWEEN_REQUESTS_SEC, requestGiftsInfo)
})

let needShow = keepref(Computed(@() actualGifts.get().len() > 0
  && isInMenuNoModals.get()
  && !isInDebriefing.get()
  && isLoggedIn.get()
  && !isTutorialActive.get()
  && !isInQueue.get()
))

let showGiftWnd = @() !needShow.get() ? null
  : openMsgBox({
    uid = $"gifts_{actualGifts.get()[0].gift_id}"
    title = loc("shop/giftTitle")
    text = {
      rendObj = ROBJ_BOX
      size = flex()
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      margin = const [hdpx(32), 0, 0, 0]
      children = [
        {
          size = [giftSize, giftSize]
          rendObj = ROBJ_IMAGE
          image = Picture($"ui/gameuiskin#icon_gift.avif:{giftSize}:{giftSize}:P")
          keepAspect = true
        },
        msgBoxText(loc("shop/giftDesc", {
          donator = actualGifts.get()[0].donator_name,
          gift = actualGifts.get()[0].item_name,
          timeAgo = secondsToHoursLoc(serverTime.get() - actualGifts.get()[0].item_payment_time)
        }))
      ]
    }
    buttons = [
      { id = "reject", isCancel = true, cb = @() sendGiftsAnswer(actualGifts.get()[0].gift_id, GIFT_ACTION.DELETE) }
      { id = "activate", styleId = "PRIMARY", isDefault = true, cb = @() sendGiftsAnswer(actualGifts.get()[0].gift_id, GIFT_ACTION.ACTIVATE) }
    ]
  })

showGiftWnd()
needShow.subscribe(@(v) !v ? null : showGiftWnd())


register_command(@() getGiftsInfo(), "gift.get")
register_command(@() actualGifts.set([
    {
      item_payment_time = "1748607060"
      item_project = "1180"
      item_name = "War Thunder Mobile - 270 (+10% Bonus) Golden Eagles"
      gift_id = "194962"
      item_id = "11187"
      item_link = "https://store.gaijin.net/story.php?id=11187"
      link_guid = "2B9B1A3B-2C94-4B8A-A6A6-5E6BE2B4B330"
      donator_name = "denis0k"
      link_icon = "https://store.gaijin.net/img/items/2B9B1A3B-2C94-4B8A-A6A6-5E6BE2B4B330.jpg"
    }
    {
      item_payment_time = "1748607120"
      item_project = "1180"
      item_name = "War Thunder Mobile - 2450 (+10% Bonus) Golden Eagles"
      gift_id = "194963"
      item_id = "11190"
      item_link = "https://store.gaijin.net/story.php?id=11190"
      link_guid = "E4CEF0E3-D432-410A-BFB8-56E1FD8A1596"
      donator_name = "denis0k"
      link_icon = "https://store.gaijin.net/img/items/E4CEF0E3-D432-410A-BFB8-56E1FD8A1596.jpg"
    }
  ]), "gift.setMockData")
