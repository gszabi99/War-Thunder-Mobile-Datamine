from "%globalsDarg/darg_library.nut" import *
let { hasAddons } = require("%appGlobals/updater/addonsState.nut")
let { mkGradientBlock } = require("%rGui/hudHints/hintCtors.nut")
let { resetTimeout, clearTimer } = require("dagor.workcycle")

let textSize = calc_str_box(loc("updater/lqTexturesWarning"), fontSmall)
let bgColor = 0x80000000
let DELAY = 1.5
let BLINK = 0.5
let SHOW = 2.0
let HIDE = 5.5

let notUploadedHqTextures = Computed(@() hasAddons.get()?.pkg_secondary_hq == false)
let showWarningInHangar = Watched(false)
let showWarningInBattle = Watched(false)
let wasShownInHangar = mkWatched(persist, "wasShownInHangar", false)
let wasShownInBattle = mkWatched(persist, "wasShownInBattle", false)

let blinkAnimation = [
  {
    prop = AnimProp.opacity, from = 1.0, to = 0.3,
    delay = DELAY, duration = BLINK, play = true, easing = InOutCubic
  }
  {
    prop = AnimProp.opacity, from = 1.0, to = 0.3,
    delay = DELAY + BLINK, duration = BLINK, play = true, easing = InOutCubic
  }
]

function lqTexturesWarning(wasShown, showWarning) {
  function hideWarning() {
    showWarning(false)
    wasShown(true)
  }
  let updateShowWarning = @() showWarning(notUploadedHqTextures.value)

  return {
    watch = [showWarning, wasShown]
    hplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    pos = [0, sh(15)]
    children = !showWarning.value || wasShown.value ? null
      : mkGradientBlock(
        bgColor
        {
          rendObj = ROBJ_TEXT
          text = loc("updater/lqTexturesWarning")
          fontFxColor = 0xFF000000
          fontFxFactor = 50
          fontFx = FFT_GLOW
        }.__update(fontSmall)
        textSize[0] * 1.3
      ).__update({ animations = blinkAnimation })
    function onAttach() {
      resetTimeout(SHOW, updateShowWarning)
      resetTimeout(HIDE, hideWarning)
    }
    function onDetach() {
      clearTimer(updateShowWarning)
      clearTimer(hideWarning)
    }
  }
}

let lqTexturesWarningHangar = @() lqTexturesWarning(wasShownInHangar, showWarningInHangar)
let lqTexturesWarningBattle = @() lqTexturesWarning(wasShownInBattle, showWarningInBattle)

return {
  lqTexturesWarningHangar
  lqTexturesWarningBattle
}
