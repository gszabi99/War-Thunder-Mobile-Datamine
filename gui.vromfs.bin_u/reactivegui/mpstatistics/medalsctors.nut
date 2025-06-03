from "%globalsDarg/darg_library.nut" import *
let { date } = require("datetime")
let { format } = require("string")
let { getMedalPresentation } = require("%appGlobals/config/medalsPresentation.nut")
let { withTooltip, tooltipDetach } = require("%rGui/tooltip.nut")

let medalSize = hdpx(50)

let defColor = 0xFFFFFFFF
let mkText = @(text, color = defColor) {
  rendObj = ROBJ_TEXT
  text
  color
}.__update(fontTiny)

let mkLbMedalTop10Ctor = @(presentation) function(medal) {
  let { descLocId, image } = presentation
  let stateFlags = Watched(0)
  return @() {
    size = [medalSize, medalSize]
    watch = stateFlags
    key = medal
    behavior = Behaviors.Button
    transform = { scale = stateFlags.value & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
    onDetach = tooltipDetach(stateFlags)
    onElemState = withTooltip(stateFlags, medal, @() {
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
    children = [
      {
        size = [medalSize, medalSize]
        rendObj = ROBJ_IMAGE
        keepAspect = KEEP_ASPECT_FIT
        image = Picture($"ui/gameuiskin#{image}:{medalSize}:{medalSize}:P")
      }
      medal.list.len() <= 1 ? null
        : {
            rendObj = ROBJ_TEXT
            text = medal.list.len()
            halign = ALIGN_CENTER
            pos = [medalSize * 0.8, medalSize * 0.8]
          }.__update(fontVeryTinyAccented)
    ]
  }
}

let mkSimpleMedalCtor = @(presentation) function(medal) {
  let { descLocId, image } = presentation
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    key = medal
    size = [medalSize, medalSize]
    rendObj = ROBJ_IMAGE
    keepAspect = KEEP_ASPECT_FIT
    image = image == null ? Picture("ui/unitskin#image_in_progress")
      : Picture($"ui/gameuiskin#{image}:{medalSize}:{medalSize}:P")
    behavior = Behaviors.Button
    transform = { scale = stateFlags.value & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
    onDetach = tooltipDetach(stateFlags)
    onElemState = withTooltip(stateFlags, medal,
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
