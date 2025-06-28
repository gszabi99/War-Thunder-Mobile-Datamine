from "%globalsDarg/darg_library.nut" import *
let { scaleArr } = require("%globalsDarg/screenMath.nut")
let { prettyScaleForSmallNumberCharVariants } = require("%globalsDarg/fontScale.nut")
let { oxygen, waterDist, periscopeDepthCtrl } = require("%rGui/hud/shipState.nut")


let textPadding = hdpx(5)
let depthWidth = hdpxi(165)
let depthHeight = hdpxi(105)
let oxigenProgressSize = [hdpx(108), hdpx(10)]
let oxigenBlockSize = [oxigenProgressSize[0], hdpx(70)]

let zeroOxygen = Computed(@() oxygen.value.tointeger() == 0)
let depthText = Computed(@() zeroOxygen.value ? loc("controls/lack_of_oxygen")
  : waterDist.value.tointeger() == 0 ? loc("controls/submarine_on_water")
  : waterDist.value.tointeger() <= periscopeDepthCtrl.value.tointeger() ? loc("controls/submarine_depth_periscope")
  : loc("controls/submarine_depth")
)

depthText.subscribe(@(_) zeroOxygen.value
  ? anim_start("depth_oxygen_highlight")
  : anim_start("depth_status_highlight")
)

let oxygenMark = @(scale) {
  flow = FLOW_HORIZONTAL
  children = [
    {
      rendObj = ROBJ_TEXT
      text =  "O"
    }.__update(prettyScaleForSmallNumberCharVariants(fontMediumShaded, scale))
    {
      rendObj = ROBJ_TEXT
      pos = [0, hdpx(20 * scale)]
      text =  "2"
    }.__update(prettyScaleForSmallNumberCharVariants(fontTinyShaded, scale))
  ]
}

let mText = loc("measureUnits/meters_alt")

function depthControl(scale) {
  let font1 = prettyScaleForSmallNumberCharVariants(fontTinyAccentedShaded, scale)
  let font2 = prettyScaleForSmallNumberCharVariants(fontVeryTinyShaded, scale)
  return {
    halign = ALIGN_RIGHT
    valign = ALIGN_BOTTOM
    gap = hdpx(5 * scale)
    size = scaleArr([depthWidth, depthHeight], scale)
    flow = FLOW_VERTICAL
    children = [
      @() {
        watch = waterDist
        rendObj = ROBJ_TEXT
        text = $"{waterDist.value.tointeger()} {mText}"
        padding = [0, textPadding, 0, 0]
      }.__update(font1)
      {
        size = FLEX_H
        rendObj = ROBJ_SOLID
        color = 0,
        padding = textPadding
        animations = [
          {
            prop = AnimProp.color,
            to = Color(44, 253, 255, 80),
            duration = 1,
            easing = CosineFull,
            trigger = "depth_status_highlight"
          }
          {
            prop = AnimProp.color,
            from = Color(0, 0, 0, 0),
            to = Color(255, 1, 1, 80),
            duration = 1,
            easing = CosineFull,
            trigger = "depth_oxygen_highlight"
          }
        ]
        children = @() {
          watch = [waterDist, periscopeDepthCtrl]
          rendObj = ROBJ_TEXTAREA
          size = FLEX_H
          halign = ALIGN_RIGHT
          behavior = [Behaviors.TextArea]
          text = depthText.value
        }.__update(font2)
      }
    ]
  }
}

let depthControlEditView = {
  halign = ALIGN_RIGHT
  valign = ALIGN_BOTTOM
  gap = hdpx(5)
  size = [depthWidth, depthHeight]
  flow = FLOW_VERTICAL
  children = [
    {
      padding = [0, textPadding, 0, 0]
      rendObj = ROBJ_TEXT
      text = $"XX {mText}"
    }.__update(fontTinyAccentedShaded)
    {
      margin = textPadding
      rendObj = ROBJ_TEXTAREA
      size = FLEX_H
      halign = ALIGN_RIGHT
      behavior = [Behaviors.TextArea]
      text = loc("controls/submarine_depth")
    }.__update(fontVeryTinyShaded)
  ]
}

let oxygenLevel = @(scale) {
  size = scaleArr(oxigenBlockSize, scale)
  halign = ALIGN_RIGHT
  flow = FLOW_VERTICAL
  gap = hdpx(5 * scale)
  children = [
    oxygenMark(scale)
    {
      size = scaleArr(oxigenProgressSize, scale)
      children = [
        {
          rendObj = ROBJ_SOLID
          color = Color(44, 44, 44, 200)
          size = flex()
        },
        @() {
          watch = oxygen
          rendObj = ROBJ_SOLID
          color = Color(44, 253, 255)
          size = flex()
          transform = { pivot = [0, 1], scale = [oxygen.value / 100.0, 1] }
          transitions = [{ prop = AnimProp.scale, duration = 0.5 }]
        }
      ]
    }
  ]
}

let oxygenLevelEditView = {
  size = oxigenBlockSize
  halign = ALIGN_RIGHT
  gap = hdpx(5)
  flow = FLOW_VERTICAL
  children = [
    oxygenMark(1)
    {
      size = oxigenProgressSize
      children = [
        {
          rendObj = ROBJ_SOLID
          color = Color(44, 253, 255)
          size = flex()
        }
      ]
    }
  ]
}

return {
  oxygenLevel
  oxygenLevelEditView
  depthControl
  depthControlEditView
}