from "%globalsDarg/darg_library.nut" import *
from "%rGui/controls/shortcutsMap.nut" import gamepadShortcuts
import "%rGui/controlsMenu/gamepadImagePresets.nut" as gamepadImagePresets
from "%rGui/controlsMenu/gamepadVendor.nut" import gamepadPreset
from "types" import String


const blockWidth = hdpx(480)
const textWidth = hdpx(450)
let bgSize = [840, 452]
const bgFinalHeight = hdpx(500)
let bgFinalWidth = (bgFinalHeight * bgSize[0] / bgSize[1]).tointeger()
const borderOffs = 25 
let iconSize = fontSmall.fontSize.tointeger()
let textWithIconWidth = textWidth - iconSize

let mkSizeByParent = @(size) [pw(100.0 * size[0] / bgSize[0]), ph(100.0 * size[1] / bgSize[1])]
let mkLines = @(lines) lines.map(@(v, i) 100.0 * v / bgSize[i % 2])
let keyWithCombination = @(v) $"{gamepadShortcuts["ID_COMBINATION"]} {v}"

function mergeWithDefaults(cfg) {
  let keys = []
  if (cfg.key instanceof String)
    keys.append(cfg.key, keyWithCombination(cfg.key))
  else
    keys.extend(cfg.key, cfg.key.map(keyWithCombination))
  cfg.key = keys

  if (cfg?.axisKey)
    cfg.axisKey.extend(cfg.axisKey.map(keyWithCombination))

  cfg.blockOvr <- {}.__merge({ size = const [blockWidth, SIZE_TO_CONTENT] }, cfg?.blockOvr ?? {})

  return cfg
}

let mkControlDescBtn = @(text, maxWidth = textWidth) {
  maxWidth
  rendObj = ROBJ_TEXT
  behavior = Behaviors.Marquee
  color = 0xFFFFFFFF
  text
}.__update(fontTiny)

let mkGamepadIcon = @(id) {
    size = FLEX_V
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = {
      size = [iconSize, iconSize]
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#{id}.svg:{iconSize}:{iconSize}:P")
      keepAspect = true
    }
  }

let mkTwoRowBlock = @(text, isLeft) {
  flow = FLOW_VERTICAL
  gap = hdpx(10)
  children = [
    {
      flow = FLOW_HORIZONTAL
      gap = hdpx(10)
      children = [
        mkGamepadIcon(gamepadImagePresets[gamepadPreset][$"BTN_{isLeft ? "L" : "R"}S_ANY"])
        mkControlDescBtn(text.axis, textWithIconWidth)
      ]
    }
    {
      flow = FLOW_HORIZONTAL
      gap = hdpx(10)
      children = [
        mkGamepadIcon(gamepadImagePresets[gamepadPreset][$"BTN_{isLeft ? "L" : "R"}S"])
        mkControlDescBtn(text.sc, textWithIconWidth)
      ]
    }
  ]
}.__update(fontTiny)

function getHintText(hint, texts) {
  if (hint.key instanceof String)
    return { sc = texts?[hint.key] }
  let list = []
  foreach (k in hint.key) {
    let t = texts?[k] ?? ""
    if (t != "" && !list.contains(t))
      list.append(t)
  }
  let txt = { sc = ", ".join(list) }
  if (hint?.axisKey) {
    let axisList = []
    foreach (k in hint.axisKey) {
      let t = texts?[k] ?? ""
      if (t != "" && !axisList.contains(t))
        axisList.append(t)
    }
    txt.axis <- ", ".join(axisList)
  }
  return txt
}

let mkHintsContent = @(hints, texts)
  hints.map(function(hint) {
    let text = getHintText(hint, texts)
    let {sc = "", axis = ""} = text
    if (sc == "" && axis == "")
      return null
    return hint.__merge({ content = sc != "" && axis != "" ? mkTwoRowBlock(text, hint?.isLeftAxis ?? false)
      : sc != "" ? mkControlDescBtn(sc)
      : mkControlDescBtn(axis)})
  })
  .filter(@(h) h != null)


return {
  mkControlDescBtn
  mkTwoRowBlock
  mkSizeByParent
  mkLines
  getHintText
  mergeWithDefaults
  mkHintsContent

  bgFinalHeight
  bgFinalWidth
  borderOffs
  blockWidth
  textWidth
}