from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import setInterval, clearTimer
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/squadState.nut" import squadDataRemote, squadId, isSquadLeader, isInSquad
from "%rGui/clans/components/clanComps.nut" import clanScrollBarStyle, mkGradeIcon
import "%rGui/clans/clanSquadCreateWnd.nut" as clanSquadCreateWnd
from "%rGui/clans/clanSquadsState.nut" import requestClanSquads, clanSquadsList, SQUAD_OPEN, SQUAD_HIDDEN,
  isClanSquadLeader
from "%rGui/clans/currentClanState.nut" import currentClan
from "%rGui/components/buttonStyles.nut" import defButtonMinWidth
from "%rGui/components/gradTexts.nut" import mkGradRank
from "%rGui/components/scrollbar.nut" import makeVertScroll
from "%rGui/components/textButton.nut" import textButtonCommon, textButtonPrimary, buttonsVGap
from "%rGui/contacts/contact.nut" import validateNickNames, Contact
from "%rGui/contacts/contactInfoPkg.nut" import contactNameBlock, contactAvatar
from "%rGui/contacts/contactPublicInfo.nut" import mkPublicInfo, refreshPublicInfo
from "%rGui/gameModes/gameModeState.nut" import maxSquadSizeByCampaign, maxSquadSize
from "%rGui/squad/squadManager.nut" import requestSquadMembership, myMembershipRequests, revokeSquadMembershipRequest
from "%rGui/squad/squadPanel.nut" import squadPanelFull, squadPanelGap
from "%rGui/style/stdColors.nut" import rowBgEvenColor, rowBgOddColor


const AUTO_REFRESH_PERIOD = 10.0
const rowPadding = buttonsVGap / 2
const rowBtnHeight = evenPx(80)
const rowBtnWidth = defButtonMinWidth - 2 * rowPadding
const rowHeight = rowBtnHeight + buttonsVGap
const gradeIconSize = evenPx(36)
const campIconSize = evenPx(60)

const flexGapComp = { size = FLEX }
const tblGapComp = { size = [buttonsVGap, 0] }

let isAttached = Watched(false)

squadDataRemote.subscribe(function(d) {
  if (d?.squadType != null && isAttached.get())
    requestClanSquads()
})

let unknownCampIcon = { icon = "icon_primary_attention.svg" }
let campIcons = {
  tanks = {
    icon = "ground_saver.avif"
    pos = [0, campIconSize * 0.1]
  }
  air = {
    icon = "fighter_air_saver.avif"
    pos = [0, campIconSize * 0.03]
  }
  ships = {
    icon = "water_saver.avif"
    pos = [0, campIconSize * 0.05]
  }
}

function mkCampIcon(campaign) {
  if (campaign == "")
    return { size = campIconSize }
  let { icon, pos = null } = campIcons?[campaign] ?? unknownCampIcon
  return {
    size = campIconSize
    pos
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#{icon}:{campIconSize}")
    keepAspect = true
  }
}

let mkMySquadStatus = @(text) {
  size = [rowBtnWidth, SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  text
  ...fontTiny
}

function mkSquadRow(squad, idx) {
  let { leader, data = {}, members = [] } = squad
  let { campaign = "", mRank = 0, squadType = null } = data
  let userIdStr = leader.tostring()
  let contact = Contact(userIdStr)
  let info = mkPublicInfo(userIdStr)
  let member = Computed(@() currentClan.get()?.users.findvalue(@(m) m.userId == leader))
  let squadSize = Computed(@() maxSquadSizeByCampaign.get()?[campaign] ?? maxSquadSize.get())
  return @() {
    watch = [contact, info, member, squadSize, squadId, isSquadLeader, myMembershipRequests]
    key = leader
    size = [FLEX, rowHeight]
    padding = rowPadding
    rendObj = ROBJ_SOLID
    color = idx % 2 == 0 ? rowBgEvenColor : rowBgOddColor

    function onAttach() {
      refreshPublicInfo(userIdStr)
      validateNickNames([userIdStr])
    }

    flow = FLOW_HORIZONTAL
    gap = rowPadding
    valign = ALIGN_CENTER
    children = [
      contactAvatar(info.get(), rowBtnHeight)
      mkGradeIcon(member.get()?.gradeStr ?? "", gradeIconSize)
      contactNameBlock(contact.get(), info.get())
      flexGapComp
      {
        rendObj = ROBJ_TEXT
        text = loc("squad/members/counter", { count = members.len(), total = squadSize.get() })
      }.__update(fontTiny)
      tblGapComp
      mkCampIcon(campaign)
      {
        size = [hdpx(80), SIZE_TO_CONTENT]
        children = mRank == 0 ? null : mkGradRank(mRank)
      }
      tblGapComp
      squadType == null ? { size = [rowBtnWidth, SIZE_TO_CONTENT] }
        : squadId.get() == leader
          ? mkMySquadStatus(loc(isSquadLeader.get() ? "status/squad_leader" : "status/squad_member"))
        : myMembershipRequests.get()?[leader]
          ? textButtonCommon(utf8ToUpper(loc("revokeMembershipRequest")),
              @() revokeSquadMembershipRequest(leader),
              { ovr = { size = [rowBtnWidth, rowBtnHeight], minWidth = rowBtnWidth } })
        : textButtonPrimary(utf8ToUpper(loc(squadType == SQUAD_OPEN ? "join" : "requestToJoin")),
            @() requestSquadMembership(leader),
            { ovr = { size = [rowBtnWidth, rowBtnHeight], minWidth = rowBtnWidth } })
    ]
  }
}

let squadsList = @() {
  watch = clanSquadsList
  size = FLEX_H
  flow = FLOW_VERTICAL
  children = clanSquadsList.get()
    .filter(@(s) (s?.data.squadType ?? SQUAD_HIDDEN) != SQUAD_HIDDEN)
    .map(mkSquadRow)
}

return {
  key = {}
  size = FLEX
  function onAttach() {
    isAttached.set(true)
    requestClanSquads()
    setInterval(AUTO_REFRESH_PERIOD, requestClanSquads)
  }
  function onDetach() {
    clearTimer(requestClanSquads)
    isAttached.set(false)
  }

  flow = FLOW_VERTICAL
  gap = buttonsVGap
  children = [
    makeVertScroll(
      squadsList
      {
        size = FLEX
        isBarOutside = true
        barStyleCtor = clanScrollBarStyle
      })
    @() {
      watch = [isClanSquadLeader, isInSquad]
      hplace = ALIGN_RIGHT
      valign = ALIGN_BOTTOM
      flow = FLOW_HORIZONTAL
      gap = squadPanelGap
      children = [
        isInSquad.get() ? squadPanelFull : null
        textButtonCommon(
          utf8ToUpper(loc(isClanSquadLeader.get() ? "clan/squad/configure" : "clan/createSquad")),
          clanSquadCreateWnd)
      ]
    }
  ]
}
