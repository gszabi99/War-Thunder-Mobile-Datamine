from "%globalsDarg/darg_library.nut" import *
let { format } =  require("string")

let defColor = 0xFFFFFFFF

let mkText = @(text, color = defColor) {
  rendObj = ROBJ_TEXT
  text
  color
}.__update(fontTiny)

let mkRow = @(t1, t2, icon = null) {
  minWidth = SIZE_TO_CONTENT
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = hdpx(10)
  children = [
    mkText(t1)
    icon
    {
      minWidth = hdpx(40)
      size = flex()
    }
    mkText(t2)
  ]
}

function mkStatRow(stats, config, campaign) {
  let configCamp = config?.campaign ?? campaign
  if (configCamp == campaign) {
    let value = config.value(stats)
    return value > 0 ? mkRow(config.name, config?.format(value) ?? value, config?.icon) : null
  }
  return null
}

function secureDiv(a, b) {
  if (b == 0)
    return 0
  return a.tofloat() / b.tofloat()
}

let viewStats = [
  {
    name = loc("lb/battles")
    value = @(stats) stats?.battle_end ?? 0
  }
  {
    name = loc("stats/missions_wins")
    value = @(stats) secureDiv((stats?.profile_stat_win ?? 0) * 100.0, stats?.profile_stat_battle_end ?? 0)
    format = @(v) format("%.0f%%", v)
  }
  {
    name = loc("stats/damage_per_battle")
    campaign = "ships"
    value = @(stats) secureDiv(stats?.profile_stat_damage ?? 0, stats?.profile_stat_battle_end ?? 0)
    format = @(v) format("%.0f", v)
  }
  {
    name = loc("stats/kill_death_ratio")
    campaign = "tanks"
    value = @(stats) secureDiv(stats?.profile_stat_kill ?? 0, stats?.profile_stat_death ?? 0)
    format = @(v) format("%.2f", v)
  }
]

return {
  viewStats
  mkRow
  mkStatRow
}