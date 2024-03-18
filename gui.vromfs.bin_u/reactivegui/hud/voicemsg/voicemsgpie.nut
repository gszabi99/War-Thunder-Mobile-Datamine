from "%globalsDarg/darg_library.nut" import *
let { sin, cos, PI } = require("math")
let { voiceMsgCfg, isVoiceMsgEnabled, isVoiceMsgStickActive, voiceMsgSelectedIdx
} = require("%rGui/hud/voiceMsg/voiceMsgState.nut")

let DEG_TO_RAD = PI / 180.0
let degPerItem = 360.0 / voiceMsgCfg.len()

let pieRadius = shHud(28)
let pieSize = [pieRadius * 2, pieRadius * 2]
let ringWidth = 0.54
let defaultIconSize = (pieRadius * 0.24 + 0.5).tointeger()

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
    @() voiceMsgSelectedIdx.get() < 0 ? { watch = voiceMsgSelectedIdx } : {
      watch = voiceMsgSelectedIdx
      size = pieSize
      rendObj = ROBJ_VECTOR_CANVAS
      color = 0xFFFFFFFF
      commands = [[VECTOR_SECTOR, 50, 50, 50, 50, -90 - (degPerItem * 0.5), -90 + (degPerItem * 0.5)]]
      transform = {
        pivot = [0.5, 0.5]
        rotate = degPerItem * voiceMsgSelectedIdx.get()
      }
    }
  ]
}

let iconsDistance = pieRadius * (1.0 - (ringWidth / 2))
let iconsComp = {
  size = pieSize
  children = voiceMsgCfg.map(function(c, i) {
    let { icon, iconScale } = c
    let iconSize = (defaultIconSize * iconScale + 0.5).tointeger()
    let angleRad = ((degPerItem * i) - 90) * DEG_TO_RAD
    return {
      size = [iconSize, iconSize]
      pos = [iconsDistance * cos(angleRad), iconsDistance * sin(angleRad)]
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#{icon}:{iconSize}:{iconSize}:P")
      keepAspect = true
      color = 0xFFFFFFFF
    }
  })
}

let selectedItemLabel = @() voiceMsgSelectedIdx.get() < 0 ? { watch = voiceMsgSelectedIdx } : {
  watch = voiceMsgSelectedIdx
  rendObj = ROBJ_SOLID
  color = 0x80000000
  padding = hdpx(5)
  children = {
    rendObj = ROBJ_TEXT
    text = voiceMsgCfg?[voiceMsgSelectedIdx.get()].label
  }.__update(fontSmall)
}

let voiceMsgPieBase = {
  size = pieSize
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  pos = [0, shHud(-6)]
  children = [
    pieBg
    iconsComp
    selectedItemLabel
  ]
}

function voiceMsgPie() {
  let res = { watch = [isVoiceMsgEnabled, isVoiceMsgStickActive] }
  return isVoiceMsgEnabled.get() && isVoiceMsgStickActive.get()
    ? res.__update(voiceMsgPieBase)
    : res
}

return voiceMsgPie
