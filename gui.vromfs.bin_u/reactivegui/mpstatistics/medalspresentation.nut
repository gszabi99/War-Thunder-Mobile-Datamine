from "%globalsDarg/darg_library.nut" import *
let { date } = require("datetime")
let { format } = require("string")
let { withTooltip, tooltipDetach } = require("%rGui/tooltip.nut")

let medalSize = hdpx(50)

let defColor = 0xFFFFFFFF
let mkText = @(text, color = defColor) {
  rendObj = ROBJ_TEXT
  text
  color
}.__update(fontTiny)

function mkLbMedalTop10(medal) {
  let stateFlags = Watched(0)
  let key = {}

  return @() {
    size = [medalSize, medalSize]
    watch = stateFlags
    key
    behavior = Behaviors.Button
    transform = { scale = stateFlags.value & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
    onDetach = tooltipDetach(stateFlags)
    onElemState = withTooltip(stateFlags, key, @() {
      content = {
        flow = FLOW_VERTICAL
        sound = { attach = "click" }
        gap = hdpx(10)
        halign = ALIGN_CENTER
        valign =  ALIGN_CENTER
        children = [mkText(loc($"lb/{medal.name}/desc"))].extend(
          medal.list.map(function(v){
            let d = date(v.time)
            let time = format("%04d-%02d-%02d", d.year, d.month + 1, d.day) //ISO 8601
            let desc = loc($"events/name/{v.details.replace(":", "_")}")
            return mkText($"{desc} {time}")
          }))
      }
      flow = FLOW_HORIZONTAL
    })
    children = [
      {
        size = [medalSize, medalSize]
        rendObj = ROBJ_IMAGE
        keepAspect = KEEP_ASPECT_FIT
        image = Picture($"ui/gameuiskin#leaderboard_trophy_01.avif:{medalSize}:{medalSize}:P")
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

function mkUnknownMedal(medal) {
  let stateFlags = Watched(0)
  let key = {}

  return @() {
    watch = stateFlags
    key
    size = [medalSize, medalSize]
    rendObj = ROBJ_IMAGE
    keepAspect = KEEP_ASPECT_FIT
    image = Picture("ui/unitskin#image_in_progress")
    behavior = Behaviors.Button
    transform = { scale = stateFlags.value & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
    onDetach = tooltipDetach(stateFlags)
    onElemState = withTooltip(stateFlags, key, @() {
      content = mkText($"{medal.name}")
      flow = FLOW_HORIZONTAL
    })
  }
}

let medalsPresentation = {
  lb_wp_top_10       = { ctor = mkLbMedalTop10 }
  lb_tanks_top_10    = { ctor = mkLbMedalTop10, campaign = "tanks" }
  lb_ships_top_10    = { ctor = mkLbMedalTop10, campaign = "ships" }
  def                = { ctor = mkUnknownMedal }
}

let getMedalPresentation = @(medal) medalsPresentation?[medal.name] ?? medalsPresentation.def

return {
  getMedalPresentation
}
