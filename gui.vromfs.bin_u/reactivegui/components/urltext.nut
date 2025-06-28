from "%globalsDarg/darg_library.nut" import *

let { eventbus_send } = require("eventbus")

function urlLikeButton(text, action, style = {}) {
  let { ovr = {}, childOvr = {} } = style
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    behavior = Behaviors.Button
    rendObj = ROBJ_TEXT
    onElemState = @(v) stateFlags(v)
    sound = {
      click = "click"
    }
    text
    color = Color(192, 192, 192)
    fontFx = FFT_GLOW
    fontFxFactor = 64
    fontFxColor = Color(0, 0, 0)
    onClick = action
    transform = {
      scale = (stateFlags.value & S_ACTIVE) != 0 ? [0.95, 0.95] : [1, 1]
    }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
    children = {
      rendObj = ROBJ_FRAME
      borderWidth = const [0, 0, 2, 0]
      size = flex()
      pos = [0, 2]
      color = Color(192, 192, 192)
    }.__update(childOvr)
  }.__update(fontSmall, ovr)
}

function urlText(text, baseUrl, style = {}, useExternalBrowser = true) {
  return text != "" ? urlLikeButton(text, @() eventbus_send("openUrl", { baseUrl, useExternalBrowser }), style) : null
}

return {
  urlText
  urlLikeButton
}
