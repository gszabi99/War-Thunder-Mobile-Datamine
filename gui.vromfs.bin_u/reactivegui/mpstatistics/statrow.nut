from "%globalsDarg/darg_library.nut" import *
let { format } =  require("string")
let { infoTooltipButton } = require("%rGui/components/infoButton.nut")
let { withTooltip, tooltipDetach } = require("%rGui/tooltip.nut")

let defColor = 0xFFFFFFFF
let tooltipOffset = hdpx(50)

let mkText = @(text, color = defColor) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
  color
  maxWidth = pw(85)
}.__update(fontTiny)

let mkTooltipBtn = @(tooltip) infoTooltipButton(
  @() tooltip,
  { flowOffset = tooltipOffset },
  { size = hdpx(30), pos = [-hdpx(40), hdpx(5)]}
)

function mkTooltippedRow(row, tooltip) {
  let stateFlags = Watched(0)
  let key = {}

  return {
    size = FLEX_H
    children = [
      mkTooltipBtn(tooltip)
      row.__merge({
        key
        behavior = Behaviors.Button
        onElemState = withTooltip(stateFlags, key, @() {
          content = tooltip,
          flow = FLOW_HORIZONTAL
          flowOffset = tooltipOffset
        })
        onDetach = tooltipDetach(stateFlags)
      })
    ]
  }
}

function mkRow(t1, t2, icon = null, tooltip = null) {
  let baseComp = {
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    valign = ALIGN_BOTTOM
    gap = hdpx(10)
    children = [
      mkText(t1)
      icon
      {
        size = FLEX
      }
      mkText(t2)
    ]
  }

  return tooltip == null ? baseComp : mkTooltippedRow(baseComp, tooltip)
}

let mkMarqueeText = @(text)
  mkText(text).__update({ behavior = Behaviors.Marquee })

function mkStatRow(stats, config, campaign, ctor = null) {
  let configCamp = config?.campaign ?? campaign
  if (configCamp == campaign) {
    let value = config.value(stats)
    return value > 0
      ? ctor != null
        ? ctor(config.name, config?.format(value) ?? value, config?.icon, config?.tooltip)
        : mkRow(config.name, config?.format(value) ?? value, config?.icon, config?.tooltip)
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
    name = loc("stats/damage_per_battle_max")
    campaign = "ships"
    value = @(stats) stats?.profile_stat_damage_max ?? 0
    format = @(v) format("%.0f", v)
  }
  {
    name = loc("stats/kill_death_ratio")
    campaign = "tanks"
    value = @(stats) secureDiv(stats?.profile_stat_kill ?? 0, stats?.profile_stat_death ?? 0)
    format = @(v) format("%.2f", v)
  }
  {
    name = loc("stats/avg_score_dmg")
    campaign = "tanks"
    value = @(stats) stats?.m_avg_score ?? 0
    format = @(v) format("%.0f", v)
    tooltip = loc("stats/avg_score_dmg/tooltip")
  }
  {
    name = loc("stats/avg_score_enemy_hp")
    campaign = "ships"
    value = @(stats) stats?.m_avg_score ?? 0
    format = @(v) format("%.1f%%", v)
    tooltip = loc("stats/avg_score_dmg/tooltip")
  }
  {
    name = loc("stats/avg_score_dmg")
    campaign = "air"
    value = @(stats) stats?.m_avg_score ?? 0
    format = @(v) format("%.0f", v)
    tooltip = loc("stats/avg_score_dmg/tooltip")
  }
]

return {
  viewStats
  mkRow
  mkMarqueeText
  mkStatRow
}
