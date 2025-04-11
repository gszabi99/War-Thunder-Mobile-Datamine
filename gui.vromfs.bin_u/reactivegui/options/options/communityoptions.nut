from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { getCurrentLanguage } = require("dagor.localize")
let { getCountryCode } = require("auth_wt")
let { openSupportTicketWndOrUrl } = require("%rGui/feedback/supportWnd.nut")
let { is_nswitch } = require("%sqstd/platform.nut")
let { arrayByRows } = require("%sqstd/underscore.nut")

let iconSize = hdpxi(120)
let itemSize = [hdpx(200), hdpx(200)]

let userCountryRU = getCountryCode() == "RU"
let canShowSocialNetworks = !is_nswitch
let maxItemsInRow = 3
let socialsGap = hdpx(35)

let socNetList = [
  userCountryRU ? null
    : {
      text = loc("community/facebook")
      image = "ui/gameuiskin#icon_social_facebook.svg"
      url = loc("url/community/facebook")
    }
  {
    text = loc("community/telegram")
    image = "ui/gameuiskin#icon_social_telegram.svg"
    url = loc("url/community/telegram")
  }
  userCountryRU ? null
    : {
      text = loc("community/discord")
      image = "ui/gameuiskin#icon_social_discord.svg"
      url = loc("url/community/discord")
    }
  getCurrentLanguage() != "Russian" ? null
    : {
      text = loc("community/vk")
      image = "ui/gameuiskin#icon_social_vk.svg"
      url = loc("url/community/vk")
    }
  userCountryRU ? null
    : {
      text = loc("community/instagram")
      image = "ui/gameuiskin#icon_social_instagram.svg"
      url =  loc("url/community/instagram")
    }
  userCountryRU ? null
    : {
      text = loc("community/x")
      image = "ui/gameuiskin#x_logo.svg"
      url =  loc("url/community/x")
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
    onElemState = @(v) stateFlags(v)
    transform = { scale = (stateFlags.value & S_ACTIVE) != 0 ? [0.9, 0.9] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
    sound = { click  = "click" }
    flow = FLOW_VERTICAL
    children = [
      {
        size = [iconSize, iconSize]
        rendObj = ROBJ_IMAGE
        image = Picture($"{image}:{iconSize}:{iconSize}:P")
      }
      {
        halign = ALIGN_CENTER
        minWidth = hdpx(200)
        rendObj = ROBJ_TEXT
        text
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
    onElemState = @(v) stateFlags(v)
    transform = { scale = (stateFlags.value & S_ACTIVE) != 0 ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
    sound = { click  = "click" }
    flow = FLOW_HORIZONTAL
    gap = hdpx(25)
    children = [
        {
          size = [iconSize, iconSize]
          rendObj = ROBJ_IMAGE
          image = Picture($"{image}:{iconSize}:{iconSize}:P")
        }
        {
          size = [hdpx(300), SIZE_TO_CONTENT]
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
  size = flex()
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = { size = flex() }
  children = [
    canShowSocialNetworks ? header : null
    canShowSocialNetworks ? socNetworks : null
    feedBack
  ]
}