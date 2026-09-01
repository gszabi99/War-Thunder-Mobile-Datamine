from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout, clearTimer
from "%appGlobals/pServer/bqClient.nut" import sendUiBqEvent
from "%appGlobals/pServer/pServerApi.nut" import set_session_id_for_premium_bonus
from "%appGlobals/permissions.nut" import allow_subscriptions
from "%rGui/debriefing/debriefingState.nut" import isDebriefingAnimFinished
from "%rGui/shop/bqPurchaseInfo.nut" import PURCH_SRC_DEBRIEFING, PURCH_TYPE_PREMIUM
from "%rGui/shop/shopCommon.nut" import SC_PREMIUM
from "%rGui/shop/shopState.nut" import openShopWnd
from "%rGui/state/profilePremium.nut" import havePremium
from "%rGui/style/gradients.nut" import gradTranspDoubleSideX, gradRadial


const btnW = hdpx(400)
const btnH = hdpxi(180)
const premIconW = hdpxi(225)
const premIconH = hdpxi(155)

const glareAnimDuration = 0.4
const glareRepeatDelay = 2
let startGlareAnim = @() anim_start("glareAnim")
const glareWidth = hdpx(40)
const glareHeight = btnH * 1.25

const glowColor = 0xFF8A5627
const bgColor = 0xFF1A1D1E
const textColor = 0xFFFFFFFF

let isActive = @(sf) (sf & S_ACTIVE) != 0

let btnBg = {
  size = FLEX
  rendObj = ROBJ_SOLID
  color = bgColor
}

let btnGlow = {
  size = const [btnW * 1.2, btnW * 1.2]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = gradRadial
  color = glowColor
}

let btnIcon = @() {
  watch = allow_subscriptions
  size = const [premIconW, premIconH]
  rendObj = ROBJ_IMAGE
  image = allow_subscriptions.get()
    ? Picture($"ui/gameuiskin#subs_vip.avif:{premIconW}:{premIconH}:P")
    : Picture($"ui/gameuiskin#premium_active_big.avif:{premIconW}:{premIconH}:K:P")
  keepAspect = KEEP_ASPECT_FIT
}

let btnText = @() {
  watch = allow_subscriptions
  size = FLEX_H
  margin = const [0, hdpx(10)]
  halign = ALIGN_CENTER
  vplace = ALIGN_TOP
  behavior = Behaviors.TextArea
  rendObj = ROBJ_TEXTAREA
  text = loc(allow_subscriptions.get() ? "debriefing/trySubs" : "debriefing/tryPremium")
  color = textColor
}.__update(fontTinyShaded)

let glare = @() !isDebriefingAnimFinished.get() ? { watch = isDebriefingAnimFinished } : {
  watch = isDebriefingAnimFinished
  key = "glare"
  rendObj = ROBJ_IMAGE
  size = const [glareWidth, glareHeight]
  image = gradTranspDoubleSideX
  color = 0x00A0A0A0
  transform = { translate = [-glareWidth * 3, 0], rotate = 25 }
  vplace = ALIGN_CENTER
  onAttach = @() clearTimer(startGlareAnim)
  animations = [{
    prop = AnimProp.translate, duration = glareAnimDuration, delay = 0.5, play = true,
    to = [btnW + glareWidth * 2, 0],
    trigger = "glareAnim",
    onFinish = @() resetTimeout(glareRepeatDelay, startGlareAnim),
  }]
}

function mkTryPremiumButton(mulComps, sessionId = null) {
  let stateFlags = Watched(0)
  return @() havePremium.get() ? { watch = havePremium } : {
    watch = [havePremium, stateFlags]
    size = const [btnW, btnH]

    behavior = Behaviors.Button
    function onClick() {
      if (sessionId)
        set_session_id_for_premium_bonus(sessionId)
      openShopWnd(SC_PREMIUM)
      sendUiBqEvent("open_shop", { id = "open", from = PURCH_SRC_DEBRIEFING, status = PURCH_TYPE_PREMIUM} )
    }
    onElemState = @(v) stateFlags.set(v)
    transform = { scale = isActive(stateFlags.get()) ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = Linear }]
    sound = { click  = "click" }

    rendObj = ROBJ_BOX
    borderWidth = hdpx(3)
    borderColor = 0xFFEEEEEE
    padding = hdpx(3)
    clipChildren = true

    children = [
      btnBg
      btnGlow
      btnText
      {
        hplace = ALIGN_CENTER
        vplace = ALIGN_BOTTOM
        flow = FLOW_HORIZONTAL
        gap = hdpx(20)
        children = [
          btnIcon
          {
            flow = FLOW_VERTICAL
            vplace = ALIGN_CENTER
            children = mulComps
          }
        ]
      }
      glare
    ]
  }
}

return mkTryPremiumButton
