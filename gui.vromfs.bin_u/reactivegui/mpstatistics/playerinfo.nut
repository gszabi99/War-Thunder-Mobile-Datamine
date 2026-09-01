from "%rGui/style/gamercardStyle.nut" import *
from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import deferOnce
from "%sqstd/string.nut" import utf8ToUpper
from "%sqstd/underscore.nut" import arrayByRows
from "%appGlobals/config/campaignPresentation.nut" import campaignPresentations, getCampaignPresentation
from "%appGlobals/pServer/campaign.nut" import campaignsList
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/unreleasedUnits.nut" as unreleasedUnits
from "%appGlobals/permissions.nut" import can_view_player_uids
from "%appGlobals/timeToText.nut" import secondsToTimeAbbrString
from "%rGui/components/buttonStyles.nut" import COMMON
from "%rGui/components/clipboard.nut" import copyToClipboard
from "%rGui/components/levelBlockPkg.nut" import mkLevelBg
import "%rGui/components/mkIconBtn.nut" as mkIconBtn
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/modalWnd.nut" import modalWndBg
from "%rGui/components/spinner.nut" import mkSpinner
from "%rGui/components/starLevel.nut" import starLevelTiny
from "%rGui/components/textButton.nut" import textButtonCommon, mkCustomButton, mergeStyles
from "%rGui/contacts/contact.nut" import validateNickNames, Contact
from "%rGui/contacts/contactActions.nut" import INVITE_TO_FRIENDS, CANCEL_INVITE, REVOKE_INVITE, INVITE_TO_SQUAD, REPORT
from "%rGui/contacts/contactInfoPkg.nut" import contactNameBlock, contactAvatar, contactLevelBlock
from "%rGui/contacts/contactPublicInfo.nut" import mkPublicInfo, refreshPublicInfo, mkIsPublicInfoWait
from "%rGui/contacts/contactsState.nut" import needFetchContactsInBattle
from "%rGui/contacts/mkContactActionBtn.nut" import mkExtContactActionBtn
from "%rGui/contacts/userstatPublicInfo.nut" import mkStatsInfo, mkIsStatsWait, refreshUserStats
from "%rGui/controls/tabs.nut" import mkTab
from "%rGui/controlsMenu/gpActBtn.nut" import btnBEscUp
from "%rGui/mpStatistics/botsInfoState.nut" import mkBotStats, mkBotInfo
from "%rGui/mpStatistics/medalsCtors.nut" import getMedalPresentationWithCtor
from "%rGui/mpStatistics/statRow.nut" import viewStats, mkRow, mkStatRow
from "%rGui/mpStatistics/viewProfile.nut" import selectedPlayerForInfo, SECTION_PROFILE_IDS
from "%rGui/report/reportPlayerState.nut" import mkTimeToNextReport
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/gradients.nut" import mkColoredGradientY
from "%rGui/style/stdColors.nut" import selectColor
from "%rGui/tooltip.nut" import calcPosition


let defSections = [SECTION_PROFILE_IDS.PROFILE]

const maxMedalInRow = 7
const defColor = 0xFFFFFFFF
let hlColor = selectColor
const grayColor = 0x80808080
const commonBgGradColor = 0x990C1113
let secondaryGradColor = selectColor
let iconSize = [hdpx(40), hdpx(20)]
const rowMedalHeight = hdpx(70)
const sectionBtnHeight = hdpx(80)
const sectionBtnGap = hdpx(10)
const lineWidth = hdpx(5)
let bgGradient = mkColoredGradientY(commonBgGradColor, secondaryGradColor)

let mkText = @(text, color = defColor) {
  rendObj = ROBJ_TEXT
  text
  color
}.__update(fontTiny)

let textProps = {
    rendObj = ROBJ_TEXT
    color = selectColor
  }.__update(fontMediumShaded)

let mkTitle = @(title, ovr = {}) {
    rendObj = ROBJ_TEXT
    text = (title != null && title != "") ? loc($"title/{title}") : ""
  }.__update(ovr)

let starLevelOvr = { hplace = ALIGN_CENTER vplace = ALIGN_CENTER pos = const [0, ph(30)] }
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
  size = FLEX_H
  children = [
    contactAvatar(info.get())
    contactNameBlock(contact.get(), info.get())
    contactLevelBlock(info.get())
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
    size = FLEX_H
    children = [
      contactAvatar(info.get())
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
  let gap = { minWidth = hdpx(40) size = FLEX }
  return {
    minWidth = SIZE_TO_CONTENT
    size = FLEX_H
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
      .filter(@(camp)
        campaignPresentations?[camp].campaign != null
          && !uniqueCamps?[campaignPresentations[camp].campaign]
          && (uniqueCamps[campaignPresentations[camp].campaign] <- true)
      )
      .map(@(camp) mkTab(
         { icon = campaignPresentations?[camp].icon, locId = campaignPresentations?[camp].unitsLocId },
         selectedPlayerForInfo.get()?.campaign == camp,
         @() selectedPlayerForInfo.get() == null ? null
           : selectedPlayerForInfo.mutate(@(v) v.campaign = camp)
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

  let campaignExt = getCampaignPresentation(selCampaign).campaign
  foreach(medal in info.get()?.medals ?? {}) {
    let { campaign = campaignExt, ctor } = getMedalPresentationWithCtor(medal.name)
    if (campaign == campaignExt)
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
                size = const [SIZE_TO_CONTENT, rowMedalHeight]
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

let mkSectionBtn = @(id, onClick, isSelected) {
  size = const [FLEX, sectionBtnHeight]
  behavior = Behaviors.Button
  onClick
  sound = { click = "choose" }
  children = [
    {
      size = FLEX
      rendObj = ROBJ_SOLID
      color = commonBgGradColor
    }
    @() {
      watch = isSelected
      size = FLEX
      rendObj = ROBJ_IMAGE
      image = bgGradient
      opacity = isSelected.get() ? 1 : 0
      transitions = [{ prop = AnimProp.opacity, duration = 0.3, easing = InOutQuad }]
    }
    {
      size = FLEX
      margin = const [0, sectionBtnGap / 2]
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = {
        rendObj = ROBJ_TEXTAREA
        behavior = [Behaviors.TextArea, Behaviors.Marquee]
        delay = defMarqueeDelay
        text = utf8ToUpper(loc($"mainmenu/profileInfo/{id}"))
      }.__update(fontTinyAccented)
    }
  ]
}

let mkSectionTabs = @(sections, curSectionId = Watched(null), onSectionChange = @(_) null) {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = sectionBtnGap
  rendObj = ROBJ_BOX
  borderColor = secondaryGradColor
  borderWidth = const [0, 0, lineWidth, 0]
  padding = const [0, 0, lineWidth, 0]
  children = sections.map(@(id) mkSectionBtn(id, @() onSectionChange(id), Computed(@() curSectionId.get() == id)))
}

function mkScoreSection(player, scoreStats) {
  if (scoreStats.len() == 0)
    return null
  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = hdpx(5)
    children = [mkText(loc("mainmenu/profileInfo/score"), hlColor).__update(fontTinyAccented)]
      .extend(scoreStats.map(@(c) mkRow(loc(c.titleId), c.getText(player))))
  }
}

function mkProfileSectionContent(player, info, globalStats, campaign, isInvitesAllowed) {
  let { userId = 0, isBot = false } = player
  let isWaitInfo = mkIsPublicInfoWait(userId)
  let publicStats = isBot ? mkBotStats(player) : mkStatsInfo(userId)
  let isWaitStats = mkIsStatsWait(userId)

  return [
    mkTabsCampaignName
    mkMedals(info, campaign)
    {
      gap = { minWidth = hdpx(50) size = FLEX }
      minWidth = SIZE_TO_CONTENT
      size = FLEX_H
      children = [
        function() {
          let my = info.get()?.campaigns[campaign].units
          let all = globalStats.get()?[campaign]
          if (isWaitInfo.get())
            return { watch = [isWaitInfo, globalStats, info], children = mkSpinner() }
          if (!my || !all)
            return { watch = [isWaitInfo, globalStats, info] }
          return {
            watch = [isWaitInfo, globalStats, info]
            size = const [pw(45), SIZE_TO_CONTENT]
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
            return { watch = [isWaitStats, publicStats], children = mkSpinner() }
          if (!stats)
            return { watch = [isWaitStats, publicStats] }
          return {
            watch = [isWaitStats, publicStats]
            size = const [pw(45), SIZE_TO_CONTENT]
            valign = ALIGN_CENTER
            hplace = ALIGN_RIGHT
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

function mkPlayerInfo(player, globalStats, campaign, isInvitesAllowed, sections = null, scoreStats = null) {
  let { userId = 0, isBot = false } = player
  sections = sections ?? defSections
  if (!isBot) {
    refreshPublicInfo(userId)
    refreshUserStats(userId)
  }
  let contact = Contact(userId)
  if (!isBot)
    validateNickNames([userId])
  let info = isBot ? mkBotInfo(player) : mkPublicInfo(userId)
  let curSectionId = Watched(sections[0])

  let sectionContentById = {
    [SECTION_PROFILE_IDS.PROFILE] = @() mkProfileSectionContent(player, info, globalStats, campaign, isInvitesAllowed),
    [SECTION_PROFILE_IDS.SCORE] = @() mkScoreSection(player, scoreStats ?? []),
  }

  let mkSectionLayer = @(content, isCurrent) {
    opacity = isCurrent ? 1 : 0
    size = FLEX_H
    flow = FLOW_VERTICAL
    valign = ALIGN_TOP
    gap = hdpx(30)
    children = content
  }

  let refSectionId = sections[0]
  let sectionBody = @() {
    watch = curSectionId
    size = FLEX_H
    children = [
      mkSectionLayer(sectionContentById?[refSectionId](), curSectionId.get() == refSectionId)
      curSectionId.get() == refSectionId ? null
        : { size = FLEX, stopMouse = true }
      curSectionId.get() == refSectionId ? null
        : mkSectionLayer(sectionContentById?[curSectionId.get()](), true)
    ]
  }

  return modalWndBg.__merge({
    size = FLEX_H
    flow = FLOW_VERTICAL
    valign = ALIGN_TOP
    stopMouse = true
    children = [
      sections.len() > 1 ? mkSectionTabs(sections, curSectionId, @(id) curSectionId.set(id)) : null
      {
        size = const [sw(45), SIZE_TO_CONTENT]
        hplace = ALIGN_CENTER
        flow = FLOW_VERTICAL
        valign = ALIGN_TOP
        padding = const [hdpx(40), 0]
        gap = hdpx(30)
        minWidth = hdpx(780)
        children = [
          isBot
            ? mkBotNameContent(player, info)
            : mkContactInfo(contact, info)
          mkPlayerUidInfo(player, contact)
          sectionBody
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

  let { player, isInvitesAllowed = true, sections = null, scoreStats = null } = v
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
      if (name in unreleasedUnits.get())
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
    size = const [sw(100), sh(100)]
    onAttach = @() needFetchContactsInBattle.set(true)
    onDetach = @() needFetchContactsInBattle.set(false)
    children = position.__merge({
      size = 0
      children = {
        size = const [sw(50), SIZE_TO_CONTENT]
        transform = {}
        safeAreaMargin = saBordersRv
        behavior = Behaviors.BoundToArea
        children = mkPlayerInfo(player, globalStats, selCampaign, isInvitesAllowed, sections, scoreStats)
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
