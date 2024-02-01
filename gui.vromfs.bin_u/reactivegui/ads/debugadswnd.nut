from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { get_time_msec } = require("dagor.time")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { sin, cos, PI } = require("math")
let { registerScene } = require("%rGui/navState.nut")
let { debugAdsWndParams } = require("adsInternalState.nut")
let { textButtonPrimary } = require("%rGui/components/textButton.nut")


let isOpened = Computed(@() debugAdsWndParams.value != null)
function sendEnvet(evt) {
  let evtId = debugAdsWndParams.value?[$"{evt}Event"]
  if (evtId != null)
    eventbus_send(evtId, debugAdsWndParams.value?[$"{evt}Data"] ?? {})
}
function close() {
  sendEnvet("finish")
  debugAdsWndParams(null)
}

let isRewardReceived = Watched(false)
let REWARDS_TIME = 5.0
let AUTO_FINISH_TIME = 8.0
let totalAnim = 40
let imgSize = hdpxi(50)
let image = Picture($"ui/gameuiskin#currency_eagles.svg:{imgSize}:{imgSize}")
let rotatePeriodMsec = 2500
let movePeriodMsec = 11000
let blockSize = [hdpx(900), hdpx(600)]

function applyRewards() {
  isRewardReceived(true)
  sendEnvet("reward")
}

function animPoint(i) {
  let rotateOffset = rotatePeriodMsec * i / totalAnim
  let radOffset = (i % 2) * 2000 + 50 * i
  return {
    size = [hdpx(50), hdpx(50)]
    behavior = Behaviors.RtPropUpdate
    rendObj = ROBJ_IMAGE
    image
    transform = {}
    function update() {
      let angle = (rotateOffset + get_time_msec()).tofloat() / rotatePeriodMsec * 2 * PI
      let radPart = sin(((get_time_msec() + radOffset) % movePeriodMsec).tofloat() / movePeriodMsec * 2 * PI)
      return {
        transform = {
          rotate = 360.0 * angle
          translate = [sin(angle), cos(angle)].map(@(val, idx) 0.5 * val * blockSize[idx] * radPart)
        }
      }
    }
  }
}

let animBlock = {
  size = blockSize
  vplace = ALIGN_CENTER
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = array(totalAnim).map(@(_, i) animPoint(i))
}

let debugAdsScene = {
  key = isOpened
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0xFF00000000
  halign = ALIGN_CENTER
  function onAttach() {
    isRewardReceived(false)
    resetTimeout(REWARDS_TIME, applyRewards)
    resetTimeout(AUTO_FINISH_TIME, close)
  }
  function onDetach() {
    clearTimer(applyRewards)
    clearTimer(close)
  }
  children = [
    animBlock
    {
      pos = [0, sh(10)]
      rendObj = ROBJ_TEXT
      text = "Debug advert, just watch this :o)"
    }.__update(fontMedium)
    @() {
      watch = isRewardReceived
      pos = [0, sh(15)]
      rendObj = ROBJ_TEXT
      text = isRewardReceived.value ? "Rewards received" : ""
    }
    textButtonPrimary("Debug cancel", close, { ovr = { vplace = ALIGN_BOTTOM, hplace = ALIGN_RIGHT, margin = sh(5) } })
  ]
}

registerScene("debugAdsWnd", debugAdsScene, close, isOpened)
