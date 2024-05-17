from "%globalsDarg/darg_library.nut" import *
from "%rGui/style/gamercardStyle.nut" import *
let { mkLevelBg } = require("%rGui/components/levelBlockPkg.nut")
let { starLevelTiny } = require("%rGui/components/starLevel.nut")
let { can_view_player_uids } = require("%appGlobals/permissions.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { mkPublicInfo, refreshPublicInfo, mkIsPublicInfoWait } = require("%rGui/contacts/contactPublicInfo.nut")
let { mkStatsInfo, mkIsStatsWait, refreshUserStats } = require("%rGui/contacts/userstatPublicInfo.nut")
let { calcPosition } = require("%rGui/tooltip.nut")
let { bgMessage, bgHeader, bgShaded } = require("%rGui/style/backgrounds.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { mkBotStats, mkBotInfo } = require("botsInfoState.nut")
let { viewStats, mkRow, mkStatRow } = require("%rGui/mpStatistics/statRow.nut")
let { mkSpinner } = require("%rGui/components/spinner.nut")
let { mkTab } = require("%rGui/controls/tabs.nut")
let { lbCfgById } = require("%rGui/leaderboard/lbConfig.nut")
let { campaignsList } = require("%appGlobals/pServer/campaign.nut")
let { getMedalPresentation } = require("%rGui/mpStatistics/medalsPresentation.nut")
let { validateNickNames, Contact } = require("%rGui/contacts/contact.nut")
let { mkExtContactActionBtn } = require("%rGui/contacts/mkContactActionBtn.nut")
let { contactNameBlock, contactAvatar, contactLevelBlock } = require("%rGui/contacts/contactInfoPkg.nut")
let { INVITE_TO_FRIENDS, CANCEL_INVITE, REVOKE_INVITE, INVITE_TO_SQUAD } = require("%rGui/contacts/contactActions.nut")
let { isLbWndOpened } = require("%rGui/leaderboard/lbState.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { selectedPlayerForInfo } = require("%rGui/mpStatistics/viewProfile.nut")

let defColor = 0xFFFFFFFF
let hlColor = 0xFF5FC5FF
let grayColor = 0x80808080
let iconSize = [hdpx(40), hdpx(20)]

let mkText = @(text, color = defColor) {
  rendObj = ROBJ_TEXT
  text
  color
}.__update(fontTiny)

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

let mkContactInfo = @(contact, info) @() {
  watch = [contact, info]
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(30)
  minWidth = SIZE_TO_CONTENT
  size = [flex(), SIZE_TO_CONTENT]
  children = [
    contactAvatar(info.value)
    contactNameBlock(contact.value, info.value)
    contactLevelBlock(info.value)
  ]
}

let mkBotNameContent = @(player, info) function() {
  let {
    playerLevel = player?.level ?? 1,
    playerStarLevel = (player?.starLevel ?? 0),
    playerStarHistoryLevel = 0
  } = info.get()
  return {
    watch = info
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(30)
    minWidth = SIZE_TO_CONTENT
    size = [flex(), SIZE_TO_CONTENT]
    children = [
      contactAvatar(info.value)
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
      levelMark(playerLevel - playerStarLevel, max(playerStarLevel, playerStarHistoryLevel))
    ]
  }
}

function mkPlayerUidInfo(player, contact) {
  let res = { watch = can_view_player_uids }
  if (!can_view_player_uids.get())
    return @() res
  return @() {
    watch = [can_view_player_uids, contact]
    rendObj = ROBJ_TEXT
    text = player?.isBot ? loc("multiplayer/state/bot_ready") : $"UID: {player?.userId} | {contact.get()?.realnick}"
    grayColor
  }.__update(fontTiny)
}

let actions = [
  {
    action = INVITE_TO_FRIENDS
    hotkeys = ["^J:RB"]
    icon = { name = "ui/gameuiskin#icon_contacts.svg" color = 0xFFFFFFFF }
  }
    //same hotkey is correct, only 1 from 4 buttons, displayed at once
  {
    action = CANCEL_INVITE
    hotkeys = ["^J:RB"]
    icon = { name = "ui/gameuiskin#icon_contacts.svg" color = 0xFFEE5252 }
  }
  {
    action = INVITE_TO_SQUAD
    hotkeys = ["^J:RB"]
    icon = { name = "ui/gameuiskin#icon_party.svg" color = 0xFFFFFFFF }
    onlyForFriends = true
  }
  {
    action = REVOKE_INVITE
    hotkeys = ["^J:RB"]
    icon = { name = "ui/gameuiskin#icon_party.svg" color = 0xFFEE5252 }
  }
]

function mkButtons(userId) {
  let gap = { minWidth = hdpx(40) size = flex() }
  if (isLbWndOpened.get())
    return null
  return {
    minWidth = SIZE_TO_CONTENT
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    gap
    children = actions.map(@(cfg) mkExtContactActionBtn(cfg, userId))
  }
}

let tabs = @() {
  watch = selectedPlayerForInfo
  flow = FLOW_HORIZONTAL
  gap = hdpx(40)
  children = campaignsList.get().map(
    @(camp) mkTab(
      lbCfgById?[camp]
      selectedPlayerForInfo.get()?.campaign == camp,
      @() selectedPlayerForInfo.get() == null ? null
        : selectedPlayerForInfo.mutate(@(v) v.campaign = camp)))
}

let mkMedals = @(info, selCampaign) function() {
  let children = []

  let curr = info.get()?.campaigns?[selCampaign] ?? {}
  foreach(v in curr?.starLevelHistory ?? [])
    children.append(levelMark(v.level, v.starLevel + 1))
  if ((curr?.starLevel ?? 0) > 0)
    children.append(levelMark(curr.level - curr.starLevel, curr.starLevel - 1))

  foreach(medal in info.get()?.medals ?? {}) {
    let { campaign = selCampaign, ctor } = getMedalPresentation(medal)
    if (campaign == selCampaign)
      children.append(ctor(medal))
  }
  return {
    watch = info
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(30)
    children = children.len() > 0
      ? [
          mkText(loc("mainmenu/btnMedal"), hlColor).__update(fontTinyAccented)
          {
            valign = ALIGN_CENTER
            flow = FLOW_HORIZONTAL
            gap = hdpx(30)
            children
          }
        ]
      : mkText(loc("mainmenu/noMedal"))
  }
}

function mkPlayerInfo(player, globalStats, campaign) {
  let { userId = 0, isBot = false } = player
  if (!isBot) {
    refreshPublicInfo(userId)
    refreshUserStats(userId)
  }
  let contact = Contact(userId)
  if (!isBot)
    validateNickNames([userId])
  let info = isBot ? mkBotInfo(player) : mkPublicInfo(userId)
  let isWaitInfo = mkIsPublicInfoWait(userId)
  let publicStats = isBot ? mkBotStats(player) : mkStatsInfo(userId)
  let isWaitStats = mkIsStatsWait(userId)
  return bgMessage.__merge({
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
        valign = ALIGN_TOP
        padding = [hdpx(40), hdpx(80), hdpx(40), hdpx(80)]
        gap = hdpx(30)
        minWidth = SIZE_TO_CONTENT
        size = [flex(), SIZE_TO_CONTENT]
        children = [
          isBot
            ? mkBotNameContent(player, info)
            : mkContactInfo(contact, info)
          mkPlayerUidInfo(player, contact)
          tabs
          mkMedals(info, campaign)
          {
            flow = FLOW_HORIZONTAL
            gap = { minWidth = hdpx(50) size = flex() }
            minWidth = SIZE_TO_CONTENT
            size = [flex(), SIZE_TO_CONTENT]
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
                      vplace = ALIGN_CENTER
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
                return {
                  watch = [isWaitStats, publicStats]
                  valign = ALIGN_CENTER
                  flow = FLOW_VERTICAL
                  gap = hdpx(5)
                  children = [mkText(loc("flightmenu/btnStats"), hlColor).__update(fontTinyAccented)]
                    .extend(viewStats.map(@(conf) mkStatRow(stats, conf, campaign)))
                }
              }
            ]
          }
          mkButtons(userId)
        ]
      }
    ]
  })
}

let close = @() selectedPlayerForInfo(null)
let key = "playerInfo"
selectedPlayerForInfo.subscribe(function(v) {
  removeModalWindow(key)
  if (v == null)
    return

  let { player } = selectedPlayerForInfo.get()
  let position = calcPosition(gui_scene.getCompAABBbyKey(player.userId), FLOW_VERTICAL, hdpx(20), ALIGN_CENTER, ALIGN_CENTER)
  let selCampaign = selectedPlayerForInfo.get().campaign
  let globalStats = Computed(function() {
    let { allUnits = {} } = serverConfigs.get()
    let all = {}
    foreach (camp in campaignsList.get()) {
      all[camp] <- { prem = 0, wp = 0 }
    }
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

  addModalWindow(bgShaded.__merge({
    key
    animations = appearAnim(0, 0.2)
    onClick = close
    hotkeys = [[btnBEscUp, { action = close }]]
    sound = { click  = "click" }
    size = [sw(100), sh(100)]
    children = position.__merge({
      size = [0, 0]
      children = {
        size = [hdpx(1000), SIZE_TO_CONTENT]
        transform = {}
        safeAreaMargin = saBordersRv
        behavior = Behaviors.BoundToArea
        children = mkPlayerInfo(player, globalStats, selCampaign)
      }
    })
  }))
})

return {
  mkPlayerInfo
  levelMark

  defColor
  hlColor
  iconSize
  mkText
}
