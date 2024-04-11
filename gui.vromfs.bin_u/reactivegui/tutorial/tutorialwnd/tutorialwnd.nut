from "%globalsDarg/darg_library.nut" import *
let { setTimeout } = require("dagor.workcycle")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let tutorialWndDefStyle = require("tutorialWndDefStyle.nut")
let { isTutorialActive, tutorialConfigVersion, getTutorialConfig, stepIdx,
  nextStep, nextStepByDefaultHotkey, skipStep, nextKeyAllowed, skipKeyAllowed, getTimeAfterStepStart
} = require("tutorialWndState.nut")
let { getBox, incBoxSize, createHighlight, findGoodPos, findGoodArrowPos, sizePosToBox,
  hasInteractions
} = require("tutorialUtils.nut")

const WND_UID = "tutorial_wnd"
const DEF_SKIP_TIME = 3.0

let mkLightCtorExt = @(lightCtor, nextStepDelay) function(box) {
  let { ctor = null, onClick = null } = box
  if (ctor != null)
    return ctor(box)

  function onClickExt() {
    let skipNext = onClick?() ?? false
    if (!skipNext && (onClick != null || nextStepDelay < getTimeAfterStepStart()))
      nextStep()
  }

  return lightCtor(box, { onClick = onClickExt })
}

function mkBg(boxes, style, nextStepDelay) {
  let { lightCtor, darkCtor } = style
  let lightCtorExt = mkLightCtorExt(lightCtor, nextStepDelay)
  return {
    size = flex()
    children = createHighlight(boxes, lightCtorExt, darkCtor)
  }
}

function mkArrowLinks(stepData, boxes, style) {
  let { arrowLinks = null } = stepData
  if (type(arrowLinks) != "array")
    return null

  let { mkLinkArrow } = style
  let linkBoxes = []
  let linkComps = []
  foreach (link in arrowLinks) {
    if (type(link) != "array" || link.len() != 2) {
      logerr($"Bad arrow link in tutorial: {link}. Expected array with length 2.")
      continue
    }
    let lBoxes = link.map(@(idx) boxes.findvalue(@(b) b?.idx == idx))
    if (lBoxes.findindex(@(b) b == null) != null)
      continue
    let { component = null, box = null } = mkLinkArrow(lBoxes[0], lBoxes[1])
    if (component == null)
      continue
    linkComps.append(component)
    if (box != null)
      linkBoxes.append(box)
  }
  return {
    linkBoxes,
    arrowLinks = {
      size = flex()
      children = linkComps
    }
  }
}

function mkMessage(text, customCtor, boxes, style) {
  if (text == null && customCtor == null)
    return null

  let ctor = customCtor ?? style.messageCtor
  //calc size with next message
  let size = calc_comp_size(ctor(text, Watched(true), nextStepByDefaultHotkey))
  let pos = findGoodPos(size, [sw(50) - 0.5 * size[0], sh(50) - 0.5 * size[1]], boxes)
  return {
    messageComp = {
      pos
      children = ctor(text, nextKeyAllowed, nextStepByDefaultHotkey)
    }
    messageBox = sizePosToBox(size, pos)
  }
}

function mkSkipButton(stepSkipDelay, boxes, style) {
  let skipBtn = style.skipBtnCtor(stepSkipDelay, skipStep, $"skipBtn{stepIdx.value}")
  let size = calc_comp_size(skipBtn)
  local pos = null
  let rightPos = [sw(95) - size[0], sh(5)]
  if (!hasInteractions(sizePosToBox(size, rightPos), boxes))
    pos = rightPos
  else {
    let leftPos = [sw(5), sh(5)]
    if (!hasInteractions(sizePosToBox(size, leftPos), boxes))
      pos = leftPos
  }
  if (pos == null)
    pos = findGoodPos(size, rightPos, boxes)

  return {
    skipBtn = @() {
      watch = skipKeyAllowed
      pos
      children = skipKeyAllowed.value ? skipBtn : null
    }
    skipBox = sizePosToBox(size, pos)
  }
}

local function mkArrows(boxes, obstaclesVar, style) {
  boxes = boxes.filter(@(b) (b?.needArrow ?? false) && b.r - b.l > 0 && b.b - b.t > 0)
  if (boxes.len() == 0)
    return null
  let { pointerArrow } = style
  let size = calc_comp_size(pointerArrow)
  let children = []
  foreach (box in boxes) {
    let { pos, rotate } = findGoodArrowPos(box, size, obstaclesVar)
    obstaclesVar.append(sizePosToBox(size, pos))
    children.append(pointerArrow.__merge({ pos, transform = { rotate } }))
  }
  return {
    size = flex()
    children
  }
}

let nextStepSubscription = @(v) v ? nextStep() : null

let boxUpdateCount = Watched(0)
let boxUpdateCountWithStep = Computed(@() boxUpdateCount.value + stepIdx.value)
function tutorialWnd() {
  let watch = [tutorialConfigVersion, stepIdx, boxUpdateCountWithStep]
  let config = getTutorialConfig()
  let style = tutorialWndDefStyle.__merge(config?.style ?? {})

  let stepData = config?.steps[stepIdx.value] ?? {}
  local { nextStepAfter = null, text = null, textCtor = null } = stepData

  if (text instanceof Watched) {
    watch.append(text)
    text = text.value
  }

  let boxes = []
  local shouldBeBoxes = false
  local hasValidBoxes = false
  foreach (idx, objData in stepData?.objects ?? []) {
    local { keys = null, sizeIncAdd = 0 } = objData
    shouldBeBoxes = shouldBeBoxes || keys != null
    if (keys instanceof Watched) {
      watch.append(keys)
      keys = keys.value
    }
    local box = getBox(keys)
    if (box == null)
      continue
    let isValid = box.r - box.l > 0 && box.b - box.t > 0
    if (isValid)
      box = incBoxSize(box, sizeIncAdd)
    boxes.append(objData.__merge(box, { idx }))
    hasValidBoxes = hasValidBoxes || isValid
  }

  let { linkBoxes = null, arrowLinks = null } = mkArrowLinks(stepData, boxes, style)
  let obstacles = (clone boxes).extend(linkBoxes ?? [])

  let { skipBtn, skipBox } = mkSkipButton(config?.stepSkipDelay ?? DEF_SKIP_TIME, obstacles, style)
  obstacles.append(skipBox)
  let { messageComp = null, messageBox = null } = mkMessage(text, textCtor, obstacles, style)
  if (messageBox != null)
    obstacles.append(messageBox)

  return {
    watch
    size = flex()
    stopMouse = true
    children = [
      mkBg(boxes, style, config?.nextStepDelay ?? 0.5)
      arrowLinks
      messageComp
      skipBtn
      mkArrows(boxes, obstacles, style)
      hasValidBoxes || !shouldBeBoxes ? null //recalc objects if back scene not loaded yet
        : {
            size = SIZE_TO_CONTENT
            key = boxUpdateCountWithStep.value,
            onAttach = @() setTimeout(0.05, @() boxUpdateCount(boxUpdateCount.value + 1))
          }
      nextStepAfter == null ? null
        : {
            size = SIZE_TO_CONTENT
            key = $"nextStepAfter{stepIdx}"
            onAttach = @() nextStepAfter.value ? nextStep()
              : nextStepAfter.subscribe(nextStepSubscription)
            onDetach = @() nextStepAfter.unsubscribe(nextStepSubscription)
          }
    ]
  }
}

let close = @() removeModalWindow(WND_UID)
let open = @() addModalWindow({
  key = WND_UID
  size = [sw(100), sh(100)]
  children = tutorialWnd
  onClick = @() null
})

if (isTutorialActive.value)
  open()
isTutorialActive.subscribe(@(v) v ? open() : close())
