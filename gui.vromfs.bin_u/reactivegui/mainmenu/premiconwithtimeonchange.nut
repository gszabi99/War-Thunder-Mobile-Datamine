from "%globalsDarg/darg_library.nut" import *
let { abs } = require("math")
let { round_by_value } = require("%sqstd/math.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { TIME_DAY_IN_SECONDS, TIME_HOUR_IN_SECONDS, TIME_MINUTE_IN_SECONDS } = require("%sqstd/time.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { havePremium, premiumEndsAt, hasPremiumSubs } = require("%rGui/state/profilePremium.nut")
let { premiumTextColor, goodTextColor2, badTextColor2 } = require("%rGui/style/stdColors.nut")
let { isProfileReceived } = require("%appGlobals/pServer/campaign.nut")
let { mkBalanceDiffAnims, mkBalanceHiglightAnims } = require("balanceAnimations.nut")
let { gradCircularSmallHorCorners, gradCircCornerOffset } = require("%rGui/style/gradients.nut")
let { openShopWnd } = require("%rGui/shop/shopState.nut")
let { SC_PREMIUM } = require("%rGui/shop/shopCommon.nut")
let { CS_GAMERCARD, CS_INCREASED_ICON } = require("%rGui/components/currencyComp.nut")

let premIconW = CS_INCREASED_ICON.iconSize
let premIconH = (CS_INCREASED_ICON.iconSize / 1.3).tointeger()
let highlightTrigger = {}

let visibleEndsAt = hardPersistWatched("premium.visibleEndsAt", premiumEndsAt.value ?? -1)
let changeOrders = hardPersistWatched("premium.changeOrders", [])
let nextChange = Computed(@() changeOrders.value?[0])

isProfileReceived.subscribe(function(_) {
  visibleEndsAt(premiumEndsAt.value)
  changeOrders([])
})
premiumEndsAt.subscribe(function(endsAt) {
  if (endsAt == visibleEndsAt.value && changeOrders.value.len() == 0)
    return
  let prev = max(changeOrders.value.len() == 0 ? visibleEndsAt.value : changeOrders.value.top().cur, serverTime.value)
  local diff = endsAt - prev
  if (abs(diff % TIME_HOUR_IN_SECONDS) < TIME_MINUTE_IN_SECONDS)
    diff = round_by_value(diff, TIME_MINUTE_IN_SECONDS).tointeger()
  changeOrders.mutate(@(v) v.append({ cur = endsAt, diff }))
})


let premImage = {
  key = {}
  size = [premIconW, premIconH]
  rendObj = ROBJ_IMAGE
  keepAspect = true
  image = Picture($"ui/gameuiskin#premium_active.svg:{premIconW}:{premIconH}:P")
}

let premImageMain = @() premImage.__merge({
  watch = [havePremium, hasPremiumSubs]
  image = !havePremium.value ? Picture($"ui/gameuiskin#premium_inactive.svg:{premIconW}:{premIconH}:P")
    : Picture($"ui/gameuiskin#premium_active.svg:{premIconW}:{premIconH}:P")
  children = hasPremiumSubs.get() ? null
    : {
        vplace = ALIGN_CENTER
        hplace = ALIGN_CENTER
        pos = [pw(30), ph(30)]
        rendObj = ROBJ_TEXT
        color = 0xFFFFFFFF
        text = "+"
      }.__update(fontBigShaded)
})

function premiumTime(style = CS_GAMERCARD) {
  local timeLeft = max(0, visibleEndsAt.value - serverTime.value)
  if (timeLeft >= 3 * TIME_DAY_IN_SECONDS)  //we do not show hours in such case
    timeLeft = round_by_value(timeLeft, TIME_HOUR_IN_SECONDS).tointeger()

  if (timeLeft == 0)
    return {
      watch = [visibleEndsAt, serverTime]
    }

  return {
    watch = [visibleEndsAt, serverTime]
    key = visibleEndsAt
    rendObj = ROBJ_TEXT
    text = timeLeft > 0 ? secondsToHoursLoc(timeLeft) : "".concat(0, loc("measureUnits/days"))
    color = premiumTextColor
    transform = {}
    animations = [
      { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.15, easing = OutQuad,
        play = true, trigger = "premiumAnimSkip" }
      { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.3, easing = OutQuad,
        playFadeOut = true, trigger = "premiumAnimSkip" }
      { prop = AnimProp.translate, to = [0, hdpx(50)], duration = 0.3, easing = OutQuad,
        playFadeOut = true, trigger = "premiumAnimSkip" }
    ]
    fontFxColor = style.fontFxColor
    fontFxFactor = style.fontFxFactor
    fontFx = style.fontFx
  }.__update(style.fontStyle)
}

function onChangeAnimFinish(change) {
  if (change != changeOrders.value?[0])
    return
  visibleEndsAt(change.cur)
  changeOrders.mutate(@(v) v.remove(0))
  anim_start(highlightTrigger)
}

function mkChangeView(change) {
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
      }.__update(fontMediumShaded)
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
      padding = [hdpx(3), 0]
      children =  stateFlags.value & S_HOVER ? hoverBg : null
    }
    content
  ]
}

function premIconWithTimeOnChange() {
  let stateFlags = Watched(0)
  return {
    onAttach = @() anim_skip("premiumAnimSkip")
    onDetach = @() anim_skip("premiumAnimSkip")
    children = [
      withHoveredBg(@() {
        valign = ALIGN_CENTER
        behavior = Behaviors.Button
        onClick = @() openShopWnd(SC_PREMIUM)
        sound = { click  = "meta_shop_buttons" }
        onElemState = @(sf) stateFlags(sf)
        flow = FLOW_HORIZONTAL
        gap = hdpx(10)
        children = [
          premImageMain
          premiumTime
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