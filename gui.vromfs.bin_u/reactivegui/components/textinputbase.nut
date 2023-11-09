from "%darg/ui_imports.nut" import *
from "string" import regexp, split_by_chars

/*
  todo:
    - somehow provide result of validation - maybe more complex type of inputState, like Watched({text=text isValid=true}))
    - important to know about language and CapsLock. The easiest way - show last symbol in password for 0.25 seconds before hide it with *

    - replace editor in enlisted with this component (it should be already suitable)
*/
let rexInt = regexp(@"[\+\-]?[0-9]+")
let function isStringInt(str) {
  return rexInt.match(str) //better use one from string.nut
}

let rexFloat = regexp(@"(\+|-)?([0-9]+\.?[0-9]*|\.[0-9]+)([eE](\+|-)?[0-9]+)?")
let function isStringFloat(str) {
  return rexFloat.match(str) //better use one from string.nut
}

let rexEng = regexp(@"[a-z,A-Z]*")
let function isStringEng(str) {
  return rexEng.match(str)
}
let function isStringLikelyEmail(str, _verbose = true) {
// this check is not rfc fully compatible. We check that @ exist and correctly used, and that let and domain parts exist and they are correct length.
// Domain part also have at least one period and main domain at least 2 symbols
// also come correct emails on google are against RFC, for example a.a.a@gmail.com.

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
  if (dompart.len() > 253 || dompart.len() < 4) //RFC + domain should be at least x.xx
    return false
  let quotes = locpart.indexof("\"")
  if (quotes && quotes != 0)
    return false //quotes only at the begining
  if (quotes == null && locpart.indexof("@") != null)
    return false //no @ without quotes
  if (dompart.indexof(".") == null || dompart.indexof(".") > dompart.len() - 3) // warning disable: -func-can-return-null -potentially-nulled-ops
    return false  //too short first level domain or no periods
  return true
}

let function isValidStrByType(str, inputType) {
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

let function textInput(text_state, options = {}) {
  let group = ElemGroup()
  let {
    setValue = @(v) text_state(v), inputType = null,
    placeholder = null, showPlaceHolderOnFocus = false, password = null, maxChars = null,
    title = null, hotkeys = null,
    xmbNode = null, imeOpenJoyBtn = null, charMask = null,
    ovr = {}, textStyle = {},
    mkEditContent = null,

    //handlers
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

  let function onBlurExt() {
    if (!isValidResult(text_state.value))
      anim_start(text_state)
    onBlur?()
  }

  let function onReturnExt() {
    if (!isValidResult(text_state.value))
      anim_start(text_state)
    onReturn?()
  }

  let function onEscapeExt() {
    if (!isValidResult(text_state.value))
      anim_start(text_state)
    onEscape()
  }

  let function onChangeExt(new_val) {
    onChange?(new_val)
    if (!isValidChange(new_val))
      anim_start(text_state)
    else
      setValue(new_val)
  }

  local placeholderObj = null
  if (placeholder != null) {
    let phBase = {
      text = placeholder
      rendObj = ROBJ_TEXT
      animations = [failAnim(text_state)]
      margin = [0, sh(0.5)]
    }.__update(textStyle, { color = placeHolderColor })
    placeholderObj = placeholder instanceof Watched
      ? @() phBase.__update({ watch = placeholder, text = placeholder.value })
      : phBase
  }

  let inputObj = @() {
    watch = [text_state, stateFlags]
    rendObj = ROBJ_TEXT
    behavior = [Behaviors.TextInput, Behaviors.Button]

    size = [flex(), fontH(100)]
    color = textColor
    group
    valign = ALIGN_CENTER

    animations = [failAnim(text_state)]

    text = text_state.value
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

    children = (text_state.value?.len() ?? 0) == 0
        && (showPlaceHolderOnFocus || !(stateFlags.value & S_KB_FOCUS))
      ? placeholderObj
      : null
  }.__update(textStyle)

  return @() {
    watch = stateFlags
    size = [flex(), SIZE_TO_CONTENT]
    onElemState = @(sf) stateFlags(sf)

    rendObj = ROBJ_BOX
    fillColor = backGroundColor
    borderRadius = hdpx(3)
    clipChildren = true
    group
    animations = [failAnim(text_state)]
    valign = ALIGN_CENTER

    children = mkEditContent?(stateFlags.value, inputObj) ?? inputObj
  }.__update(ovr)
}

return textInput
