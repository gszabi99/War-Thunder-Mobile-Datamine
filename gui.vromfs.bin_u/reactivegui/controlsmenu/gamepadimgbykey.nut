from "%globalsDarg/darg_library.nut" import *
let { gamepadPreset } = require("gamepadVendor.nut")
let allPresets = require("gamepadImagePresets.nut")
let { BTN_A, BTN_B, BTN_X, BTN_Y, BTN_DIRPAD, BTN_DIRPAD_DOWN, BTN_DIRPAD_LEFT, BTN_DIRPAD_RIGHT, BTN_DIRPAD_UP,
  BTN_BACK, BTN_START, BTN_LB, BTN_RB, BTN_LT, BTN_RT,
  BTN_LS, BTN_LS_ANY, BTN_LS_UP, BTN_LS_DOWN, BTN_LS_LEFT, BTN_LS_RIGHT, BTN_LS_HOR, BTN_LS_VER,
  BTN_RS, BTN_RS_ANY, BTN_RS_UP, BTN_RS_DOWN, BTN_RS_LEFT, BTN_RS_RIGHT, BTN_RS_HOR, BTN_RS_VER,
  defHeightMul, heightMuls
} = allPresets?[gamepadPreset] ?? allPresets.xone

local dargJKeysToImageId = {
  "J:A"             : BTN_A,
  "J:B"             : BTN_B,
  "J:CROSS"         : BTN_A,
  "J:CIRCLE"        : BTN_B,
  "J:X"             : BTN_X,
  "J:Y"             : BTN_Y,
  "J:SQUARE"        : BTN_X,
  "J:TRIANGLE"      : BTN_Y,

  "J:D.Up"          : BTN_DIRPAD_UP,
  "J:D.Down"        : BTN_DIRPAD_DOWN,
  "J:D.Left"        : BTN_DIRPAD_LEFT,
  "J:D.Right"       : BTN_DIRPAD_RIGHT,

  "J:Start"         : BTN_START,
  "J:Menu"          : BTN_START,
  "J:Back"          : BTN_BACK,
  "J:Select"        : BTN_BACK,
  "J:View"          : BTN_BACK,

  "J:L.Thumb"       : BTN_LS,
  "J:LS"            : BTN_LS,
  "J:L3"            : BTN_LS,
  "J:L3.Centered"   : BTN_LS,
  "J:LS.Centered"   : BTN_LS,
  "J:R.Thumb"       : BTN_RS,
  "J:RS"            : BTN_RS,
  "J:R3"            : BTN_RS,
  "J:R3.Centered"   : BTN_RS,
  "J:RS.Centered"   : BTN_RS,

  "J:L.Shoulder"    : BTN_LB,
  "J:LB"            : BTN_LB,
  "J:L1"            : BTN_LB,
  "J:R.Shoulder"    : BTN_RB,
  "J:RB"            : BTN_RB,
  "J:R1"            : BTN_RB,

  "J:L.Trigger"     : BTN_LT,
  "J:LT"            : BTN_LT,
  "J:L2"            : BTN_LT,
  "J:R.Trigger"     : BTN_RT,
  "J:RT"            : BTN_RT,
  "J:R2"            : BTN_RT,

  "J:L.Thumb.Right" : BTN_LS_RIGHT,
  "J:LS.Right"      : BTN_LS_RIGHT,
  "J:L.Thumb.Left"  : BTN_LS_LEFT,
  "J:LS.Left"       : BTN_LS_LEFT,
  "J:L.Thumb.Up"    : BTN_LS_UP,
  "J:LS.Up"         : BTN_LS_UP,
  "J:L.Thumb.Down"  : BTN_LS_DOWN,
  "J:LS.Down"       : BTN_LS_DOWN,

  "J:R.Thumb.Right" : BTN_RS_RIGHT,
  "J:RS.Right"      : BTN_RS_RIGHT,
  "J:R.Thumb.Left"  : BTN_RS_LEFT,
  "J:RS.Left"       : BTN_RS_LEFT,
  "J:R.Thumb.Up"    : BTN_RS_UP,
  "J:RS.Up"         : BTN_RS_UP,
  "J:R.Thumb.Down"  : BTN_RS_DOWN,
  "J:RS.Down"       : BTN_RS_DOWN,

  "J:L.Thumb.h"     : BTN_LS_HOR,
  "J:L.Thumb.v"     : BTN_LS_VER,
  "J:R.Thumb.h"     : BTN_RS_HOR,
  "J:R.Thumb.v"     : BTN_RS_VER,

  "J:R.Thumb.hv"    : BTN_RS_ANY,
  "J:L.Thumb.hv"    : BTN_LS_ANY,

  //custom aliases
  "dirpad"          : BTN_DIRPAD
}

let btnsNum = [ "D.Up", "D.Down", "D.Left", "D.Right", "Start", "Select", "L3", "R3", "L1", "R1", "0x0400", "0x0800", "CROSS", "CIRCLE", "SQUARE", "TRIANGLE", "L2", "R2", "LS.Right", "LS.Left", "LS.Up", "LS.Down", "RS.Right", "RS.Left", "RS.Up", "RS.Down", "L3.Centered", "R3.Centered"]
let axisNum = ["L.Thumb.h", "L.Thumb.v", "R.Thumb.h", "R.Thumb.v", "L.Trigger", "R.Trigger", "R+L.Trigger", "J:SensorX", "J:SensorZ", "J:SensorY"]

let function keyAndImg(table, list, prefix, offs) {
  foreach (i, k in list) {
    let key = prefix + (i + offs) //for unknow reasons all indexes are incremented
    let img = dargJKeysToImageId?[$"J:{k}"]
    if (img)
      table[key] <- img
  }
}
let basicJBtns = {}
keyAndImg(basicJBtns, btnsNum, "J:Button", 1)
keyAndImg(basicJBtns, axisNum, "J:Axis", 1)
keyAndImg(basicJBtns, btnsNum, "J:B", 0)
keyAndImg(basicJBtns, axisNum, "J:A", 0)

let keysToImageId = dargJKeysToImageId.__merge(basicJBtns)
let getBtnImageHeight = @(imageName, aHeight) ((heightMuls?[imageName] ?? defHeightMul) * aHeight + 0.5).tointeger()

let defHeight = fontTiny.fontSize.tointeger()
let getBtnPicture = @(imgId, hgt) Picture("ui/gameuiskin#{0}.svg:{1}:{1}:P".subst(imgId, hgt))

local function mkBtnImageComp(hotkey, baseHeight = defHeight) {
  let imgId = keysToImageId?[hotkey]
  if (imgId == null)
    return null
  let height = getBtnImageHeight(imgId, baseHeight)
  return {
    size = [height, height]
    rendObj = ROBJ_IMAGE
    image = getBtnPicture(imgId, height)
    keepAspect = true
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
  }
}

return {
  keysToImageId
  mkBtnImageComp
  getBtnImageHeight
  getBtnPicture
}
