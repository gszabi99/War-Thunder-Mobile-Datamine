let { on_module_unload } = require("modules")

//pseudo-module

// register script respondnets for native code calls
// to add extra checks in script respondents registration (type checks, forbid redefinition
// todo later - check that respondent is needed in native code

let fullList = {}
let root = getroottable()
function registerRespondent(name, func) {
  assert(type(name)=="string")
  assert(type(func)=="function")
  assert(name not in root, @() $"{name} already registerd!")
  root[name] <- func
  fullList[name] <- true
}

on_module_unload(@(_) fullList.each(@(_, key) key in root ? root.$rawdelete(key) : null))

return {
  registerRespondent
}