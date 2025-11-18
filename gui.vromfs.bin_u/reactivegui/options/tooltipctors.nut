from "%globalsDarg/darg_library.nut" import *
let { unitClassFontIcons } = require("%appGlobals/unitPresentation.nut")
let { OPT_HUD_RELOAD_STYLE } = require("%rGui/options/guiOptions.nut")
let { mkTooltipText } = require("%rGui/tooltip.nut")


let touchButtonSize = shHud(10)

let mkHudReloadStyleDescItem = @(img, title, isPrimaryStyle) {
  size = [hdpx(250), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = hdpx(10)
  halign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_TEXTAREA
      behavior = [Behaviors.TextArea, Behaviors.Marquee]
      maxWidth = hdpx(200)
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      color = 0xFFFFFFFF
      text = title
    }.__update(fontTinyAccented)
    {
      size = [touchButtonSize, touchButtonSize + ((0.4 * touchButtonSize).tointeger())]
      flow = FLOW_VERTICAL
      children = [
        {
          valign = ALIGN_CENTER
          halign = ALIGN_CENTER
          size = [touchButtonSize, touchButtonSize]
          children = [
            {
              size = flex()
              rendObj = ROBJ_PROGRESS_CIRCULAR
              fgColor = isPrimaryStyle ? 0x80808080 : 0x80405780
              bgColor = 0x26000000
              fValue = 1
              animations = [{ prop = AnimProp.fValue, from = 0.0, to = 1.0, duration = 2, play = true, loop = true }]
            }.__update(isPrimaryStyle ? { image = Picture($"ui/gameuiskin#hud_movement_stop2_bg_loading.svg:P") } : {})
            {
              size = flex()
              rendObj = ROBJ_BOX
              borderColor = Color(218, 218, 218)
              borderWidth = hdpx(3)
            }
            {
              rendObj = ROBJ_IMAGE
              size = [touchButtonSize, touchButtonSize]
              image = Picture($"{img}:{touchButtonSize}:{touchButtonSize}:P")
              keepAspect = KEEP_ASPECT_FIT
              color = 0xFFFFFFFF
            }
          ]
        }
        {
          size = flex()
          rendObj = ROBJ_TEXT
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          color = 0xFFFFFFFF
          text = 10
        }.__update(fontTinyShaded)
      ]
    }
  ]
}

let mkUnitClassFilterDesc = @(unitClassList) @() {
  watch = unitClassList
  flow = FLOW_VERTICAL
  gap = hdpx(15)
  halign = ALIGN_LEFT
  children = unitClassList.get().map(@(unitClass) {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    halign = ALIGN_LEFT
    gap = hdpx(20)
    children = [
      {
        rendObj = ROBJ_TEXT
        text = unitClassFontIcons?[unitClass] ?? ""
        color = 0xFFFFFFFF
        fontFx = FFT_GLOW
        fontFxFactor = 64
        fontFxColor = 0xFF000000
      }.__update(fontSmallShaded)
      {
        rendObj = ROBJ_TEXT
        text = loc($"type/{unitClass}")
      }.__update(fontSmallShaded)
    ]
  })
}

let optionTooltipCtors = {
  [OPT_HUD_RELOAD_STYLE] = {
    flow = FLOW_VERTICAL
    gap = hdpx(8)
    children = [
      mkTooltipText(colorize("@darken", loc("options/desc/hud_reload_style")))
      {
        flow = FLOW_HORIZONTAL
        gap = hdpx(20)
        children = [
          mkHudReloadStyleDescItem("ui/gameuiskin#hud_consumable_repair.svg", loc("options/when_disable"), false)
          mkHudReloadStyleDescItem("ui/gameuiskin#hud_consumable_repair.svg", loc("options/when_enable"), true)
        ]
      }
    ]
  }
  unitClass = @(allValues) {
    flow = FLOW_VERTICAL
    gap = hdpx(8)
    children = [
      mkTooltipText(colorize("@darken", loc("options/unitClass")))
      mkUnitClassFilterDesc(allValues)
    ]
  }
}

function mkOvrTooltipContent(tooltipCtorId, dataW = Watched({})) {
  if (tooltipCtorId not in optionTooltipCtors) {
    logerr($"Tooltip: Missing tooltipCtorId {tooltipCtorId}")
    return @() null
  }

  return @() type(optionTooltipCtors[tooltipCtorId]) == "function"
    ? optionTooltipCtors[tooltipCtorId](dataW)
    : optionTooltipCtors[tooltipCtorId]
}

return { mkOvrTooltipContent }
