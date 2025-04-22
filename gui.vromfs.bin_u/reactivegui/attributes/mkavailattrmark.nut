from "%globalsDarg/darg_library.nut" import *
let { hoverColor } = require("%rGui/style/stdColors.nut")

let mkBgAnim = @(duration, colorFrom, colorTo) [
  { prop = AnimProp.fillColor, from = colorFrom, to = colorTo, duration,
    play = true, loop = true, easing = CosineFull }
]

let mkIconAnim = @(duration, scale = 1.2) [
  { prop = AnimProp.scale, from = [scale, scale], to = [1.0, 1.0], duration,
    play = true, loop = true, easing = CosineFull }
]

let defCfg = {
  bgColor = 0x60000000
  bgAnim = null
  icon = "ui/gameuiskin#button_notify_marker.svg"
  iconColor = 0xFFFFFFFF
  iconAnim = null
}

let cfgByStatus = [
  {}
  {
    bgColor = 0xBF08A7BF  
  }
  {
    bgColor = 0xBF08A7BF  
    bgAnim = mkBgAnim(3.0, 0xFF0BDFFF, 0xA50790A5) 
    iconAnim = mkIconAnim(3.0)
  }
  {
    bgColor = 0xBFBF8908  
    bgAnim = mkBgAnim(1.0, 0xFFFFB70B, 0xA5A57607) 
    iconAnim = mkIconAnim(1.0)
  }
].map(@(v) defCfg.__merge(v))

function mkAvailAttrMark(status, size = hdpx(60), sf = 0) {
  let cfg = cfgByStatus?[status]
  if (cfg == null)
    return null

  let { bgColor, bgAnim, icon, iconColor, iconAnim } = cfg
  let icoSize = (0.4 * size).tointeger()
  let bgSize = 0.71 * size
  return {
    size  = [size, size] 
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER

    children = [
      {
        key = cfg
        size = [bgSize, bgSize]
        rendObj = ROBJ_BOX
        borderWidth = hdpx(2)
        fillColor = bgColor
        borderColor = sf & S_HOVER ? hoverColor : 0xFFA0A0A0
        transform = { rotate = 45 }
        animations = bgAnim
      }
      {
        key = cfg
        size = [icoSize, icoSize]
        rendObj = ROBJ_IMAGE
        image = Picture($"{icon}:{icoSize}:{icoSize}:K")
        color = iconColor
        transform = {}
        animations = iconAnim
      }
    ]
  }
}

return mkAvailAttrMark
