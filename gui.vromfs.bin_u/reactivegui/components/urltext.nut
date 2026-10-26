from "%globalsDarg/darg_library.nut" import *
from "%rGui/style/stdAnimations.nut" import mkPressTransitionScale
from "eventbus" import eventbus_send


function urlLikeButton(text, action, style = {}) {
  let { ovr = {}, childOvr = {} } = style
  let stateFlags = Watched(0)
  let underline = {
    rendObj = ROBJ_FRAME
    borderWidth = const [0, 0, 2, 0]
    size = FLEX
    pos = const [0, 2]
    color = Color(192, 192, 192)
    ...childOvr
  }
  return @() {
    watch = stateFlags
    behavior = Behaviors.Button
    rendObj = ROBJ_TEXT
    onElemState = @(v) stateFlags.set(v)
    sound = const {
      click = "click"
    }
    text
    color = Color(192, 192, 192)
    onClick = action
    children = underline
    ...mkPressTransitionScale(stateFlags.get())
    ...fontSmallShaded
    ...ovr
  }
}

function urlText(text, baseUrl, style = {}, useExternalBrowser = true) {
  return text != "" ? urlLikeButton(text, @() eventbus_send("openUrl", { baseUrl, useExternalBrowser }), style) : null
}

return {
  urlText
  urlLikeButton
}
