from "%globalsDarg/darg_library.nut" import *
let { DM_VIEWER_NONE, DM_VIEWER_ARMOR, DM_VIEWER_XRAY } = require("hangar")
let { allow_dm_viewer, allow_dm_viewer_ships_armor } = require("%appGlobals/permissions.nut")
let { mkColoredGradientY } = require("%rGui/style/gradients.nut")
let { dmViewerMode } = require("dmViewerState.nut")
let { SHIP, BOAT, SUBMARINE } = require("%appGlobals/unitConst.nut")

let forAnyUnit = @(_unitW) Watched(true)
let noArmorForShips = @(unitW) Computed(
  @() allow_dm_viewer_ships_armor.get() || ![ SHIP, BOAT, SUBMARINE ].contains(unitW.get()?.unitType))

let btnsCfg = [
  { mode = DM_VIEWER_NONE,  text = loc("dm_viewer/mode/none"),  mkIsVisible = forAnyUnit }
  { mode = DM_VIEWER_ARMOR, text = loc("dm_viewer/mode/armor"), mkIsVisible = noArmorForShips }
  { mode = DM_VIEWER_XRAY,  text = loc("dm_viewer/mode/xray"),  mkIsVisible = forAnyUnit }
]

let plateH = hdpx(70)
let platePad = hdpx(5)
let btnH = plateH - (2 * platePad)
let lightColor = 0xFFCACACA
let darkColor = 0xFF292929
let hoverColor = 0xFF606060

let btnBgSelected = {
  size = flex()
  rendObj = ROBJ_IMAGE
  image = mkColoredGradientY(0xFFFFFFFF, 0xFF7A7A7A)
}

let btnBgHovered = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = hoverColor
}

function mkModeBtn(btnCfg, unitW) {
  let { mode, text, mkIsVisible } = btnCfg
  let stateFlags = Watched(0)
  let isSelected = Computed(@() dmViewerMode.get() == mode)
  let isVisible = mkIsVisible(unitW)
  return @() !isVisible.get() ? { watch = isVisible } : {
    watch = [stateFlags, isSelected, isVisible]
    size = [flex(), btnH]

    behavior = Behaviors.Button
    onElemState = @(v) stateFlags.set(v)
    onClick = @() dmViewerMode.set(mode)
    sound = { click  = "click" }
    transform = { scale = stateFlags.get() & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]

    children = [
      isSelected.get() ? btnBgSelected
        : (stateFlags.get() & S_HOVER) ? btnBgHovered
        : null
      {
        vplace = ALIGN_CENTER
        hplace = ALIGN_CENTER
        rendObj = ROBJ_TEXT
        text
        color = isSelected.get() ? darkColor
          : (stateFlags.get() & S_HOVER) ? 0xFFFFFFFF
          : lightColor
      }.__update(fontTinyAccented)
    ]
  }
}

let mkModeBtnsSet = @(unitW) {
  size = [flex(), plateH]
  padding = platePad
  onDetach = @() dmViewerMode.set(DM_VIEWER_NONE)
  rendObj = ROBJ_SOLID
  color = darkColor
  flow = FLOW_HORIZONTAL
  children = btnsCfg.map(@(cfg) mkModeBtn(cfg, unitW))
}

let mkDmViewerSwitchComp = @(unitW) @() {
    watch = [allow_dm_viewer, unitW]
  }.__update(!allow_dm_viewer.get() || unitW.get() == null ? {} : mkModeBtnsSet(unitW))

return mkDmViewerSwitchComp
