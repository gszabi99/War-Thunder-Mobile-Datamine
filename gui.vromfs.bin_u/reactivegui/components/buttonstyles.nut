from "%globalsDarg/darg_library.nut" import *

let defButtonHeight = hdpxi(109)
let defButtonMinWidth = hdpxi(368)

return freeze({
  defButtonHeight
  defButtonMinWidth

  PRIMARY = { // Blue
    ovr = {
      size = [SIZE_TO_CONTENT, defButtonHeight]
      minWidth = defButtonMinWidth
      fillColor = Color(5, 147, 173)
      borderColor = Color(35, 109, 181)
    }
    gradientOvr = {
      color = Color(22, 178, 233)
    }
  }
  PURCHASE = { // Golden
    ovr = {
      size = [SIZE_TO_CONTENT, defButtonHeight]
      minWidth = defButtonMinWidth
      fillColor = Color(170, 114, 5)
      borderColor = Color(179, 181, 35)
    }
    gradientOvr = {
      color = Color(233, 184, 22)
    }
  }
  BATTLE = { // Red
    ovr = {
      size = [SIZE_TO_CONTENT, defButtonHeight]
      minWidth = defButtonMinWidth
      fillColor = Color(140, 18, 8)
      borderColor = Color(159, 71, 43)
    }
    gradientOvr = {
      color = Color(220, 18, 8)
    }
  }
  BRIGHT = { // White
    ovr = {
      size = [SIZE_TO_CONTENT, defButtonHeight]
      minWidth = defButtonMinWidth
      fillColor = Color(216, 216, 216)
      borderColor = Color(184, 184, 155)
    }
    childOvr = {
      color = Color(0, 0, 0)
      fontFxFactor = 0
    }
  }
  HUAWEI = { // Huawei
    ovr = {
      size = [SIZE_TO_CONTENT, defButtonHeight]
      minWidth = hdpx(566)
      fillColor = Color(255, 255, 255)
      borderColor = Color(184, 184, 155)
    }
    childOvr = {
      color = Color(0, 0, 0)
      fontFxFactor = 0
    }
    hasPattern = false
  }
  COMMON = { // Gray
    ovr = {
      size = [SIZE_TO_CONTENT, defButtonHeight]
      minWidth = defButtonMinWidth
      fillColor = Color(100, 100, 100)
      borderColor = Color(74, 74, 74)
    }
    gradientOvr = {
      color = Color(132, 132, 132)
    }
  }
  SECONDARY = { // Green
    ovr = {
      size = [SIZE_TO_CONTENT, defButtonHeight]
      minWidth = defButtonMinWidth
      fillColor = Color(46, 193, 129)
      borderColor = Color(74, 74, 74)
    }
    gradientOvr = {
      color = Color(66, 199, 141)
    }
  }
})
