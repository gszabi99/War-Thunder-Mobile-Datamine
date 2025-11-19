from "%darg/ui_imports.nut" import *
from "string" import regexp, split_by_chars








let rexInt = regexp(@"[\+\-]?[0-9]+")
function isStringInt(str) {
  return rexInt.match(str) 
}

let rexFloat = regexp(@"(\+|-)?([0-9]+\.?[0-9]*|\.[0-9]+)([eE](\+|-)?[0-9]+)?")
function isStringFloat(str) {
  return rexFloat.match(str) 
}

let rexEng = regexp(@"[a-z,A-Z]*")
function isStringEng(str) {
  return rexEng.match(str)
}
function isStringLikelyEmail(str, _verbose = true) {




  if (type(str) != "string")
    return false
  let splitted = split_by_chars(str, "@")
  if (splitted.len() < 2)
    return false
  local locpart = splitted[0]
  if (splitted.len() > 2)
    locpart = "@".join(splitted.slice(0, -1))
  if (locpart.len() > 64)
    return false
  let dompart = splitted[splitted.len() - 1]
  if (dompart.len() > 253 || dompart.len() < 4) 
    return false
  let quotes = locpart.indexof("\"")
  if (quotes && quotes != 0)
    return false 
  if (quotes == null && locpart.indexof("@") != null)
    return false 
  if (dompart.indexof(".") == null || dompart.indexof(".") > dompart.len() - 3) 
    return false  
  return true
}

function isValidStrByType(str, inputType) {
  if (str == "")
    return true
  if (inputType == "mail")
     return isStringLikelyEmail(str)
  if (inputType == "num")
     return isStringInt(str) || isStringFloat(str)
  if (inputType == "float")
     return isStringFloat(str)
  if (inputType == "lat")
     return isStringEng(str)
  return true
}

let textColor = Color(255, 255, 255)
let placeHolderColor = Color(80, 80, 80, 80)
let backGroundColor = 0xFF000000
let failureColor = Color(255, 60, 70)


let failAnim = @(trigger) {
  prop = AnimProp.color
  from = failureColor
  easing = OutCubic
  duration = 1.0
  trigger = trigger
}

let interactiveValidTypes = ["num", "lat", "integer", "float"]

function textInput(text_state, options = {}) {
  let group = ElemGroup()
  let {
    setValue = @(v) text_state.set(v), inputType = null,
    placeholder = null, showPlaceHolderOnFocus = false, password = null, maxChars = null,
    title = null, hotkeys = null,
    xmbNode = null, imeOpenJoyBtn = null, charMask = null,
    ovr = {}, textStyle = {},
    mkEditContent = null,

    
    onBlur = null, onReturn = null,
    onEscape = @() set_kb_focus(null), onChange = null, onFocus = null, onAttach = null,
    onHover = null, onImeFinish = null
  } = options

  local {
    isValidResult = null, isValidChange = null
  } = options

  isValidResult = isValidResult ?? @(new_value) isValidStrByType(new_value, inputType)
  isValidChange = isValidChange
    ?? @(new_value) interactiveValidTypes.indexof(inputType) == null
      || isValidStrByType(new_value, inputType)

  let stateFlags = Watched(0)
  let errorCount = Watched(0)

  function onBlurExt() {
    if (!isValidResult(text_state.get()))
      anim_start(text_state)
    onBlur?()
  }

  function onReturnExt() {
    if (!isValidResult(text_state.get()))
      anim_start(text_state)
    onReturn?()
  }

  function onEscapeExt() {
    if (!isValidResult(text_state.get()))
      anim_start(text_state)
    onEscape()
  }

  function onChangeExt(new_val) {
    onChange?(new_val)
    if (!isValidChange(new_val)) {
      anim_start(text_state)
      errorCount.set(errorCount.get() + 1)
     } else
      setValue(new_val)
  }

  local placeholderObj = null
  if (placeholder != null) {
    let phBase = {
      text = placeholder
      rendObj = ROBJ_TEXT
      animations = [failAnim(text_state)]
      margin = const [0, sh(0.5)]
    }.__update(textStyle, { color = placeHolderColor })
    placeholderObj = placeholder instanceof Watched
      ? @() phBase.__update({ watch = placeholder, text = placeholder.get() })
      : phBase
  }

  let inputObj = @() {
    
    watch = [text_state, stateFlags, errorCount]
    rendObj = ROBJ_TEXT
    behavior = Behaviors.TextInput

    size = [flex(), fontH(100)]
    color = textColor
    group
    valign = ALIGN_CENTER

    animations = [failAnim(text_state)]

    text = text_state.get()
    title
    inputType = inputType
    password = password
    key = text_state

    maxChars
    hotkeys
    charMask

    onChange = onChangeExt

    onFocus
    onBlur   = onBlurExt
    onAttach
    onReturn = onReturnExt
    onEscape = onEscapeExt
    onHover
    onImeFinish
    xmbNode
    imeOpenJoyBtn

    children = (text_state.get()?.len() ?? 0) == 0
        && (showPlaceHolderOnFocus || !(stateFlags.get() & S_KB_FOCUS))
      ? placeholderObj
      : null
  }.__update(textStyle)

  return @() {
    watch = stateFlags
    size = FLEX_H
    onElemState = @(sf) stateFlags.set(sf)

    rendObj = ROBJ_BOX
    fillColor = backGroundColor
    borderRadius = hdpx(3)
    clipChildren = true
    group
    animations = [failAnim(text_state)]
    valign = ALIGN_CENTER

    children = mkEditContent?(stateFlags.get(), inputObj) ?? inputObj
  }.__update(ovr)
}

return textInput
