from "%globalsDarg/darg_library.nut" import *
let { sqrt, pow, fabs, sin, cos, atan2, PI } = require("math")

let RAD_TO_DEG = 180.0 / PI
let DEG_TO_RAD = PI / 180.0
let textureHoleWidth = 0.54

let defaultPieMenuParams = freeze({
  pieRadius = shHud(28)
  piePosOffset = [0, shHud(-6)]
  pieIconSizeMul = 0.24
})

/**
 * Creates a pie menu component, which should be controlled with miniTouchStick.
 * @param {integer} menuItemsCount - Menu items count.
 * @param {Point2} stickDeltaV - Value of stickDelta watched.
 * @return {integer} - Selected menu item index, or -1 if nothing is selected.
 */
function getPieMenuSelectedIdx(menuItemsCount, stickDeltaV) {
  if (menuItemsCount == 0)
    return -1
  let { x, y } = stickDeltaV
  let deltaX = -x
  let deltaY = -y
  let distance = sqrt(pow(fabs(deltaX), 2) + pow(fabs(deltaY), 2))
  let angleRad = atan2(deltaX, -deltaY)
  let degPerItem = 360.0 / menuItemsCount
  let itemsAngle = ((angleRad * RAD_TO_DEG) + 360.0 + (degPerItem / 2)) % 360.0
  let idx = distance == 0 ? -1 : (itemsAngle / degPerItem).tointeger()
  return idx
}

function mkPieMenuItemIcon(c, pieRadius, pieIconSizeMul) {
  let { icon, iconScale = 1.0, iconColor = 0xFFFFFFFF } = c
  let iconSize = (pieRadius * pieIconSizeMul + 0.5).tointeger()
  let iconTexSize = (iconSize * iconScale + 0.5).tointeger()
  return {
    size = [iconSize, iconSize]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = {
      size = [iconTexSize, iconTexSize]
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#{icon}:{iconTexSize}:{iconTexSize}:P")
      keepAspect = true
      color = iconColor
    }
  }
}

let mkPieMenuItemText = @(c) {
  rendObj = ROBJ_TEXT
  text = c.label
}.__update(fontSmall)

/**
 * Creates a pie menu component, which should be controlled with miniTouchStick.
 * @param {Watched(array)} menuCfg - Watched menu items config. Items count is unlimited, but recommended from 1 to 8 items.
 *                                   Item format example: { icon = "foo.svg", iconScale = 1.0, label = "Text", action = @() null }
 *                                   Only "icon" param is required, all other params are optional.
 * @param {Watched(integer)} selIdx - Watched selected item index to be highlighted (see getPieMenuSelectedIdx func).
 * @param {table} [params] - Optional custom params, see defaultPieMenuParams.
 * @return {table} - Pie menu component for HUD.
 */
function mkPieMenu(menuCfg, selIdx, params = defaultPieMenuParams) {
  let { pieRadius, piePosOffset, pieIconSizeMul } = params
  let pieSize = [pieRadius * 2, pieRadius * 2]
  let degPerItem = Computed(@() 360.0 / (menuCfg.get().len() || 1))

  let pieBg = {
    size = pieSize
    rendObj = ROBJ_MASK
    image = Picture($"ui/gameuiskin/pie_menu_bg.svg:{pieSize[0]}:{pieSize[1]}:P")
    color = 0xFF000000
    children = [
      {
        size = pieSize
        rendObj = ROBJ_SOLID
        color = 0xFF000000
      }
      @() selIdx.get() < 0 ? { watch = selIdx } : {
        watch = [selIdx, degPerItem]
        size = pieSize
        rendObj = ROBJ_VECTOR_CANVAS
        color = 0xFFFFFFFF
        commands = [[VECTOR_SECTOR, 50, 50, 50, 50, -90 - (degPerItem.get() * 0.5), -90 + (degPerItem.get() * 0.5)]]
        transform = {
          pivot = [0.5, 0.5]
          rotate = degPerItem.get() * selIdx.get()
        }
      }
    ]
  }

  let iconsDistance = pieRadius * (1.0 - (textureHoleWidth / 2))
  let iconsComp = @() {
    watch = [menuCfg, degPerItem]
    size = pieSize
    children = menuCfg.get().map(function(c, i) {
      let angleRad = ((degPerItem.get() * i) - 90) * DEG_TO_RAD
      return mkPieMenuItemIcon(c, pieRadius, pieIconSizeMul).__update({
        pos = [iconsDistance * cos(angleRad), iconsDistance * sin(angleRad)]
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
      })
    })
  }

  let selectedItemLabel = @() (menuCfg.get()?[selIdx.get()]?.label ?? "") == ""
    ? { watch = selIdx }
    : {
        watch = [menuCfg, selIdx]
        rendObj = ROBJ_SOLID
        color = 0x80000000
        padding = hdpx(5)
        children = mkPieMenuItemText(menuCfg.get()?[selIdx.get()])
      }

  return {
    size = pieSize
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    pos = piePosOffset
    children = [
      pieBg
      iconsComp
      selectedItemLabel
    ]
  }
}

return {
  mkPieMenu
  getPieMenuSelectedIdx

  defaultPieMenuParams
  mkPieMenuItemIcon
  mkPieMenuItemText
}
