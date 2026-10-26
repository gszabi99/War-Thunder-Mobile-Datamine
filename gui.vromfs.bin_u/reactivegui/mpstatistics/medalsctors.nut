from "%globalsDarg/darg_library.nut" import *
from "datetime" import date
from "string" import format
from "%appGlobals/config/medalsPresentation.nut" import getMedalPresentation
from "%rGui/style/stdAnimations.nut" import mkPressTransitionScale
from "%rGui/tooltip.nut" import withTooltip, tooltipDetach


const medalSize = hdpx(50)

const defColor = 0xFFFFFFFF
let mkText = @(text, color = defColor) {
  rendObj = ROBJ_TEXT
  text
  color
}.__update(fontTiny)

let mkLbMedalTop10Ctor = @(presentation) function(medal, mSize = medalSize) {
  let { descLocId, image } = presentation
  let stateFlags = Watched(0)
  let size = [mSize, mSize]
  let txtPos = [mSize * 0.8, mSize * 0.8]
  let detachHandler = tooltipDetach(stateFlags)
  let tooltipHandler = withTooltip(stateFlags, medal, @() {
    flow = FLOW_HORIZONTAL
    content = {
      flow = FLOW_VERTICAL
      sound = { attach = "click" }
      gap = hdpx(10)
      halign = ALIGN_CENTER
      valign =  ALIGN_CENTER
      children = [ mkText(loc(descLocId)) ]
        .extend(
          medal.list.map(function(v){
            let d = date(v.time)
            let time = format("%04d-%02d-%02d", d.year, d.month + 1, d.day) 
            let desc = loc($"events/name/{v.details.replace(":", "_")}")
            return mkText($"{desc} {time}")
          }))
    }
  })
  let medalChildren = [
    {
      size
      rendObj = ROBJ_IMAGE
      keepAspect = KEEP_ASPECT_FIT
      image = Picture($"ui/gameuiskin#{image}:{mSize}:{mSize}:P")
    }
    medal.list.len() <= 1 ? null
      : {
          rendObj = ROBJ_TEXT
          text = medal.list.len()
          halign = ALIGN_CENTER
          pos = txtPos
          ...fontVeryTinyAccented
        }
  ]
  return @() {
    size
    watch = stateFlags
    key = medal
    behavior = Behaviors.Button
    onDetach = detachHandler
    onElemState = tooltipHandler
    children = medalChildren
    ...mkPressTransitionScale(stateFlags.get(), 0.9)
  }
}

let mkSimpleMedalCtor = @(presentation) function(medal, mSize = medalSize) {
  let { descLocId, image } = presentation
  let stateFlags = Watched(0)
  let size = [mSize, mSize]
  let img = image == null ? Picture("ui/unitskin#image_in_progress")
    : Picture($"ui/gameuiskin#{image}:{mSize}:{mSize}:P")
  let detachHandler = tooltipDetach(stateFlags)
  let tooltipHandler = withTooltip(stateFlags, medal,
    @() {
      flow = FLOW_HORIZONTAL
      content = {
        flow = FLOW_VERTICAL
        sound = { attach = "click" }
        gap = hdpx(10)
        halign = ALIGN_CENTER
        valign =  ALIGN_CENTER
        children = [ mkText(loc(descLocId)) ]
          .extend(medal.list.map(function(v){
            let d = date(v.time)
            return mkText(format("%04d-%02d-%02d", d.year, d.month + 1, d.day))
          }))
      }
    })
  return @() {
    watch = stateFlags
    key = medal
    size
    rendObj = ROBJ_IMAGE
    keepAspect = KEEP_ASPECT_FIT
    image = img
    behavior = Behaviors.Button
    onDetach = detachHandler
    onElemState = tooltipHandler
    ...mkPressTransitionScale(stateFlags.get(), 0.9)
  }
}

let medalCtors = {
  lbTop10 = mkLbMedalTop10Ctor
}

let presentations = {}
function getMedalPresentationWithCtor(name) {
  if (name not in presentations) {
    let p = getMedalPresentation(name)
    let { ctor = null, campaign = null } = p
    presentations[name] <- { ctor = (medalCtors?[ctor] ?? mkSimpleMedalCtor)(p) }
    if (campaign != null)
      presentations[name].campaign <- campaign
  }
  return presentations[name]
}

return {
  getMedalPresentationWithCtor
}
