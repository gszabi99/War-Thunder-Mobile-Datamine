from "%globalsDarg/darg_library.nut" import *
let { abs } = require("math")
let { get_time_msec } = require("dagor.time")
let { resetTimeout } = require("dagor.workcycle")
let { round_by_value } = require("%sqstd/math.nut")
let mkHardWatched = require("%globalScripts/mkHardWatched.nut")
let { TIME_DAY_IN_SECONDS, TIME_HOUR_IN_SECONDS, TIME_MINUTE_IN_SECONDS } = require("%sqstd/time.nut")
let { secondsToHoursLoc } = require("%rGui/globals/timeToText.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { havePremium, premiumEndsAt } = require("%rGui/state/profilePremium.nut")
let { premiumTextColor, goodTextColor2, badTextColor2 } = require("%rGui/style/stdColors.nut")
let { isProfileReceived } = require("%appGlobals/pServer/campaign.nut")
let { mkBalanceDiffAnims, mkBalanceHiglightAnims } = require("balanceAnimations.nut")
let { gradCircularSmallHorCorners, gradCircCornerOffset } = require("%rGui/style/gradients.nut")
let { openShopWnd } = require("%rGui/shop/shopState.nut")
let { SC_PREMIUM } = require("%rGui/shop/shopCommon.nut")

let premIconW = hdpxi(90)
let premIconH = hdpxi(70)
let highlightTrigger = {}
let showTextTimeSec = 10

let visibleEndsAt = mkHardWatched("premium.visibleEndsAt", -1)
let changeOrders = mkHardWatched("premium.changeOrders", [])
let hideTime = mkWatched(persist, "hideTime", 0)
let shouldShowText = Watched(false)
let nextChange = Computed(@() changeOrders.value?[0])

let refreshHideTime = @() hideTime(get_time_msec() + (1000 * showTextTimeSec).tointeger())
isProfileReceived.subscribe(function(_) {
  visibleEndsAt(premiumEndsAt.value)
  changeOrders([])
  hideTime(0)
})
premiumEndsAt.subscribe(function(endsAt) {
  if (endsAt == visibleEndsAt.value && changeOrders.value.len() == 0)
    return
  let prev = max(changeOrders.value.len() == 0 ? visibleEndsAt.value : changeOrders.value.top().cur, serverTime.value)
  local diff = endsAt - prev
  if (abs(diff % TIME_HOUR_IN_SECONDS) < TIME_MINUTE_IN_SECONDS)
    diff = round_by_value(diff, TIME_MINUTE_IN_SECONDS).tointeger()
  changeOrders.mutate(@(v) v.append({ cur = endsAt, diff }))
  refreshHideTime()
})

let function updateLastChangeTimer() {
  let timeToHide = hideTime.value - get_time_msec()
  shouldShowText(timeToHide > 0)
  if (timeToHide > 0)
    resetTimeout(0.001 * timeToHide, updateLastChangeTimer)
}
updateLastChangeTimer()
hideTime.subscribe(@(_) updateLastChangeTimer())

let premImage = {
  key = {}
  size = [premIconW, premIconH]
  rendObj = ROBJ_IMAGE
  keepAspect = true
  image = Picture($"ui/gameuiskin#premium_active.svg:{premIconW}:{premIconH}:P")
}

let premImageMain = @() premImage.__merge({
  watch = havePremium
  image = !havePremium.value ? Picture($"ui/gameuiskin#premium_inactive.svg:{premIconW}:{premIconH}:P")
    : Picture($"ui/gameuiskin#premium_active.svg:{premIconW}:{premIconH}:P")
  children = {
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    pos = [pw(30), ph(30)]
    rendObj = ROBJ_TEXT
    color = 0xFFFFFFFF
    text = "+"
  }.__update(fontBigShaded)
})

let function premiumTime() {
  local timeLeft = max(0, visibleEndsAt.value - serverTime.value)
  if (timeLeft >= 3 * TIME_DAY_IN_SECONDS)  //we do not show hours in such case
    timeLeft = round_by_value(timeLeft, TIME_HOUR_IN_SECONDS).tointeger()
  return {
    watch = [visibleEndsAt, serverTime]
    key = visibleEndsAt
    rendObj = ROBJ_TEXT
    text = timeLeft > 0 ? secondsToHoursLoc(timeLeft) : "".concat(0, loc("measureUnits/days"))
    color = premiumTextColor
    transform = {}
    animations = [
      { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.15, easing = OutQuad, play = true }
      { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.3, easing = OutQuad, playFadeOut = true }
      { prop = AnimProp.translate, to = [0, hdpx(50)], duration = 0.3, easing = OutQuad, playFadeOut = true }
    ]
  }.__update(fontSmall, fontGlowBlack)
}

let function onChangeAnimFinish(change) {
  if (change != changeOrders.value?[0])
    return
  visibleEndsAt(change.cur)
  changeOrders.mutate(@(v) v.remove(0))
  refreshHideTime()
  anim_start(highlightTrigger)
}

let function mkChangeView(change) {
  let { diff } = change
  return {
    key = change
    zOrder = Layers.Upper
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    children = [
      premImage
      {
        rendObj = ROBJ_TEXT
        text = "".concat(diff < 0 ? "-" : "+", secondsToHoursLoc(abs(diff)))
        color = diff < 0 ? badTextColor2 : goodTextColor2
      }.__update(fontMedium, fontGlowBlack)
    ]
    transform = {}
    animations = mkBalanceDiffAnims(@() onChangeAnimFinish(change))
  }
}

let hoverBg = {
  size = [pw(150), flex()]
  hplace = ALIGN_CENTER
  color = 0x8052C4E4
  rendObj = ROBJ_9RECT
  image = gradCircularSmallHorCorners
  screenOffs = hdpx(100)
  texOffs = gradCircCornerOffset
}

let withHoveredBg = @(content, stateFlags) {
  children = [
    @() {
      watch = stateFlags
      key = stateFlags
      size = flex()
      children =  stateFlags.value & S_HOVER ? hoverBg : null
    }
    content
  ]
}

let function premIconWithTimeOnChange() {
  let stateFlags = Watched(0)
  return {
    children = [
      withHoveredBg(@() {
        watch = shouldShowText
        valign = ALIGN_CENTER
        behavior = Behaviors.Button
        onClick = @() openShopWnd(SC_PREMIUM)
        onElemState = @(sf) stateFlags(sf)
        flow = FLOW_HORIZONTAL
        gap = hdpx(10)
        children = [
          premImageMain
          shouldShowText.value ? premiumTime : null
        ]
        transform = {}
        animations = mkBalanceHiglightAnims(highlightTrigger)
      }, stateFlags)
      @() {
        watch = nextChange
        key = nextChange
        size = [0, 0] //to not affect parent size
        vplace = ALIGN_BOTTOM
        hplace = ALIGN_CENTER
        children = nextChange.value == null ? null
          : mkChangeView(nextChange.value)
      }
    ]
  }
}

return premIconWithTimeOnChange