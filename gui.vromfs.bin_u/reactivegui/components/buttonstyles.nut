from "%globalsDarg/darg_library.nut" import *

let defButtonHeight = hdpxi(109)
let defButtonMinWidth = hdpxi(368)
let defButtonBorderWidth = hdpx(3)
let defBorderGradient = {
  rendObj = ROBJ_9RECT
  image = Picture($"ui/gameuiskin#gradient_button.svg")
  padding = defButtonBorderWidth
  color = 0xFFEEEEEE
}

return freeze({
  defButtonHeight
  defButtonMinWidth
  defButtonBorderWidth
  defBorderGradient

  PRIMARY = { 
    ovr = {
      size = [SIZE_TO_CONTENT, defButtonHeight]
      minWidth = defButtonMinWidth
    }
    childOvr = fontTinyAccentedShadedBold
    gradientOvr = { color = 0xFF7395CF }
    gradientContainerOvr = { fillColor = 0xFF3A5D91 }
    borderGradientOvr = defBorderGradient
  }
  COMMON = { 
    ovr = {
      size = [SIZE_TO_CONTENT, defButtonHeight]
      minWidth = defButtonMinWidth
    }
    childOvr = fontTinyAccentedShadedBold
    gradientOvr = { color = 0xFF57595B }
    gradientContainerOvr = { fillColor = 0xFF191616 }
    borderGradientOvr = defBorderGradient
  }
  SECONDARY = { 
    ovr = {
      size = [SIZE_TO_CONTENT, defButtonHeight]
      minWidth = defButtonMinWidth
    }
    childOvr = fontTinyAccentedShadedBold
    gradientOvr = { color = 0xFF65C99E }
    gradientContainerOvr = { fillColor = 0xFF32946A }
    borderGradientOvr = defBorderGradient
  }
  INACTIVE = { 
    ovr = {
      size = [SIZE_TO_CONTENT, defButtonHeight]
      minWidth = defButtonMinWidth
      borderColor = 0x80777777
      borderWidth = defButtonBorderWidth
      padding = defButtonBorderWidth
    }
    childOvr = fontTinyAccentedShadedBold.__merge({
      color = 0x80808080
    })
    gradientOvr = { color = 0x80808080 }
    gradientContainerOvr = { fillColor = 0x80000000 }
    borderGradientOvr = { color = null }
  }
  PURCHASE = { 
    ovr = {
      size = [SIZE_TO_CONTENT, defButtonHeight]
      minWidth = defButtonMinWidth
    }
    childOvr = fontTinyAccentedShadedBold
    gradientOvr = { color = 0xFFFFB92D }
    gradientContainerOvr = { fillColor = 0xFFC88704 }
    borderGradientOvr = defBorderGradient
  }
  BATTLE = { 
    ovr = {
      size = [SIZE_TO_CONTENT, defButtonHeight]
      minWidth = defButtonMinWidth
    }
    childOvr = fontTinyAccentedShadedBold
    hasPattern = true
    gradientOvr = { color = 0xFFDC1208 }
    gradientContainerOvr = { fillColor = 0xFF8C1208 }
    borderGradientOvr = defBorderGradient
  }
  HUAWEI = { 
    ovr = {
      size = [SIZE_TO_CONTENT, defButtonHeight]
      minWidth = hdpx(566)
      fillColor = Color(255, 255, 255)
      borderColor = Color(184, 184, 155)
    }
    childOvr = fontTinyAccentedShadedBold.__merge({
      color = Color(0, 0, 0)
      fontFxFactor = 0
    })
  }
})
