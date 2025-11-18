from "%globalsDarg/darg_library.nut" import *
let { mirror_current_decal, get_mirror_current_decal, hangar_toggle_abs, get_hangar_abs,
  set_hangar_opposite_mirrored, get_hangar_opposite_mirrored
} = require("unitCustomization")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { textColor, selectColor } = require("%rGui/style/stdColors.nut")
let { isEditingDecal } = require("%rGui/unitCustom/unitDecals/unitDecalsState.nut")
let { mkButtonHoldTooltip } = require("%rGui/tooltip.nut")
let { eventbus_subscribe } = require("eventbus")


enum decalTwoSidedMode {
  OFF
  ON
  ON_MIRRORED
}

let decalSideOptionsList = [
  {
    id = decalTwoSidedMode.OFF
    img = "ui/gameuiskin#icon_decal_single_side.svg"
    locId = "mainmenu/edit/decals/twosided/off"
  },
  {
    id = decalTwoSidedMode.ON
    img = "ui/gameuiskin#icon_decal_two_sided.svg"
    locId = "mainmenu/edit/decals/twosided"
  },
  {
    id = decalTwoSidedMode.ON_MIRRORED
    img = "ui/gameuiskin#icon_decal_two_sided_mirrored.svg"
    locId = "mainmenu/edit/decals/twosided/mirrored"
  }
]

let selectedOptId = mkWatched(persist, "selectedOptId", decalTwoSidedMode.OFF)
let isFlipActive = mkWatched(persist, "isFlipActive", false)

let flipOpt = { img = "ui/gameuiskin#icon_decal_flip.svg", locId = "mainmenu/edit/decals/flip", isOptActive = isFlipActive }

let actionsGap = hdpx(30)
let optBorderWidth = hdpxi(4)
let optImgSize = hdpx(50)

function mkOptBtn(opt, onClick) {
  let { id = null, img = "", locId = "", isOptActive = Watched(false) } = opt
  let isActive = Computed(@() id == selectedOptId.get() || isOptActive.get())
  let stateFlags = Watched(0)
  let key = {}

  return @() {
    watch = [stateFlags, isActive]
    key
    size = defButtonHeight
    behavior = Behaviors.Button
    rendObj = ROBJ_BOX
    borderWidth = optBorderWidth
    borderColor = isActive.get() ? selectColor : textColor
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = {
      size = optImgSize
      rendObj = ROBJ_IMAGE
      image = Picture($"{img}:{optImgSize}:{optImgSize}:P")
      keepAspect = true
      color = isActive.get() ? selectColor : textColor
    }
    onElemState = @(sf) stateFlags.set(sf)
    sound = { click  = "click" }
    transform = { scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.98, 0.98] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]
  }.__update(mkButtonHoldTooltip(onClick, stateFlags, key, @() { content = loc(locId) }))
}

function onFlip() {
  mirror_current_decal()
  isFlipActive.set(get_mirror_current_decal())
}

function handleOptClick(id) {
  let isTwoSided = get_hangar_abs()
  let isOppositeMirrored = get_hangar_opposite_mirrored()
  let needTwoSided = id != decalTwoSidedMode.OFF
  let needOppositeMirrored = id == decalTwoSidedMode.ON_MIRRORED
  if (needTwoSided != isTwoSided)
    hangar_toggle_abs()
  if (needOppositeMirrored != isOppositeMirrored)
    set_hangar_opposite_mirrored(needOppositeMirrored)
  selectedOptId.set(id)
}

function getTwoSidedState() {
  let isTwoSided = get_hangar_abs()
  let isOppositeMirrored = get_hangar_opposite_mirrored()
  return !isTwoSided ? decalTwoSidedMode.OFF
    : !isOppositeMirrored ? decalTwoSidedMode.ON
    : decalTwoSidedMode.ON_MIRRORED
}

function updateOptBtnStates() {
  let optId = decalSideOptionsList.findvalue(@(v) v.id == getTwoSidedState())?.id ?? decalTwoSidedMode.OFF
  selectedOptId.set(optId)
  isFlipActive.set(get_mirror_current_decal())
}

if (isEditingDecal.get())
  updateOptBtnStates()
eventbus_subscribe("on_decal_job_complete", @(v) v ? updateOptBtnStates() : null)

return {
  flow = FLOW_HORIZONTAL
  gap = actionsGap
  children = decalSideOptionsList.map(@(opt) mkOptBtn(opt, @() handleOptClick(opt.id)))
    .append(mkOptBtn(flipOpt, onFlip))
}
