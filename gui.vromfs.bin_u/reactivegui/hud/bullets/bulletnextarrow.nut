from "%globalsDarg/darg_library.nut" import *
from "%sqstd/math.nut" import PI, sin, cos
from "%rGui/style/hudColors.nut" import hudPearlGrayColor


const DEG_TO_RAD = PI / 180.0

function mkNextBulletArrow(size, rotateDeg, ovr = {}) {
  let dist = (size * 0.2).tointeger()
  let moveX = (sin(rotateDeg * DEG_TO_RAD) * dist).tointeger()
  let moveY = (-cos(rotateDeg * DEG_TO_RAD) * dist).tointeger()

  return {
    size
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#spinnerListBox_arrow_up.svg:{size}:P")
    color = hudPearlGrayColor
    transform = { pivot = [0.5, 0.5], rotate = rotateDeg }
    animations = [{ prop = AnimProp.translate, from = [0, 0], to = [moveX, moveY],
      duration = 0.7, easing = CosineFull, play = true }]
  }.__update(ovr)
}

return { mkNextBulletArrow }
