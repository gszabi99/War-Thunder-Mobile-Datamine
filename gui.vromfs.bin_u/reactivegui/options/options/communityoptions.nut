from "%globalsDarg/darg_library.nut" import *
from "auth_wt" import getCountryCode
from "eventbus" import eventbus_send
from "%sqstd/datablock.nut" import copyParamsToTable
from "%sqstd/platform.nut" import is_nswitch
from "%sqstd/underscore.nut" import arrayByRows
from "%appGlobals/curCircuitOverride.nut" import getCurCircuitOverride, isExternalOperator
from "%rGui/feedback/supportWnd.nut" import openSupportTicketWndOrUrl


const iconSize = hdpxi(120)
let itemSize = [hdpx(200), hdpx(200)]

let userCountryRU = getCountryCode() == "RU"
let canShowSocialNetworks = !is_nswitch
const maxItemsInRow = 3
const socialsGap = hdpx(35)

let operatorNetowrks = getCurCircuitOverride("social_networks")

let socNetList = operatorNetowrks ? (operatorNetowrks % "p").map(@(blk) copyParamsToTable(blk)) : [
  userCountryRU ? null
    : {
      text = "community/facebook"
      image = "ui/gameuiskin#icon_social_facebook.svg"
      url = "https://www.facebook.com/WTMobileOfficial"
    }
  {
    text = "community/telegram"
    image = "ui/gameuiskin#icon_social_telegram.svg"
    url = "https://t.me/warthundermobile"
  }
  userCountryRU ? null
    : {
      text = "community/discord"
      image = "ui/gameuiskin#icon_social_discord.svg"
      url = "https://discord.gg/VP2DuSbUZH"
    }
  !isExternalOperator() ? null
    : {
      text = "community/vk"
      image = "ui/gameuiskin#icon_social_vk.svg"
      url = "https://vk.com/wtmobile"
    }
  userCountryRU ? null
    : {
      text = "community/instagram"
      image = "ui/gameuiskin#icon_social_instagram.svg"
      url =  "https://instagram.com/wtmobile_official"
    }
  userCountryRU ? null
    : {
      text = "community/x"
      image = "ui/gameuiskin#x_logo.svg"
      url =  "https://x.com/WT_Mobile_"
    }
].filter(@(s) s != null)

let feedBackList = [
  {
    text = loc("mainmenu/support")
    image = "ui/gameuiskin#icon_social_support.svg"
    onClick = openSupportTicketWndOrUrl
  }
]

let header = {
  rendObj = ROBJ_TEXT
  text = loc("community/header")
}.__update(fontSmall)

function mkNetworkItem(item){
  let { text = "", image = null, url = ""} = item
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size = itemSize
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onClick = @() eventbus_send("openUrl", { baseUrl = url })
    onElemState = @(v) stateFlags.set(v)
    transform = { scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.9, 0.9] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
    sound = { click  = "click" }
    flow = FLOW_VERTICAL
    children = [
      {
        size = const [iconSize, iconSize]
        rendObj = ROBJ_IMAGE
        image = Picture($"{image}:{iconSize}:{iconSize}:P")
      }
      {
        halign = ALIGN_CENTER
        minWidth = hdpx(200)
        rendObj = ROBJ_TEXT
        text = loc(text)
      }.__update(fontTinyAccented)
    ]
  }
}

function mkFeedBackButtons(item){
  let { text = "", image = null, onClick = @() null } = item
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onClick
    onElemState = @(v) stateFlags.set(v)
    transform = { scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
    sound = { click  = "click" }
    flow = FLOW_HORIZONTAL
    gap = hdpx(25)
    children = [
        {
          size = const [iconSize, iconSize]
          rendObj = ROBJ_IMAGE
          image = Picture($"{image}:{iconSize}:{iconSize}:P")
        }
        {
          size = const [hdpx(300), SIZE_TO_CONTENT]
          behavior = Behaviors.TextArea
          rendObj = ROBJ_TEXTAREA
          text
        }.__update(fontSmall)
    ]
  }
}

let socNetworks = {
  flow = FLOW_VERTICAL
  gap = socialsGap
  children = arrayByRows(socNetList.map(@(item) mkNetworkItem(item)), maxItemsInRow)
    .map(@(children) {
      flow = FLOW_HORIZONTAL
      hplace = ALIGN_CENTER
      gap = socialsGap
      children
    })
}

let feedBack = {
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(50)
  children = feedBackList.map(@(item) mkFeedBackButtons(item))
}


return @() {
  size = FLEX
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    canShowSocialNetworks ? header : null
    canShowSocialNetworks ? socNetworks : null
    { size = FLEX }
    feedBack
  ]
}