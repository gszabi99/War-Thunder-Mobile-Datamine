


from "math" import PI

let math = require("math.nut").__merge(require("math"),require("dagor.math"))

function degToRad(angle){
  return angle*PI/180.0
}

function radToDeg(angle){
  return angle*180.0/PI
}
mark_pure(radToDeg)
mark_pure(degToRad)

return freeze(math.__merge({
  degToRad
  radToDeg
}))
