from "%globalsDarg/darg_library.nut" import *
from "%rGui/style/gamercardStyle.nut" import *
let { deferOnce } = require("dagor.workcycle")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { mkLevelBg } = require("%rGui/components/levelBlockPkg.nut")
let { starLevelTiny } = require("%rGui/components/starLevel.nut")
let { can_view_player_uids } = require("%appGlobals/permissions.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { mkPublicInfo, refreshPublicInfo, mkIsPublicInfoWait } = require("%rGui/contacts/contactPublicInfo.nut")
let { mkStatsInfo, mkIsStatsWait, refreshUserStats } = require("%rGui/contacts/userstatPublicInfo.nut")
let { calcPosition } = require("%rGui/tooltip.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { modalWndBg, modalWndHeader } = require("%rGui/components/modalWnd.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { mkBotStats, mkBotInfo } = require("botsInfoState.nut")
let { viewStats, mkRow, mkStatRow } = require("%rGui/mpStatistics/statRow.nut")
let { mkSpinner } = require("%rGui/components/spinner.nut")
let { mkTab } = require("%rGui/controls/tabs.nut")
let { campaignsList } = require("%appGlobals/pServer/campaign.nut")
let { getMedalPresentation } = require("%rGui/mpStatistics/medalsPresentation.nut")
let { validateNickNames, Contact } = require("%rGui/contacts/contact.nut")
let { mkExtContactActionBtn } = require("%rGui/contacts/mkContactActionBtn.nut")
let { contactNameBlock, contactAvatar, contactLevelBlock } = require("%rGui/contacts/contactInfoPkg.nut")
let { INVITE_TO_FRIENDS, CANCEL_INVITE, REVOKE_INVITE, INVITE_TO_SQUAD, REPORT } = require("%rGui/contacts/contactActions.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { selectedPlayerForInfo } = require("%rGui/mpStatistics/viewProfile.nut")
let { campaignPresentations } = require("%appGlobals/config/campaignPresentation.nut")
let { needFetchContactsInBattle } = require("%rGui/contacts/contactsState.nut")
let { textButtonCommon, mkCustomButton, mergeStyles } = require("%rGui/components/textButton.nut")
let { mkTimeToNextReport } = require("%rGui/report/reportPlayerState.nut")
let { secondsToTimeAbbrString } = require("%appGlobals/timeToText.nut")
let { COMMON } = require("%rGui/components/buttonStyles.nut")
let { copyToClipboard } = require("%rGui/components/clipboard.nut")
let mkIconBtn = require("%rGui/components/mkIconBtn.nut")
let { releasedUnits } = require("%rGui/unit/unitState.nut")
let { arrayByRows } = require("%sqstd/underscore.nut")

let maxMedalInRow = 7
let defColor = 0xFFFFFFFF
let hlColor = 0xFF5FC5FF
let grayColor = 0x80808080
let iconSize = [hdpx(40), hdpx(20)]
let rowMedalHeight = hdpx(70)

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
  let stateFlags = Watched(0)
  return function() {
    let res = { watch = can_view_player_uids }
    if (!can_view_player_uids.get())
      return res
    if (player?.isBot)
      return res.__update({
        children = mkText("".concat("Debug: ", loc("multiplayer/state/bot_ready")), grayColor)
      })
    let uidInfoText = $"{player?.userId} ({contact.get()?.realnick})"
    return {
      watch = [can_view_player_uids, contact, stateFlags]
      behavior = Behaviors.Button
      onClick = @(evt) copyToClipboard(evt, uidInfoText)
      onElemState = @(s) stateFlags.set(s)
      transform = { scale = stateFlags.get() & S_ACTIVE ? [0.95, 0.95] : [1, 1] }
      transitions = [{ prop = AnimProp.scale, duration = 0.1, easing = InOutQuad }]
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = hdpx(10)
      children = [
        mkText($"Debug: UID {uidInfoText}", grayColor)
        mkIconBtn("ui/gameuiskin#icon_copy.svg", fontTiny.fontSize, stateFlags, grayColor)
      ]
    }
  }
}

let actions = [
  {
    action = INVITE_TO_FRIENDS
    hotkeys = ["^J:RB"]
    icon = { name = "ui/gameuiskin#icon_contacts.svg" color = 0xFFFFFFFF }
    isInviteAction = true
  }
    //same hotkey is correct, only 1 from 4 buttons, displayed at once
  {
    action = CANCEL_INVITE
    hotkeys = ["^J:RB"]
    icon = { name = "ui/gameuiskin#icon_contacts.svg" color = 0xFFEE5252 }
    isInviteAction = true
  }
  {
    action = INVITE_TO_SQUAD
    hotkeys = ["^J:RB"]
    icon = { name = "ui/gameuiskin#icon_party.svg" color = 0xFFFFFFFF }
    onlyForFriends = true
    isInviteAction = true
  }
  {
    action = REVOKE_INVITE
    hotkeys = ["^J:RB"]
    icon = { name = "ui/gameuiskin#icon_party.svg" color = 0xFFEE5252 }
    isInviteAction = true
  }
]

let mkTextReportBtn = @(text) {
  key = text
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = {
    maxWidth = hdpx(150)
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    halign = ALIGN_CENTER
    text
  }.__update(fontTinyAccentedShaded)
}

function mkReportButton(userId) {
  let isVisibleReport = REPORT.mkIsVisible(userId)
  let timeToNextReport = mkTimeToNextReport(userId)

  return @() {
    watch = [isVisibleReport, timeToNextReport]
    hplace = ALIGN_RIGHT
    children = !isVisibleReport.get() ? null
      : timeToNextReport.get() <= 0
        ? textButtonCommon(utf8ToUpper(loc(REPORT.locId)),
          @() REPORT.action(userId),
          { hotkeys = ["^J:LB"] })
      : mkCustomButton(
          mkTextReportBtn($"{utf8ToUpper(loc(REPORT.locId))} {secondsToTimeAbbrString(timeToNextReport.get())}"),
          @() null,
          mergeStyles(COMMON, {}))
  }
}

function mkButtons(userId, isInvitesAllowed) {
  let gap = { minWidth = hdpx(40) size = flex() }
  return {
    minWidth = SIZE_TO_CONTENT
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    gap
    children = [
      {
        hplace=ALIGN_LEFT
        children = actions
          .filter(@(v) isInvitesAllowed || !v.isInviteAction)
          .map(@(cfg) mkExtContactActionBtn(cfg, userId))
      }
      mkReportButton(userId)
    ]
  }
}

function mkTabsCampaignName() {
  let uniqueCamps = {}
  return {
    watch = selectedPlayerForInfo
    flow = FLOW_HORIZONTAL
    gap = hdpx(40)
    children = campaignsList.get()
      .map(@(camp) campaignPresentations?[camp])
      .filter(@(cfg) cfg?.campaign != null && !uniqueCamps?[cfg.campaign] && (uniqueCamps[cfg.campaign] <- true))
      .map(@(cfg) mkTab(
         { icon = cfg?.icon, locId = cfg?.unitsLocId },
         selectedPlayerForInfo.get()?.campaign == cfg.campaign,
         @() selectedPlayerForInfo.get() == null ? null
           : selectedPlayerForInfo.mutate(@(v) v.campaign = cfg.campaign)
      ))
  }
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
    flow = FLOW_VERTICAL
    gap = hdpx(30)
    children = children.len() > 0
      ? [
          mkText(loc("mainmenu/btnMedal"), hlColor).__update(fontTinyAccented)
          {
            valign = ALIGN_CENTER
            flow = FLOW_VERTICAL
            gap = hdpx(5)
            children = arrayByRows(children, maxMedalInRow)
              .map(@(ch) {
                size = [SIZE_TO_CONTENT, rowMedalHeight]
                valign = ALIGN_CENTER
                flow = FLOW_HORIZONTAL
                gap = hdpx(30)
                children = ch
              })
          }
        ]
      : mkText(loc("mainmenu/noMedal"))
  }
}

function mkPlayerInfo(player, globalStats, campaign, isInvitesAllowed) {
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
  return modalWndBg.__merge({
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    valign = ALIGN_TOP
    stopMouse = true
    children = [
      modalWndHeader(loc("mainmenu/titlePlayerProfile"))
      {
        hplace = ALIGN_CENTER
        flow = FLOW_VERTICAL
        valign = ALIGN_TOP
        padding = [hdpx(40), 0]
        gap = hdpx(30)
        minWidth = hdpx(780)
        children = [
          isBot
            ? mkBotNameContent(player, info)
            : mkContactInfo(contact, info)
          mkPlayerUidInfo(player, contact)
          mkTabsCampaignName
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
              { size = flex() }
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
          mkButtons(userId, isInvitesAllowed)
        ]
      }
    ]
  })
}

let close = @() selectedPlayerForInfo.set(null)
let key = "playerInfo"
selectedPlayerForInfo.subscribe(function(v) {
  removeModalWindow(key)
  if (v == null)
    return

  let { player, isInvitesAllowed = true } = v
  let aabb = gui_scene.getCompAABBbyKey(player.userId)
  if (aabb == null) {
    deferOnce(close)
    return
  }

  let position = calcPosition(aabb, FLOW_HORIZONTAL, hdpx(20), ALIGN_CENTER, ALIGN_CENTER)
  let selCampaign = v.campaign
  let globalStats = Computed(function() {
    let { allUnits = {} } = serverConfigs.get()
    let all = {}
    foreach (camp in campaignsList.get()) {
      all[camp] <- { prem = 0, wp = 0 }
    }
    foreach (unit in allUnits) {
      let { campaign = "", isHidden = false, isPremium = false, costWp = 0, name = ""} = unit
      if (name not in releasedUnits.get())
        continue
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
    onAttach = @() needFetchContactsInBattle.set(true)
    onDetach = @() needFetchContactsInBattle.set(false)
    children = position.__merge({
      size = [0, 0]
      children = {
        size = [hdpx(900), SIZE_TO_CONTENT]
        transform = {}
        safeAreaMargin = saBordersRv
        behavior = Behaviors.BoundToArea
        children = mkPlayerInfo(player, globalStats, selCampaign, isInvitesAllowed)
      }
    })
  }))
})

return {
  mkPlayerInfo
  levelHolderSize
  levelMark

  defColor
  hlColor
  iconSize
  mkText
}
