from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { TouchScreenStick } = require("wt.behaviors")
let { Point2 } = require("dagor.math")
let { sqrt } = require("math")
let { get_decal_pos } = require("unitCustomization")
let { exitDecalMode, rotateDecalMode, moveDecalMode, scaleDecalMode,
  rotateDecal, moveDecal, scaleDecal, curDecalPosition, isManipulatorInProgress
} = require("%rGui/unitCustom/unitDecals/unitDecalsState.nut")
let { textButtonPrimary } = require("%rGui/components/textButton.nut")
let { textColor } = require("%rGui/style/stdColors.nut")
let decalSideOptions = require("%rGui/unitCustom/unitDecals/decalSideOptions.nut")


let actionsGap = hdpx(30)
let optContainerBtnSize = hdpx(300)
let optBtnSize = hdpx(90)
let optBorderWidth = hdpxi(4)
let optImgSize = hdpx(50)
let optBorderRadius = optBtnSize / 2
let stickRadius = sw(100)
let optBtnRadius = optBtnSize / 2
let centerLinksDistance = optContainerBtnSize / 2 - optBtnRadius
let lengthBetweenBnts = centerLinksDistance * sqrt(2)
let lengthLink = ((lengthBetweenBnts - optBtnSize) / 1.9).tointeger()
let displaceManipulator = [-optContainerBtnSize / 2 - optBtnSize, -optContainerBtnSize / 2 - optBtnSize / 2]
let rotateOffset = Point2(hdpx(63), -hdpx(63))

function mkStickOptBtn(icon, stickColor, handleTouch, handleChange) {
  let stateFlags = Watched(0)

  return @() {
    watch = [stateFlags, isManipulatorInProgress]
    size = optBtnSize
    behavior = TouchScreenStick
    rendObj = ROBJ_BOX
    borderWidth = optBorderWidth
    borderRadius = optBorderRadius
    borderColor = isManipulatorInProgress.get() ? 0x00000000 : stickColor
    maxValueRadius = stickRadius
    minChange = 0.003
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = {
      size = optImgSize
      rendObj = ROBJ_IMAGE
      image = Picture($"{icon}:{optImgSize}:{optImgSize}:P")
      keepAspect = true
      color = (stateFlags.get() & S_ACTIVE) || isManipulatorInProgress.get() ? 0x00000000 : textColor
    }
    onTouchBegin = @() handleTouch(true)
    onTouchEnd = @() handleTouch(false)
    onChange = @(v) handleChange(v)
    onElemState = @(sf) stateFlags.set(sf)
    sound = { click  = "click" }
    transform = { scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.98, 0.98] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]
  }
}

let rotateButton = @(color) mkStickOptBtn("ui/gameuiskin#icon_decal_rotation.svg", color, rotateDecalMode,
  @(d) rotateDecal(d, rotateOffset + Point2(1, 1) * optBtnSize))
let moveButton = @(color) mkStickOptBtn("ui/gameuiskin#icon_decal_move.svg", color, moveDecalMode, @(d) moveDecal(d, actionsGap))
let sizeButton = @(color) mkStickOptBtn("ui/gameuiskin#icon_decal_scale.svg", color, scaleDecalMode, scaleDecal)

let saveButton = textButtonPrimary(utf8ToUpper(loc("msgbox/btn_apply")), @() exitDecalMode(true))

let mkBtnLink = @(color, ovr = {}) @() {
  watch = isManipulatorInProgress
  size = [lengthLink, hdpx(8)]
  rendObj = ROBJ_SOLID
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  color = isManipulatorInProgress.get() ? 0x00000000 : color
  transform = { rotate = -45 }
}.__update(ovr)

let decalActions = @() {
  size = SIZE_TO_CONTENT
  pos = displaceManipulator
  children = {
    size = optContainerBtnSize
    children = [
      {
        size = flex()
        valign = ALIGN_TOP
        halign = ALIGN_RIGHT
        children = [
          mkBtnLink(0xFF22B14C, { pos = [rotateOffset.x, rotateOffset.y] })
          rotateButton(0xFF22B14C)
        ]
      }
      {
        size = flex()
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        children = [
          mkBtnLink(0xFFED1C24, { pos = [hdpx(43), -hdpx(43)] })
          moveButton(0xFFED1C24)
          mkBtnLink(0xFFED1C24, { pos = [-hdpx(43), hdpx(43)] })
        ]
      }
      {
        size = flex()
        valign = ALIGN_BOTTOM
        halign = ALIGN_LEFT
        children = [
          mkBtnLink(0xFF3F48CC, { pos = [-hdpx(63), hdpx(63)] })
          sizeButton(0xFF3F48CC)
        ]
      }
    ]
  }
  behavior = Behaviors.RtPropUpdate
  update = function() {
    let projPos = get_decal_pos()
    let decalPos = projPos.x > 0 ? projPos : Point2(sw(50), sh(50))
    curDecalPosition.set(decalPos)
    return {
      transform = {
        translate = [decalPos.x, decalPos.y]
      }
    }
  }
}

let leftBottomActions = @() {
  watch = isManipulatorInProgress
  hplace = ALIGN_LEFT
  vplace = ALIGN_BOTTOM
  flow = FLOW_HORIZONTAL
  gap = hdpx(100)
  children = isManipulatorInProgress.get() ? null
    : [
        saveButton
        decalSideOptions
      ]
}

let decalsEditor = {
  size = saSize
  hplace = ALIGN_LEFT
  vplace = ALIGN_BOTTOM
  children = [
    decalActions
    leftBottomActions
  ]
}

return {
  decalsEditor
}
