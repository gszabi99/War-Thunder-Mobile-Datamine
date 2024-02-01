from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { borderColor } = require("%rGui/hud/hudTouchButtonStyle.nut")

function mkStickWidgetComps(fullSize) {
  let bgRadius = round(0.375 * fullSize)
  let imgBgSize = 2 * bgRadius
  let imgRotationSize = (0.1 * imgBgSize).tointeger()
  let imgArrowW = (0.1 * imgBgSize).tointeger()
  let imgArrowH = (23.0 / 35 * imgArrowW).tointeger()
  let imgArrowGap = 0.027 * bgRadius
  let imgArrowSmallW = (0.08 * imgBgSize).tointeger()
  let imgArrowSmallH = (23.0 / 35 * imgArrowW).tointeger()
  let imgArrowSmallPosX = 0.35 * imgBgSize + 0.5 * imgArrowSmallW
  let imgArrowSmallPosY = 0.35 * imgBgSize + 0.5 * imgArrowSmallH
  let stickSize = round(0.73 * bgRadius)

  let imgRotaion = {
    size = [imgRotationSize, imgRotationSize]
    pos = [-0.5 * imgRotationSize, 0]
    vplace = ALIGN_CENTER
    image = Picture($"ui/gameuiskin#hud_tank_stick_rotation.svg:{imgRotationSize}:{imgRotationSize}:P")
    rendObj = ROBJ_IMAGE
  }

  let imgArrow = {
    size = [imgArrowW, imgArrowH]
    pos = [0, - imgArrowH - imgArrowGap]
    hplace = ALIGN_CENTER
    image = Picture($"ui/gameuiskin#hud_tank_stick_arrow.svg:{imgArrowW}:{imgArrowH}:P")
    rendObj = ROBJ_IMAGE
  }

  let imgArrowSmall = {
    size = [imgArrowSmallW, imgArrowSmallH]
    pos = [ -imgArrowSmallPosX, -imgArrowSmallPosY ]
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    image = Picture($"ui/gameuiskin#hud_tank_stick_arrow.svg:{imgArrowSmallW}:{imgArrowSmallH}:P")
    rendObj = ROBJ_IMAGE
    transform = { rotate = -45 }
  }

  let imgBg = {
    size = [imgBgSize, imgBgSize]
    image = Picture($"ui/gameuiskin#hud_tank_stick_bg.svg:{imgBgSize}:{imgBgSize}:P")
    rendObj = ROBJ_IMAGE
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    color = borderColor
  }

  let fullImgBg = imgBg.__merge({ children = [
    imgRotaion.__merge({
      flipX = true
    })
    imgRotaion.__merge({
      pos = [0.5 * imgRotationSize, 0]
      hplace = ALIGN_RIGHT
    })
    imgArrow
    imgArrow.__merge({
      pos = [0, imgArrowH + imgArrowGap]
      vplace = ALIGN_BOTTOM
      transform = { rotate = 180 }
    })
    imgArrowSmall
    imgArrowSmall.__merge({
      pos = [ imgArrowSmallPosX, -imgArrowSmallPosY ]
      transform = { rotate = 45 }
    })
    imgArrowSmall.__merge({
      pos = [ imgArrowSmallPosX, imgArrowSmallPosY ]
      transform = { rotate = 135 }
    })
    imgArrowSmall.__merge({
      pos = [ -imgArrowSmallPosX, imgArrowSmallPosY ]
      transform = { rotate = 225 }
    })
  ]})


  let stickBgComp = {
    size = [fullSize, fullSize]
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    children = fullImgBg
  }

  let stickHeadComp = {
    size = [stickSize, stickSize]
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#joy_head.svg:{stickSize}:{stickSize}:P")
  }

  let stickWidgetComp = {
    children = [
      stickBgComp
      stickHeadComp
    ]
  }

  return {
    stickWidgetComp
    stickBgComp
    stickHeadComp
  }
}

return mkStickWidgetComps
