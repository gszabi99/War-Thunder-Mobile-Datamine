from "%globalsDarg/darg_library.nut" import *

let { eventbus_subscribe } = require("eventbus")
let hudTutorElemsCtors = require("%rGui/tutorial/hudTutorElemsCtors.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { register_command } = require("console")


let hudTutorElemsState = mkWatched(persist, "hudTutorElemsState", {})

eventbus_subscribe("hudElementShow", function(p) {
  let { element = "", show = false } = p
  if (show)
    hudTutorElemsState.mutate(@(v) v[element] <- p)
  else if (element in hudTutorElemsState.get())
    hudTutorElemsState.mutate(@(v) v.$rawdelete(element))
})

isInBattle.subscribe(@(_) hudTutorElemsState.set({}))

register_command(function(id) {
  if (id not in hudTutorElemsState.get())
    hudTutorElemsState.mutate(@(v) v[id] <- {})
  else
    hudTutorElemsState.mutate(@(v) v.$rawdelete(id))
},"debug.hudElements")

let tutorElemsKey = {}
let hudTutorElems = @() {
  watch = hudTutorElemsState
  key = tutorElemsKey
  size = flex()
  children = hudTutorElemsState.get().map(@(p, id) hudTutorElemsCtors?[id](p)).values()
}

return hudTutorElems