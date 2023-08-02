from "%globalsDarg/darg_library.nut" import *
let { scopeSize } = require("%rGui/hud/commonSight.nut")
let { oxygen, waterDist, periscopeDepthCtrl } = require("%rGui/hud/shipState.nut")

let mText = loc("measureUnits/meters_alt")
let textPadding = hdpx(5)

let zeroOxygen = Computed(@() oxygen.value.tointeger() == 0)
let depthWidth = scopeSize[0] / 3
let depthHeight = scopeSize[1] * 0.6
let depthText = Computed(@() zeroOxygen.value ? loc("controls/lack_of_oxygen")
  : waterDist.value.tointeger() == 0 ? loc("controls/submarine_on_water")
  : waterDist.value.tointeger() <= periscopeDepthCtrl.value.tointeger() ? loc("controls/submarine_depth_periscope")
  : loc("controls/submarine_depth")
)

depthText.subscribe(@(_) zeroOxygen.value
  ? anim_start("depth_oxygen_highlight")
  : anim_start("depth_status_highlight")
)

let fontFx = {
  fontFxColor = Color(0, 0, 0, 255)
  fontFxFactor = 50
  fontFx = FFT_GLOW
}

let oxygenMark = {
  flow = FLOW_HORIZONTAL
  children = [
    {
      rendObj = ROBJ_TEXT
      text =  "O"
    }.__update(fontMedium, fontFx)
    {
      rendObj = ROBJ_TEXT
      pos = [0, hdpx(20)]
      text =  "2"
    }.__update(fontTiny, fontFx)
  ]
}

let depthControl = {
  halign = ALIGN_RIGHT
  valign = ALIGN_BOTTOM
  gap = hdpx(5)
  size = [depthWidth, depthHeight]
  flow = FLOW_VERTICAL
  children = [
    @() {
      watch = waterDist
      rendObj = ROBJ_TEXT
      text = $"{waterDist.value.tointeger()} {mText}"
      padding = [0, textPadding, 0, 0]
    }.__update(fontMedium, fontFx)
    {
      size = [flex(), SIZE_TO_CONTENT]
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
        size = [flex(), SIZE_TO_CONTENT]
        halign = ALIGN_RIGHT
        behavior = [Behaviors.TextArea]
        text = depthText.value
      }.__update(fontTiny, fontFx)
    }
  ]
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
    }.__update(fontMedium, fontFx)
    {
      margin = textPadding
      rendObj = ROBJ_TEXTAREA
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_RIGHT
      behavior = [Behaviors.TextArea]
      text = loc("controls/submarine_depth")
    }.__update(fontTiny, fontFx)
  ]
}

let oxygenLevel = {
  halign = ALIGN_RIGHT
  gap = hdpx(5)
  flow = FLOW_VERTICAL
  size = [depthWidth, SIZE_TO_CONTENT]
  children = [
    oxygenMark
    {
      size = [shHud(10), hdpx(10)]
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
  halign = ALIGN_RIGHT
  gap = hdpx(5)
  flow = FLOW_VERTICAL
  size = [depthWidth, SIZE_TO_CONTENT]
  children = [
    oxygenMark
    {
      size = [shHud(10), hdpx(10)]
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
