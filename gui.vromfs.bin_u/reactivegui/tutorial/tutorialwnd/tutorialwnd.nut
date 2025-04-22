from "%globalsDarg/darg_library.nut" import *
let { setInterval, clearTimer, deferOnce } = require("dagor.workcycle")
let { addModalWindow, removeModalWindow, MWP_ALWAYS_TOP } = require("%rGui/components/modalWindows.nut")
let tutorialWndDefStyle = require("tutorialWndDefStyle.nut")
let { isTutorialActive, tutorialConfigVersion, getTutorialConfig, stepIdx, WND_UID,
  nextStep, nextStepByDefaultHotkey, skipStep, nextKeyAllowed, skipKeyAllowed, getTimeAfterStepStart
} = require("tutorialWndState.nut")
let { getBox, incBoxSize, createHighlight, findGoodPos, findGoodArrowPos, sizePosToBox,
  hasInteractions, getNotInterractPos, findGoodPosX
} = require("tutorialUtils.nut")

const DEF_SKIP_TIME = 3.0
let charBestPosOffsetX = hdpxi(330)

let boxUpdateCount = Watched(0)
let boxUpdateCountWithStep = Computed(@() boxUpdateCount.value + stepIdx.value)


let mkLightCtorExt = @(lightCtor, nextStepDelay) function(box) {
  let { ctor = null, onClick = null, hotkeys = null } = box
  if (ctor != null)
    return ctor(box)

  function onClickExt() {
    let skipNext = onClick?() ?? false
    if (!skipNext && (onClick != null || nextStepDelay < getTimeAfterStepStart()))
      nextStep()
  }

  return lightCtor(box, { onClick = onClickExt, hotkeys = hotkeys })
}

function mkBg(boxes, style, nextStepDelay) {
  let { lightCtor, darkCtor } = style
  let lightCtorExt = mkLightCtorExt(lightCtor, nextStepDelay)
  return {
    size = flex()
    children = createHighlight(boxes, lightCtorExt, darkCtor)
  }
}

let bgContinueButton = @() !nextKeyAllowed.get() ? { watch = nextKeyAllowed }
  : {
      watch = nextKeyAllowed
      size = flex()
      behavior = Behaviors.Button
      onClick = nextStepByDefaultHotkey
      sound = { click  = "click" }
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

function mkMessage(text, charId, customCtor, boxes, style) {
  if (text == null && customCtor == null)
    return null

  let ctor = customCtor ?? style.messageCtor
  let character = style.characterCtor(charId, false)
  
  let charSize = calc_comp_size(character)
  let msgSize = calc_comp_size(ctor(text, Watched(false), nextStepByDefaultHotkey))

  let charPosY = sh(100) - charSize[1]
  let bestCharPos = [max(saBorders[0], sw(50) - charSize[0] - charBestPosOffsetX), charPosY]
  let charPos = getNotInterractPos(charSize,
      [
        bestCharPos,
        [min(sw(100) - saBorders[0] - charSize[0], sw(50) + charBestPosOffsetX), charPosY],
        [saBorders[0], charPosY],
        [sw(100) - saBorders[0] - charSize[0], charPosY],
      ],
      boxes)
    ?? findGoodPosX(charSize, bestCharPos, boxes)

  let bestMsgPos = [
    clamp(charPos[0] + (charSize[0] - msgSize[0]) / 2, saBorders[0], sw(100) - saBorders[0]),
    sh(100) - msgSize[1] - saBorders[1]
  ]
  local msgPos = bestMsgPos
  if (hasInteractions(sizePosToBox(msgSize, msgPos), boxes)) {
    msgPos = findGoodPosX(msgSize, msgPos, boxes) 
    if (hasInteractions(sizePosToBox(msgSize, msgPos), boxes)) {
      let boxesWithChar = (clone boxes).append(sizePosToBox(charSize, charPos))
      msgPos = findGoodPos(msgSize,
        [ charPos[0] < sw(50) ? charPos[0] + charSize[0] : charPos[0] - msgSize[0], bestMsgPos[1] ],
        boxesWithChar)
      if (hasInteractions(sizePosToBox(msgSize, msgPos), boxesWithChar))
        msgPos = bestMsgPos 
    }
  }

  return {
    messageComp = {
      pos = msgPos
      children = ctor(text, nextKeyAllowed, nextStepByDefaultHotkey)
    }
    messageBox = sizePosToBox(msgSize, msgPos)
    characterComp = {
      pos = charPos
      children = charPos[0] < sw(50) ? character : style.characterCtor(charId, true)
    }
  }
}

function mkSkipButton(stepSkipDelay, boxes, style) {
  let skipBtn = style.skipBtnCtor(stepSkipDelay, skipStep, $"skipBtn{stepIdx.get()}")
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
      key = $"skipBtnContainer{stepIdx.get()}"
      pos
      children = skipKeyAllowed.get() ? skipBtn : null
    }
    skipBox = sizePosToBox(size, pos)
  }
}

function mkArrows(boxes, obstaclesVar, style) {
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

let nextStepSubscription = @(v) v ? deferOnce(nextStep) : null
let isBoxValid = @(box) box.r - box.l > 0 && box.b - box.t > 0

function checkValidBoxes() {
  let { objects = [] } = getTutorialConfig()?.steps[stepIdx.value]
  foreach (objData in objects) {
    local { keys = null } = objData
    if (keys instanceof Watched)
      keys = keys.get()
    local box = getBox(keys)
    if (box != null && isBoxValid(box)) {
      boxUpdateCount.set(boxUpdateCount.get() + 1)
      return
    }
  }
}

function tutorialWnd() {
  let watch = [tutorialConfigVersion, stepIdx, boxUpdateCountWithStep]
  let config = getTutorialConfig()
  let style = tutorialWndDefStyle.__merge(config?.style ?? {})

  let stepData = config?.steps[stepIdx.value] ?? {}
  local { nextStepAfter = null, text = null, textCtor = null, charId = null } = stepData

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
    let isValid = isBoxValid(box)
    if (isValid)
      box = incBoxSize(box, sizeIncAdd)
    boxes.append(objData.__merge(box, { idx }))
    hasValidBoxes = hasValidBoxes || isValid
  }

  let { linkBoxes = null, arrowLinks = null } = mkArrowLinks(stepData, boxes, style)
  let obstacles = (clone boxes).extend(linkBoxes ?? [])

  let { skipBtn, skipBox } = mkSkipButton(config?.stepSkipDelay ?? DEF_SKIP_TIME, obstacles, style)
  obstacles.append(skipBox)
  let { characterComp = null, messageComp = null, messageBox = null } = mkMessage(text, charId, textCtor, obstacles, style)
  if (messageBox != null)
    obstacles.append(messageBox)

  return {
    watch
    size = flex()
    stopMouse = true
    children = [
      bgContinueButton
      mkBg(boxes, style, config?.nextStepDelay ?? 0.5)
      arrowLinks
      characterComp
      messageComp
      skipBtn
      mkArrows(boxes, obstacles, style)
      hasValidBoxes || !shouldBeBoxes ? null 
        : {
            size = SIZE_TO_CONTENT
            key = checkValidBoxes
            onAttach = @() setInterval(0.05, checkValidBoxes)
            onDetach = @() clearTimer(checkValidBoxes)
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
  priority = MWP_ALWAYS_TOP
  size = [sw(100), sh(100)]
  children = tutorialWnd
  onClick = @() null
})

if (isTutorialActive.value)
  open()
isTutorialActive.subscribe(@(v) v ? open() : close())
