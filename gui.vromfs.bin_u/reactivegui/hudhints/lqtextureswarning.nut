from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout, clearTimer
from "%appGlobals/updater/addonsState.nut" import hasAddons
from "%rGui/hudHints/hintCtors.nut" import mkGradientBlock


let textSize = calc_str_box(loc("updater/lqTexturesWarning"), fontSmall)
const bgColor = 0x80000000
const DELAY = 1.5
const BLINK = 0.5
const SHOW = 2.0
const HIDE = 5.5

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
    showWarning.set(false)
    wasShown.set(true)
  }
  let updateShowWarning = @() showWarning.set(notUploadedHqTextures.get())

  return {
    watch = [showWarning, wasShown]
    hplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    pos = const [0, sh(15)]
    children = !showWarning.get() || wasShown.get() ? null
      : mkGradientBlock(
        bgColor
        {
          rendObj = ROBJ_TEXT
          text = loc("updater/lqTexturesWarning")
        }.__update(fontSmallShaded)
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
