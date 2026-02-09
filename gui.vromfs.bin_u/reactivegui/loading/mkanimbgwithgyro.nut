from "%globalsDarg/darg_library.nut" import *
from "%sqstd/platform.nut" import is_pc
from "%appGlobals/activeControls.nut" import isGamepad
from "%globalsDarg/components/mkAnimBg.nut" import mkAnimBg, leftShade, rightShade
from "%rGui/controls/shortcutConsts.nut" import GRAVITY_AXIS_Y, JOY_XBOX_REAL_AXIS_R_THUMB_H
import "%rGui/controls/axisListener.nut" as axisListener

let axisV = Watched(0)
let gyroListener = axisListener({ [GRAVITY_AXIS_Y] = @(v) axisV.set(v) })
let gamepadListener = axisListener({ [JOY_XBOX_REAL_AXIS_R_THUMB_H] = @(v) axisV.set(v) })

function mkGyroBgLayer(layerCfg) {
  let { moveX = 0, children = null } = layerCfg
  if (moveX == 0 || children == null)
    return children
  return {
    size = flex()
    children
    behavior = Behaviors.RtPropUpdate
    onlyWhenParentInScreen = true
    transform = { translate = [axisV.get() * moveX, 0] }
    update = @() { transform = { translate = [axisV.get() * moveX, 0] } }
    transitions = [{ prop = AnimProp.translate, duration = 0.05, easing = InQuad }]
  }
}

let mkGyroBg = @(layersCfg) {
  size = const [sw(100), sh(100)]
  rendObj = ROBJ_SOLID
  color = 0xFF000000
  halign = ALIGN_CENTER

  children = {
    size = const [sh(250), sh(100)]
    children = layersCfg.map(mkGyroBgLayer)
      .append(leftShade, rightShade)
  }
}

let mkAnimBgWithGyro = @(layersCfg) @() {
  watch = isGamepad
  size = flex()
  children = is_pc && !isGamepad.get() ? mkAnimBg(layersCfg)
    : [
        mkGyroBg(layersCfg)
        is_pc ? gamepadListener : gyroListener
      ]
}

return {
  mkAnimBgWithGyro
}