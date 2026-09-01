from "%globalsDarg/darg_library.nut" import *
from "math" import abs
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/math.nut" import round_by_value
from "%sqstd/time.nut" import TIME_DAY_IN_SECONDS, TIME_HOUR_IN_SECONDS, TIME_MINUTE_IN_SECONDS
from "%appGlobals/config/subsPresentation.nut" import mkSubsIcon
from "%appGlobals/pServer/campaign.nut" import isProfileReceived
from "%appGlobals/timeToText.nut" import secondsToHoursLoc
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%rGui/components/currencyComp.nut" import CS_GAMERCARD
from "%rGui/mainMenu/balanceAnimations.nut" import mkBalanceDiffAnims, mkBalanceHiglightAnims
from "%rGui/shop/shopCommon.nut" import SC_PREMIUM
from "%rGui/shop/shopState.nut" import openShopWnd
from "%rGui/state/profilePremium.nut" import havePremium, premiumEndsAt, hasPremiumSubs, hasVip, havePremiumDeprecated
from "%rGui/style/gradients.nut" import gradCircularSmallHorCorners, gradCircCornerOffset
from "%rGui/style/stdColors.nut" import premiumTextColor, goodTextColor2, badTextColor2, hoverColor


const premIconH = hdpxi(50)
let highlightTrigger = {}

let visibleEndsAt = hardPersistWatched("premium.visibleEndsAt", premiumEndsAt.get() ?? -1)
let changeOrders = hardPersistWatched("premium.changeOrders", [])
let nextChange = Computed(@() changeOrders.get()?[0])

isProfileReceived.subscribe(function(_) {
  visibleEndsAt.set(premiumEndsAt.get())
  changeOrders.set([])
})
premiumEndsAt.subscribe(function(endsAt) {
  if (endsAt == visibleEndsAt.get() && changeOrders.get().len() == 0)
    return
  let prev = max(changeOrders.get().len() == 0 ? visibleEndsAt.get() : changeOrders.get().top().cur, serverTime.get())
  local diff = endsAt - prev
  if (abs(diff % TIME_HOUR_IN_SECONDS) < TIME_MINUTE_IN_SECONDS)
    diff = round_by_value(diff, TIME_MINUTE_IN_SECONDS).tointeger()
  changeOrders.mutate(@(v) v.append({ cur = endsAt, diff }))
})

let premImageMain = @() {
  watch = [havePremium, hasPremiumSubs, hasVip, havePremiumDeprecated]
  pos = const [0, -hdpx(5)]
  children = [
    mkSubsIcon(
      !havePremium.get() ? "prem_inactive"
        : !hasPremiumSubs.get() ? "prem_deprecated"
        : hasVip.get() ? "vip"
        : "prem",
      premIconH,
      {pos = [0, havePremiumDeprecated.get() ? hdpx(10) : hdpx(0) ]}
    )
    hasPremiumSubs.get() ? null
      : {
          vplace = ALIGN_CENTER
          hplace = ALIGN_CENTER
          pos = const [pw(25), ph(25)]
          rendObj = ROBJ_TEXT
          color = 0xFFFFFFFF
          text = "+"
        }.__update(fontBigShaded)
  ]
}


function premiumTime(style = CS_GAMERCARD) {
  local timeLeft = max(0, visibleEndsAt.get() - serverTime.get())
  if (timeLeft >= 3 * TIME_DAY_IN_SECONDS)  
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
  if (change != changeOrders.get()?[0])
    return
  visibleEndsAt.set(change.cur)
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
      mkSubsIcon("prem_deprecated", premIconH)
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
  size = const [pw(150), FLEX]
  hplace = ALIGN_CENTER
  color = hoverColor
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
      size = FLEX
      padding = const [hdpx(3), 0]
      children =  stateFlags.get() & S_HOVER ? hoverBg : null
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
        onElemState = @(sf) stateFlags.set(sf)
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
        size = 0 
        vplace = ALIGN_BOTTOM
        hplace = ALIGN_CENTER
        children = nextChange.get() == null ? null
          : mkChangeView(nextChange.get())
      }
    ]
  }
}

return premIconWithTimeOnChange