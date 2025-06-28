from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")

let bgColor = 0x50000000
let outlineColor = 0x58585858
let cornerColor = 0xFFFFFFFF
let highlightColor = 0x60606060

let horAnimSizeMul = [0.175, 0.17]
let verCornerSizeMul = [0.61, 0.24]

function mkSize(mul, szRel) {
  let w = szRel[0] * mul
  return [round(w), round(w * szRel[1] / szRel[0])]
}

function mkArrowsWidgetComps(fullSize) {
  let horSizeRel = [12.5, 17.0]
  let verSizeRel = [16.0, 12.8]
  let stopSizeRel = [9.3, 9.3]
  let vGapSizeRel = [2.0, 2.0]
  let resizeMul = fullSize / ((horSizeRel[0] * 2) + verSizeRel[0])
  let horSize = mkSize(resizeMul, horSizeRel)
  let verSize = mkSize(resizeMul, verSizeRel)
  let stopSize = mkSize(resizeMul, stopSizeRel)
  let btnsVGap = mkSize(resizeMul, vGapSizeRel)[0]

  function mkSteeringArrow(flipX) {
    let size = horSize
    let horAnimSize = horAnimSizeMul.map(@(v, i) (v * size[i]).tointeger())
    let cornerOffset = (0.72 * horAnimSize[0]).tointeger()
    return {
      size
      vplace = ALIGN_CENTER
      children = [
        {
          size
          rendObj = ROBJ_IMAGE
          image = Picture($"ui/gameuiskin#hud_movement_arrow_left_bg.svg:{size[0]}:{size[1]}")
          color = bgColor
          flipX
        }
        {
          size
          rendObj = ROBJ_IMAGE
          image = Picture($"ui/gameuiskin#hud_movement_arrow_left_bg.svg:{size[0]}:{size[1]}")
          color = highlightColor
          opacity = 0
          flipX
        }
        {
          size
          rendObj = ROBJ_IMAGE
          image = Picture($"ui/gameuiskin#hud_movement_arrow_left_outline.svg:{size[0]}:{size[1]}")
          color = outlineColor
          flipX
        }
        {
          size = horAnimSize
          rendObj = ROBJ_IMAGE
          image = Picture($"ui/gameuiskin#hud_movement_arrow_left_corner.svg:{horAnimSize[0]}:{horAnimSize[1]}")
          color = cornerColor
          hplace = flipX ? ALIGN_RIGHT : ALIGN_LEFT
          vplace = ALIGN_CENTER
          margin = [0, cornerOffset]
          flipX
        }
      ]
    }
  }

  let arrowLeft = mkSteeringArrow(false)
  let arrowRight = mkSteeringArrow(true)

  function mkGearboxArrow(flipY) {
    let size = verSize
    let verCornerSize = verCornerSizeMul.map(@(v, i) (v * size[i]).tointeger())
    let cornerOffset = (0.3 * verCornerSize[1]).tointeger()
    return {
      flipY
      children = [
        {
          size
          rendObj = ROBJ_IMAGE
          image = Picture($"ui/gameuiskin#hud_movement_arrow_forward_bg.svg:{size[0]}:{size[1]}")
          color = bgColor
          flipY
        }
        {
          size
          rendObj = ROBJ_IMAGE
          image = Picture($"ui/gameuiskin#hud_movement_arrow_forward_bg.svg:{size[0]}:{size[1]}")
          color = highlightColor
          opacity = 0
          flipY
        }
        {
          size
          rendObj = ROBJ_IMAGE
          image = Picture($"ui/gameuiskin#hud_movement_arrow_forward_outline.svg:{size[0]}:{size[1]}")
          color = outlineColor
          flipY
        }
        {
          rendObj = ROBJ_IMAGE
          size = verCornerSize
          image = Picture($"ui/gameuiskin#hud_movement_arrow_forward_corner.svg:{verCornerSize[0]}:{verCornerSize[1]}")
          vplace = flipY ? ALIGN_BOTTOM : ALIGN_TOP
          hplace = ALIGN_CENTER
          margin = [flipY ? 0 : cornerOffset, 0, flipY ? cornerOffset : 0, 0]
          color = cornerColor
          flipY
        }
      ]
    }
  }

  let arrowUp = mkGearboxArrow(false)
  let arrowDown = mkGearboxArrow(true)

  let arrowStop = {
    size = verSize
    vplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [
      {
        size = stopSize
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#hud_movement_stop2_bg.svg:{stopSize[0]}:{stopSize[1]}")
        keepAspect = true
        color = bgColor
      }
      {
        size = stopSize
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#hud_movement_stop2_bg.svg:{stopSize[0]}:{stopSize[1]}")
        keepAspect = true
        color = highlightColor
        opacity = 0
      }
      {
        size = stopSize
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#hud_movement_stop2_outline.svg:{stopSize[0]}:{stopSize[1]}")
        keepAspect = true
        color = outlineColor
      }
    ]
  }

  let arrowsWidgetComp = {
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    children = [
      arrowLeft
      {
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        gap = btnsVGap
        children = [
          arrowUp
          {
            children = [
              arrowStop
              arrowDown
            ]
          }
        ]
      }
      {
        size = FLEX_V
        children = [
          arrowRight
        ]
      }
    ]
  }

  let arrowsWidgetParts = {
    arrowDown
    arrowStop
    arrowLeftH = arrowLeft.children[1]
    arrowRightH = arrowRight.children[1]
    arrowUpH = arrowUp.children[1]
    arrowDownH = arrowDown.children[1]
    arrowStopH = arrowStop.children[1]
  }

  return {
    arrowsWidgetComp
    arrowsWidgetParts
  }
}

return mkArrowsWidgetComps