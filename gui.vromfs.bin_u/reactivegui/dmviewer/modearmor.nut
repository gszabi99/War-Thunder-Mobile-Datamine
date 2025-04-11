from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { DM_VIEWER_ARMOR, hangar_get_dm_viewer_parts_count } = require("hangar")
let { dmViewerMode, dmViewerUnitReady } = require("dmViewerState.nut")
let { toggleSubscription, mkDmViewerHint, mkHintTitle, mkHintDescText, accentColor, mkUnitStatusText
} = require("dmViewerPkg.nut")
let { collectArmorClassToSteelMuls } = require("modeArmorUtils.nut")
let { hasNotDownloadedPkgForHangarUnit } = require("%rGui/unit/hangarUnit.nut")

let absoluteArmorThreshold = 500
let relativeArmorThreshold = 5.0
let showStellEquivForArmorClassesList = [ "ships_coal_bunker" ]
let armorClassToSteel = {}

let isModeActive = Computed(@() dmViewerMode.get() == DM_VIEWER_ARMOR)

local isInited = false
function init() {
  if (isInited)
    return
  isInited = true
  armorClassToSteel.__update(collectArmorClassToSteelMuls(showStellEquivForArmorClassesList))
}
isModeActive.subscribe(@(v) v ? init() : null)
if (isModeActive.get())
  init()

let scrPosX = Watched(0)
let scrPosY = Watched(0)
let angleW = Watched(0.0)
let normalAngleW = Watched(0.0)
let thicknessW = Watched(0.0)
let effectiveThicknessRawW = Watched(0.0)
let isSolidW = Watched(false)
let isVariableThicknessW = Watched(false)
let nameW = Watched("")

function onUpdateHintArmor(p) {
  let { posX, posY, angle, normal_angle, thickness, effective_thickness, solid,
    variable_thickness = false, name = ""
  } = p
  scrPosX.set(posX)
  scrPosY.set(posY)
  angleW.set(round(angle))
  normalAngleW.set(round(normal_angle))
  thicknessW.set(thickness)
  effectiveThicknessRawW.set(effective_thickness)
  isSolidW.set(solid)
  isVariableThicknessW.set(variable_thickness)
  nameW.set(name)
}

let toggleSub = @(isEnable) toggleSubscription("on_hangar_damage_part_pick", onUpdateHintArmor, isEnable)
isModeActive.subscribe(toggleSub)
toggleSub(isModeActive.get())

let txtVariableThicknessArmor = loc("armor_class/variable_thickness_armor")
let txtThickness = loc("armor_class/thickness")
let txtNormalAngle = loc("armor_class/normal_angle")
let txtMm = loc("measureUnits/mm")
let txtDeg = loc("measureUnits/deg")
let txtImpactAngle = loc("armor_class/impact_angle")
let txtArmorDimensionAtPoint = loc("armor_class/armor_dimensions_at_point")
let txtEffectiveThickness = loc("armor_class/effective_thickness")

function hintComp() {
  if (!isModeActive.get())
    return { watch = isModeActive }

  let isHintVisible = Computed(@() isModeActive.get() && dmViewerUnitReady.get()
    && (scrPosX.get() != 0 || scrPosY.get() != 0 || thicknessW.get() != 0 || nameW.get() != ""))

  let hintTitleW = Computed(@() loc($"armor_class/{nameW.get()}"))
  let effectiveThicknessW = Computed(@() round(effectiveThicknessRawW.get()))
  let thicknessToSteelMulW = Computed(@() armorClassToSteel?[nameW.get()] ?? 0.0)
  let effectiveThicknessToSteelW = Computed(@() round(effectiveThicknessRawW.get() * thicknessToSteelMulW.get()))
  let effectiveThicknessClampedW = Computed(@() round(min(effectiveThicknessW.get(),
    (relativeArmorThreshold * thicknessW.get()).tointeger(), absoluteArmorThreshold)))

  let hintTitle = mkHintTitle(hintTitleW)
  let hintDesc = [
    Computed(function() {
      if (isSolidW.get() && isVariableThicknessW.get())
        return txtVariableThicknessArmor
      if (thicknessW.get() != 0)
        return nbsp.concat(txtThickness, colorize(accentColor, thicknessW.get()), txtMm)
      return ""
    }),
    Computed(@() nbsp.concat(txtNormalAngle, normalAngleW.get(), txtDeg)),
    Computed(@() nbsp.concat(txtImpactAngle, angleW.get(), txtDeg)),
    Computed(function() {
      if (effectiveThicknessW.get() == 0 || !isSolidW.get())
        return ""
      let desc = [
        nbsp.concat(txtArmorDimensionAtPoint, colorize(accentColor, effectiveThicknessW.get()), txtMm)
      ]
      if (effectiveThicknessToSteelW.get() != 0) {
        let equivSteelStr = nbsp.concat(colorize(accentColor, effectiveThicknessToSteelW.get()), txtMm)
        desc.append(loc("shop/armorThicknessEquivalent/steel", { thickness = equivSteelStr }))
      }
      return "\n".join(desc)
    }),
    Computed(function() {
      if (effectiveThicknessW.get() == 0 || isSolidW.get())
        return ""
      let sign = effectiveThicknessClampedW.get() < effectiveThicknessW.get() ? ">" : ""
      let effectiveThicknessStr = "".concat(sign, effectiveThicknessClampedW.get())
      return nbsp.concat(txtEffectiveThickness, effectiveThicknessStr, txtMm)
    }),
  ].map(mkHintDescText)

  let hintContent = {
    flow = FLOW_VERTICAL
    children = [ hintTitle ].extend(hintDesc)
  }

  return {
    watch = isModeActive
    size= flex()
    children = mkDmViewerHint(isHintVisible, scrPosX, scrPosY, hintContent)
  }
}

let unitStatusComp = @() !isModeActive.get() ? { watch = isModeActive } : {
  watch = [isModeActive, dmViewerUnitReady, hasNotDownloadedPkgForHangarUnit]
  size = flex()
  children = !hasNotDownloadedPkgForHangarUnit.get() && isModeActive.get() &&
      dmViewerUnitReady.get() && hangar_get_dm_viewer_parts_count() == 0
    ? mkUnitStatusText(loc("armor_class/no_armoring/common"))
    : null
}

let modeArmorComps = [
  unitStatusComp
  hintComp
]

return {
  modeArmorComps
}
