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
  size = FLEX_H
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

let mkMarqueeText = @(text)
  mkText(text).__update({ behavior = Behaviors.Marquee })

let mkMarqueeRow = @(t1, t2, icon = null) {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = hdpx(10)
  children = [
    mkMarqueeText(t1).__update({ maxWidth = pw(70) })
    icon
    {
      size = flex()
      halign = ALIGN_RIGHT
      children = mkText(t2)
    }
  ]
}

function mkStatRow(stats, config, campaign, ctor = null) {
  let configCamp = config?.campaign ?? campaign
  if (configCamp == campaign) {
    let value = config.value(stats)
    return value > 0
      ? ctor != null
        ? ctor(config.name, config?.format(value) ?? value, config?.icon)
        : mkRow(config.name, config?.format(value) ?? value, config?.icon)
      : null
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
    value = @(stats) max(stats?.battles ?? 0,
      stats?.profile_stat_battle_end ?? 0,
      stats?.battle_end ?? 0)
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
  mkMarqueeRow
  mkMarqueeText
  mkStatRow
}
