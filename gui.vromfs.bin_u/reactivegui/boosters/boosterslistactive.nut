from "%globalsDarg/darg_library.nut" import *
let { getBoosterIcon } = require("%appGlobals/config/boostersPresentation.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { isOpenedBoosterWnd } = require("%rGui/boosters/boostersState.nut")
let { gradCircularSmallHorCorners, gradCircCornerOffset } = require("%rGui/style/gradients.nut")
let { hoverColor } = require("%rGui/style/stdColors.nut")

let stateFlags = Watched(0)

let iconSize = hdpxi(87)
let iconShift = hdpx(-45)
let boostersHeight = iconSize * 1.3

let activeBoosters = Computed(function() {
  let res = []
  foreach(key, boost in (servProfile.get()?.boosters ?? {}))
    if (!boost.isDisabled && boost.battlesLeft > 0 && key in campConfigs.get()?.allBoosters)
      res.append(key)
  return res.sort(@(a, b) a <=> b)
})

let hoverBg = {
  size = [pw(150), boostersHeight]
  rendObj = ROBJ_9RECT
  image = gradCircularSmallHorCorners
  color = hoverColor
  screenOffs = hdpx(100)
  texOffs = gradCircCornerOffset
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
}

let plus = {
  pos = [0, hdpx(15)]
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  rendObj = ROBJ_TEXT
  color = 0xFFFFFFFF
  text = "+"
}.__update(fontBig)

let bstIcon = @(b) {
  rendObj = ROBJ_IMAGE
  size = [iconSize, iconSize]
  image = Picture($"{getBoosterIcon(b)}:{iconSize}:{iconSize}:P")
}

let emptyBst = {
  rendObj = ROBJ_IMAGE
  size = [iconSize, iconSize]
  image = Picture("ui/gameuiskin#not_active_booster.avif")
}

let boostersList = @(boosters) {
  flow = FLOW_HORIZONTAL
  gap = iconShift
  children = boosters.map(bstIcon)
}

let function boostersListActive() {
  let content = activeBoosters.get().len() == 0
    ? emptyBst
    : boostersList(activeBoosters.get())
  return{
    watch = [activeBoosters, stateFlags]
    size = [SIZE_TO_CONTENT, iconSize]
    vplace = ALIGN_CENTER
    onClick = @() isOpenedBoosterWnd.set(true)
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
