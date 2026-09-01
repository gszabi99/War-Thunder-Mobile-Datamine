from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/boostersPresentation.nut" import getBoosterIcon
from "%appGlobals/pServer/bqClient.nut" import sendUiBqEvent
from "%appGlobals/pServer/campaign.nut" import campConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%rGui/boosters/boostersState.nut" import isOpenedBoosterWnd
from "%rGui/style/gradients.nut" import gradCircularSmallHorCorners, gradCircCornerOffset
from "%rGui/style/stdColors.nut" import hoverColor


let stateFlags = Watched(0)

const iconSize = hdpxi(87)
const iconShift = hdpx(-45)
const boostersHeight = iconSize * 1.3

let activeBoosters = Computed(function() {
  let res = []
  foreach(key, boost in (servProfile.get()?.boosters ?? {}))
    if (!boost.isDisabled && boost.battlesLeft > 0 && key in campConfigs.get()?.allBoosters)
      res.append(key)
  return res.sort(@(a, b) a <=> b)
})

let hoverBg = {
  size = const [pw(150), boostersHeight]
  rendObj = ROBJ_9RECT
  image = gradCircularSmallHorCorners
  color = hoverColor
  screenOffs = hdpx(100)
  texOffs = gradCircCornerOffset
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
}

let plus = {
  pos = const [0, hdpx(15)]
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  rendObj = ROBJ_TEXT
  color = 0xFFFFFFFF
  text = "+"
}.__update(fontBig)

let bstIcon = @(b) {
  rendObj = ROBJ_IMAGE
  size = const [iconSize, iconSize]
  image = Picture($"{getBoosterIcon(b)}:{iconSize}:{iconSize}:P")
}

let emptyBst = {
  rendObj = ROBJ_IMAGE
  size = const [iconSize, iconSize]
  image = Picture("ui/gameuiskin#not_active_booster.avif")
}

let boostersList = @(boosters) {
  flow = FLOW_HORIZONTAL
  gap = iconShift
  children = boosters.map(bstIcon)
}

let boostersListActive = @(from) function() {
  let content = activeBoosters.get().len() == 0
    ? emptyBst
    : boostersList(activeBoosters.get())
  return {
    watch = [activeBoosters, stateFlags]
    size = const [SIZE_TO_CONTENT, iconSize]
    vplace = ALIGN_CENTER
    function onClick() {
      isOpenedBoosterWnd.set(true)
      sendUiBqEvent("open_boosters_window", { id = "open", from })
    }
    behavior = Behaviors.Button
    sound = { click  = "click" }
    onElemState = @(v) stateFlags.set(v)

    transform = {
      scale = stateFlags.get() & S_ACTIVE ? [0.95, 0.95] : [1, 1]
    }
    children = [
      stateFlags.get() & S_HOVER ? hoverBg : null
      content
      plus
    ]
  }
}
return {
  boostersListActive
  boostersHeight
}
