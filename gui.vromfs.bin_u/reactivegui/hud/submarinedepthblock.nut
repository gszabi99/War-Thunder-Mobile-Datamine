from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { fabs } = require("math")
let { scaleArr } = require("%globalsDarg/screenMath.nut")
let { prettyScaleForSmallNumberCharVariants } = require("%globalsDarg/fontScale.nut")
let { isGamepad } = require("%appGlobals/activeControls.nut")
let { dfAnimBottomRight } = require("%rGui/style/unitDelayAnims.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { setAxisValue, toggleShortcut } = require("%globalScripts/controls/shortcutActions.nut")
let { wishDist, waterDist, periscopeDepthCtrl, deadZoneDepth, maxControlDepth } = require("%rGui/hud/shipState.nut")
let { mkGamepadShortcutImage, mkContinuousButtonParams
} = require("%rGui/controls/shortcutSimpleComps.nut")
let { updateActionBarDelayed } = require("actionBar/actionBarState.nut")


let markStep = 5
let marksTextStep = 4
let depthRepeatTimes = [0.3, 0.15, 0.15, 0.07, 0.07, 0.05]
let knobColor = Color(230, 230, 230, 230)

let isDepthIncPushed = Watched(false)
let isDepthDecPushed = Watched(false)
let depthChangeDir = Computed(@() isDepthIncPushed.value == isDepthDecPushed.value ? 0
  : isDepthIncPushed.value ? 1
  : -1)

let periscopSize = [hdpxi(70), hdpxi(50)]

function getSizes(scale) {
  let height = hdpx(380 * scale)
  let scaleWidth = evenPx(13 * scale)
  let scaleImgHeight = (177.0 / 12 * scaleWidth + 0.5).tointeger()
  let knobSize = 3 * scaleWidth
  let sliderPadding = 4 * scaleWidth
  let fullWidth = knobSize + 2 * sliderPadding
  return { height, scaleWidth, scaleImgHeight, knobSize, sliderPadding, fullWidth }
}

local updateCount = 0
function depthValueUpdate() {
  if (depthChangeDir.value == 0 || periscopeDepthCtrl.value == 0) {
    updateCount = 0
    return
  }
  let curDepth = wishDist.value * maxControlDepth.value
  let newDepth = clamp(curDepth + markStep * depthChangeDir.value, periscopeDepthCtrl.value, maxControlDepth.value)
  if (curDepth == newDepth) {
    updateCount = 0
    return
  }
  setAxisValue("submarine_depth", newDepth.tofloat() / maxControlDepth.value)
  resetTimeout(depthRepeatTimes?[updateCount++] ?? depthRepeatTimes.top(), depthValueUpdate)
}

depthChangeDir.subscribe(@(_) depthValueUpdate())

let mkMarksOfDepth = @(countOfMarks, firstMark, scale) {
  size = [hdpx(20 * scale), flex()]
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = hdpx(2.5 * scale)
  commands = array(max(1, countOfMarks - firstMark)).map(function(_, i) {
    let y = 100.0 * (i + firstMark) / max(1, countOfMarks - 1)
    return [VECTOR_LINE, 0, y, 100 - 50 * ((i + 1) % 2), y]
  })
}

function mkMarksOfDepthTexts(countOfMarks, scale) {
  let iconSize = scaleArr(periscopSize, scale)
  let font = prettyScaleForSmallNumberCharVariants(fontTinyShaded, scale)
  return {
    size = FLEX_V
    margin = [0, 0, 0, hdpx(5 * scale)]
    children = array(countOfMarks / marksTextStep)
      .map(@(_, i) {
        rendObj = ROBJ_TEXT
        vplace = ALIGN_CENTER
        pos = [0, ph(100.0 * i * marksTextStep / (countOfMarks - 1) - 35)]
        text = i * markStep * marksTextStep + 20
      }.__update(font))
      .append({
        size = iconSize
        pos = [0, -hdpx(33 * scale)]
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#hud_periscope.svg:{iconSize[0]}:{iconSize[1]}:P")
      })
  }
}

let isDeeperThanPeriscopeDepth = Computed(@() waterDist.value.tointeger() > periscopeDepthCtrl.value.tointeger())
let isNotOnTheSurface = Computed(@() waterDist.value.tointeger() > periscopeDepthCtrl.value.tofloat() / 2)

let isControlDepthAllowed = Computed(function(prev) {
  let wishDepth = wishDist.value * maxControlDepth.value
  let periscopeDepth = periscopeDepthCtrl.value.tofloat() * 0.7 - 1.0
  if (waterDist.value >= periscopeDepth && wishDepth >= periscopeDepthCtrl.value)
    return true
  if (wishDepth < periscopeDepthCtrl.value)
    return false
  return prev == FRP_INITIAL ? false : prev
})

function mkGamepadShortcutImg(shortcutId, isPushed, isVisible, scale, ovr) {
  let imageComp = mkGamepadShortcutImage(shortcutId, {}, scale)
  let stateFlags = Watched(0)
  let res = mkContinuousButtonParams(@() isPushed(true), @() isPushed(false), shortcutId, stateFlags)
    .__update(ovr)
  let watch = [isVisible, isGamepad, stateFlags]
  return @() !isGamepad.value ? { watch }
    : res.__update({
        watch
        key = imageComp
        vplace = ALIGN_CENTER
        children = isVisible.value && isGamepad.value ? imageComp : null
        transform = { scale = stateFlags.value & S_ACTIVE ? [0.8, 0.8] : [1.0, 1.0] }
        transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]
      })
}

let btnImageDepthInc = @(scale) mkGamepadShortcutImg("submarine_depth_inc",
  isDepthIncPushed,
  Computed(@() fabs(wishDist.value - 1) > 0.01),
  scale,
  { hplace = ALIGN_RIGHT, pos = [pw(-100), ph(50)] })
let btnImageDepthDec = @(scale) mkGamepadShortcutImg("submarine_depth_dec",
  isDepthDecPushed,
  Computed(@() fabs(wishDist.value * maxControlDepth.value - periscopeDepthCtrl.value) > 0.01),
  scale,
  { hplace = ALIGN_RIGHT, pos = [pw(-100), ph(-50)] })

function mkDepthSlider(scale) {
  let { height, scaleWidth, scaleImgHeight, knobSize, sliderPadding, fullWidth } = getSizes(scale)
  let inc = btnImageDepthInc(scale)
  let dec = btnImageDepthDec(scale)
  return function() {
    let minVal = maxControlDepth.value > 0 ? periscopeDepthCtrl.value / maxControlDepth.value : 0.0
    let deadZoneVal = maxControlDepth.value > 0 ? deadZoneDepth.value / maxControlDepth.value : 0.0
    let countOfMarks = max(maxControlDepth.value / markStep, 2).tointeger()
    let firstMark = (deadZoneDepth.value / markStep).tointeger()

    let wishDistClamped = clamp(wishDist.value, minVal, 1.0)

    let knob = {
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      pos = [0, ph(100.0 * (wishDistClamped - minVal) / (1.0 - minVal) - 50)]
      children = {
        size  = [knobSize, knobSize]
        rendObj = ROBJ_SOLID
        color = knobColor
        transform = { rotate = 45 }
      }
    }

    return {
      watch = [wishDist, periscopeDepthCtrl, maxControlDepth]
      size = [fullWidth, height]
      padding = sliderPadding
      behavior = Behaviors.Slider
      fValue = wishDist.value
      knob = knob
      min = minVal
      max = 1.0
      unit = 0.01
      orientation = O_VERTICAL
      flow = FLOW_HORIZONTAL
      children = [
        {
          size = [scaleWidth, flex()]
          children = [
            {
              size = [scaleWidth, height - 2 * sliderPadding + scaleWidth]
              vplace = ALIGN_CENTER
              rendObj = ROBJ_9RECT
              image = Picture($"ui/gameuiskin#hud_plane_slider.avif:{scaleWidth}:{scaleImgHeight}:P")
              texOffs = [scaleWidth, 0]
              screenOffs = [scaleWidth, 0]
            }
            knob
            inc
            dec
          ]
        }
        mkMarksOfDepth(countOfMarks, firstMark, scale)
        mkMarksOfDepthTexts(countOfMarks, scale)
      ]
      onChange = function(val) {
        if (!isDeeperThanPeriscopeDepth.value && wishDist.value == 0) {
          toggleShortcut("ID_DIVING_LOCK")
          updateActionBarDelayed()
        } else {
          let newVal = val < minVal + deadZoneVal / 2.0 ? minVal : max(minVal + deadZoneVal, val)
          setAxisValue("submarine_depth", newVal)
        }
      }
      transform = {}
      animations = dfAnimBottomRight.extend(wndSwitchAnim)
    }
  }
}

function depthSliderBlock(scale) {
  let depthSlider = mkDepthSlider(scale)
  return @() {
    watch = isControlDepthAllowed
    opacity = isControlDepthAllowed.value ? 1 : 0.3
    children = depthSlider
    transitions = [
      { prop = AnimProp.opacity, duration = 0.5, easing = InOutQuad }
    ]
  }
}

function mkDepthSliderEditView() {
  let { height, scaleWidth, scaleImgHeight, knobSize, sliderPadding, fullWidth } = getSizes(1)
  return {
    size = [fullWidth, height]
    padding = sliderPadding
    flow = FLOW_HORIZONTAL
    children = [
      {
        size = [scaleWidth, flex()]
        children = [
          {
            size = [scaleWidth, height - 2 * sliderPadding + scaleWidth]
            vplace = ALIGN_CENTER
            rendObj = ROBJ_9RECT
            image = Picture($"ui/gameuiskin#hud_plane_slider.avif:{scaleWidth}:{scaleImgHeight}:P")
            texOffs = [scaleWidth, 0]
            screenOffs = [scaleWidth, 0]
          }
          {
            size  = [knobSize, knobSize]
            vplace = ALIGN_CENTER
            hplace = ALIGN_CENTER
            rendObj = ROBJ_SOLID
            color = knobColor
            transform = { rotate = 45 }
          }
        ]
      }
      { size = const [hdpx(25), 0] } 
      {
        size = periscopSize
        pos = [0, -hdpx(33)]
        hplace = ALIGN_RIGHT
        vplace = ALIGN_TOP
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#hud_periscope.svg:{periscopSize[0]}:{periscopSize[1]}:P")
      }
    ]
  }
}

return {
  depthSliderBlock
  depthSliderEditView = mkDepthSliderEditView()
  isDeeperThanPeriscopeDepth
  isNotOnTheSurface
}
