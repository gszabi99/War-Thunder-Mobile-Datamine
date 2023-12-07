from "%globalsDarg/darg_library.nut" import *
let { subscribe } = require("eventbus")
let hudTutorElemsCtors = require("%rGui/tutorial/hudTutorElemsCtors.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")


let hudTutorElemsState = mkWatched(persist, "hudTutorElemsState", {})

subscribe("hudElementShow", function(p) {
  let { element = "", show = false } = p
  if (show)
    hudTutorElemsState.mutate(@(v) v[element] <- p)
  else if (element in hudTutorElemsState.value)
    hudTutorElemsState.mutate(@(v) v.$rawdelete(element))
})

isInBattle.subscribe(@(_) hudTutorElemsState({}))

let tutorElemsKey = {}
let hudTutorElems = @() {
  watch = hudTutorElemsState
  key = tutorElemsKey
  size = flex()
  children = hudTutorElemsState.value.map(@(p, id) hudTutorElemsCtors?[id](p)).values()
}

return hudTutorElems
