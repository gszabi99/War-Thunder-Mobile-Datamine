from "%globalsDarg/darg_library.nut" import *
from "%rGui/style/gamercardStyle.nut" import *
let { mkLevelBg } = require("%rGui/components/levelBlockPkg.nut")
let { starLevelTiny } = require("%rGui/components/starLevel.nut")
let { can_view_player_uids } = require("%appGlobals/permissions.nut")
let getAvatarImage = require("%appGlobals/decorators/avatars.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { mkPublicInfo, refreshPublicInfo, mkIsPublicInfoWait } = require("%rGui/contacts/contactPublicInfo.nut")
let { mkStatsInfo, mkIsStatsWait, refreshUserStats } = require("%rGui/contacts/userstatPublicInfo.nut")
let { calcPosition } = require("%rGui/tooltip.nut")
let { bgMessage, bgHeader } = require("%rGui/style/backgrounds.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { mkBotStats, mkBotInfo } = require("botsInfoState.nut")
let { mkSpinner } = require("%rGui/components/spinner.nut")
let { mkTab } = require("%rGui/controls/tabs.nut")
let { lbCfgById } = require("%rGui/leaderboard/lbConfig.nut")
let { campaignsList } = require("%appGlobals/pServer/campaign.nut")
let { getMedalPresentation } = require("%rGui/mpStatistics/medalsPresentation.nut")

let selectedPlayerForInfo = Watched(null)

let defColor = 0xFFFFFFFF
let hlColor = 0xFF5FC5FF
let grayColor = 0x80808080
let iconSize = [hdpx(40), hdpx(20)]

let mkText = @(text, color = defColor) {
  rendObj = ROBJ_TEXT
  text
  color
}.__update(fontTiny)

let mkRow = @(t1, t2, icon = null) {
  size = [flex(), SIZE_TO_CONTENT]
  children = [
    mkText(t1).__update({hplace = ALIGN_LEFT})
    mkText(t2).__update({hplace = ALIGN_RIGHT})
    icon
  ]
}

let textProps = {
    rendObj = ROBJ_TEXT
    fontFx = FFT_GLOW
    fontFxFactor = 48
    fontFxColor = 0xFF000000
    color = 0xFF69DADC
  }.__update(fontMediumShaded)

let mkTitle = @(title, ovr = {}) {
    rendObj = ROBJ_TEXT
    text = (title != null && title != "") ? loc($"title/{title}") : ""
  }.__update(ovr)

let starLevelOvr = { hplace = ALIGN_CENTER vplace = ALIGN_CENTER pos = [0, ph(30)] }
let levelMark = @(level, starLevel) {
  size = array(2, levelHolderSize)
  children = [
    mkLevelBg()
    {
      rendObj = ROBJ_TEXT
      text = level
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
    }.__update(fontSmall)
    starLevelTiny(starLevel, starLevelOvr)
  ]
}

function mkNameContent(player, info) {
  let level = info.get()?.playerLevel ?? (player?.level ?? 1)
  let starLevel = info.get()?.playerStarLevel ?? (player?.starLevel ?? 0)
  return @() {
    watch = info
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(30)
    children = [
      {
        size = [avatarSize, avatarSize]
        rendObj = ROBJ_IMAGE
        image = Picture($"{getAvatarImage(info.get()?.decorators.avatar)}:{avatarSize}:{avatarSize}:P")
      }
      {
        valign = ALIGN_CENTER
        gap = hdpx(10)
        flow = FLOW_VERTICAL
        children = [
          textProps.__merge({
            text = player.name
          })
          mkTitle(info.get()?.decorators.title, fontTinyAccented)
        ]
      }
      levelMark(level - starLevel, starLevel)
    ]
  }
}

let mkPlayerUidInfo = @(player) function() {
  let res = { watch = can_view_player_uids }
  if (!can_view_player_uids.get())
    return res
  let text = player?.isBot ? loc("multiplayer/state/bot_ready") : $"UID: {player?.userId} | {player?.realName}"
  return mkText(text, grayColor)
}

let tabs = @() {
  watch = selectedPlayerForInfo
  flow = FLOW_HORIZONTAL
  gap = hdpx(40)
  children = campaignsList.get().map(
    @(camp) mkTab(
      lbCfgById?[camp]
      selectedPlayerForInfo.get().campaign == camp,
      @()selectedPlayerForInfo.mutate(@(v) v.campaign = camp)))
}

function mkPlayerInfo(player, globalStats, campaign) {
  let { userId = 0, isBot = false } = player
  if (!isBot) {
    refreshPublicInfo(userId)
    refreshUserStats(userId)
  }
  let info = isBot ? mkBotInfo(player) : mkPublicInfo(userId)
  let isWaitInfo = mkIsPublicInfoWait(userId)
  let publicStats = isBot ? mkBotStats(player) : mkStatsInfo(userId)
  let isWaitStats = mkIsStatsWait(userId)
  let medals = Computed(@() info.get()?.medals ?? {})

  let starLevelHistory = Computed(function() {
    let curr = info.get()?.campaigns?[campaign] ?? {}
    return curr?.starLevelHistory ?? []
  })
  let medalItems = starLevelHistory.get().map(@(v) levelMark(v.level, v.starLevel + 1))
  medalItems.extend(medals.get().values()
                  .filter(@(medal) (getMedalPresentation(medal)?.campaign ?? campaign) == campaign)
                  .map(@(medal) getMedalPresentation(medal).ctor(medal)))
  return bgMessage.__merge({
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    valign = ALIGN_TOP
    stopMouse = true
    children = [
      bgHeader.__merge({
        size = [flex(), SIZE_TO_CONTENT]
        padding = hdpx(15)
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = {rendObj = ROBJ_TEXT text = loc("mainmenu/titlePlayerProfile")}.__update(fontSmallAccented)
      })
      {
        flow = FLOW_VERTICAL
        size = [flex(), SIZE_TO_CONTENT]
        valign = ALIGN_TOP
        padding = [hdpx(40), hdpx(80), hdpx(40), hdpx(80)]
        gap = hdpx(30)
        children = [
          mkNameContent(player, info)
          tabs
          @() {
            watch = [starLevelHistory, medals]
            valign = ALIGN_CENTER
            flow = FLOW_HORIZONTAL
            gap = hdpx(30)
            children = medalItems.len() > 0
              ? [
                  mkText(loc("mainmenu/btnMedal"), hlColor).__update(fontTinyAccented)
                  {
                    valign = ALIGN_CENTER
                    flow = FLOW_HORIZONTAL
                    gap = hdpx(30)
                    children = medalItems
                  }
                ]
              : mkText(loc("mainmenu/noMedal"))
          }
          {
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_HORIZONTAL
            gap = hdpx(50)
            children = [
              function() {
                let my = info.get()?.campaigns[campaign].units
                let all = globalStats.get()?[campaign]
                if (isWaitInfo.get())
                  return {
                    watch = [isWaitInfo, globalStats, info]
                    children = mkSpinner()
                  }
                if (!my || !all)
                  return {
                    watch = [isWaitInfo, globalStats, info]
                  }
                return {
                  watch = [isWaitInfo, globalStats, info]
                  size = [flex(), SIZE_TO_CONTENT]
                  valign = ALIGN_CENTER
                  flow = FLOW_VERTICAL
                  gap = hdpx(5)
                  children = [
                    mkText(loc("lobby/vehicles"), hlColor).__update(fontTinyAccented)
                    mkRow(loc("stats/line"), $"{my.wp}/{all.wp}")
                    mkRow(loc("stats/maxLevel"), $"{my.maxLevel}/{my.wp + my.prem + my.rare}")
                    mkRow(loc("stats/premium"), $"{my.prem}/{all.prem}", {
                      size = iconSize
                      rendObj = ROBJ_IMAGE
                      keepAspect = KEEP_ASPECT_FIT
                      image = Picture($"ui/gameuiskin#icon_premium.svg:{iconSize[0]}:{iconSize[1]}:P")
                      hplace = ALIGN_RIGHT
                      vplace = ALIGN_CENTER
                      pos = [hdpx(45), 0]
                    })
                    mkRow(loc("stats/rare"), $"{my.rare}")
                  ]
                }
              }
              function() {
                let stats = publicStats.get()?.stats["global"][campaign]
                if (isWaitStats.get())
                  return {
                    watch = [isWaitStats, publicStats]
                    children = mkSpinner()
                  }
                if (!stats)
                  return { watch = [isWaitStats, publicStats] }
                let percent = stats.battle_end > 0 ? stats.win * 100 / stats.battle_end : 0
                return {
                  watch = [isWaitStats, publicStats]
                  size = [flex(), SIZE_TO_CONTENT]
                  valign = ALIGN_CENTER
                  flow = FLOW_VERTICAL
                  gap = hdpx(5)
                  children = [
                    mkText(loc("flightmenu/btnStats"), hlColor).__update(fontTinyAccented)
                    mkRow(loc("lb/battles"), $"{stats.battle_end}")
                    mkRow(loc("stats/missions_wins"), $"{percent}%")
                  ]
                }
              }
            ]
          }
          mkPlayerUidInfo(player)
        ]
      }
    ]
  })
}

let key = "playerInfo"
selectedPlayerForInfo.subscribe(function(v) {
  removeModalWindow(key)
  if (v == null)
    return
  let position = calcPosition(gui_scene.getCompAABBbyKey(selectedPlayerForInfo.get().player.userId), FLOW_VERTICAL, hdpx(20), ALIGN_CENTER, ALIGN_CENTER)

  let globalStats = Computed(function() {
    let { allUnits = {} } = serverConfigs.get()
    let all = {}
    foreach (unit in allUnits) {
      let { campaign = "", isHidden = false, isPremium = false, costWp = 0} = unit
      if (campaign not in all)
        all[campaign] <- { prem = 0, wp = 0 }
      if (isPremium && !isHidden)
        all[campaign].prem++
      else if (costWp > 0)
        all[campaign].wp++
    }
    return all
  })

  addModalWindow({
    key
    animations = appearAnim(0, 0.2)
    onClick = @() selectedPlayerForInfo(null)
    sound = { click  = "click" }
    size = [sw(100), sh(100)]
    children = position.__merge({
      size = [0, 0]
      children = {
        size = [hdpx(1000), SIZE_TO_CONTENT]
        transform = {}
        safeAreaMargin = saBordersRv
        behavior = Behaviors.BoundToArea
        children = mkPlayerInfo(selectedPlayerForInfo.get().player, globalStats, selectedPlayerForInfo.get().campaign)
      }
    })
  })
})

return {
  selectedPlayerForInfo
  mkPlayerInfo
  levelMark

  defColor
  hlColor
  iconSize
  mkText
  mkRow
}
