from "%globalsDarg/darg_library.nut" import *
let { registerScene } = require("%rGui/navState.nut")
let { getPlayerName } = require("%appGlobals/user/nickTools.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let backButton = require("%rGui/components/backButton.nut")
let playersSortFunc = require("%rGui/mpStatistics/playersSortFunc.nut")
let { mkMpStatsTable, getColumnsByCampaign } = require("%rGui/mpStatistics/mpStatsTable.nut")

let config = Watched(null)
let close = @() config(null)
let backBtn = backButton(close)

let campaign = Computed(@() config.value?.campaign ?? "")
let title = Computed(@() config.value?.title ?? "")
let playersByTeam = Computed(function() {
  let res = (config.value?.playersByTeam ?? [])
    .map(@(list) list
      .map(@(p) p.__merge({ nickname = getPlayerName(p.name) }))
      .sort(playersSortFunc(campaign.value)))
  let maxTeamSize = res.reduce(@(maxSize, t) max(maxSize, t.len()), 0)
  res.each(@(t) t.resize(maxTeamSize, null))
  return res
})

let wndTitle = @() {
  watch = title
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = Color(255, 255, 255)
  text = title.value
}.__update(fontMedium)

let mpStatiscicsStaticWnd = bgShaded.__merge({
  key = {}
  size = [ sw(100), flex()]
  padding =  [saBorders[1], 0]
  children = [
    @() {
      watch = [ campaign, playersByTeam ]
      size = [ flex(), SIZE_TO_CONTENT ]
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      children = mkMpStatsTable(getColumnsByCampaign(campaign.value), playersByTeam.value, null)
    }
    {
      size = [saSize[0], SIZE_TO_CONTENT]
      valign = ALIGN_CENTER
      hplace = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      gap = hdpx(50)
      children =[
        backBtn
        wndTitle
      ]
    }
  ]
  animations = wndSwitchAnim
})

registerScene("mpStatiscicsStaticWnd", mpStatiscicsStaticWnd, close, keepref(Computed(@() config.value != null)))

return @(cfg) config(cfg)
