from "%globalsDarg/darg_library.nut" import *
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/string.nut" import utf8ToLower
from "%sqstd/time.nut" import TIME_DAY_IN_SECONDS
from "%appGlobals/userstats/serverTime.nut" import getServerTime, isServerTimeValid
from "%appGlobals/activeControls.nut" import isGamepad
from "%appGlobals/clanConsts.nut" import GRADE_LEADER
import "%appGlobals/decorators/avatars.nut" as getAvatarImage
from "%appGlobals/profileStates.nut" import myUserId
from "%appGlobals/pServer/campaign.nut" import campaignsList
from "%appGlobals/pServer/clanServConfigs.nut" import clanServerConfigs
from "%appGlobals/permissions.nut" import allow_clans_chat
from "%rGui/clans/clanCfg.nut" import gradesSettingscfg
from "%rGui/clans/clanChatState.nut" import clanChatMembers
from "%rGui/clans/components/clanComps.nut" import mkButtonText, mkSectionText, divider, mkGradeIcon
from "%rGui/clans/components/clanPropertyBtn.nut" import mkClanChangeBtn
from "%rGui/clans/components/chooseValueWnd.nut" import openChooseValueWnd
from "%rGui/clans/currentClanState.nut" import currentClanId
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/components/playerPlaceIcon.nut" import mkPlaceIcon, playerPlaceIconSize
from "%rGui/components/selectedLine.nut" import opacityTransition
from "%rGui/components/textButton.nut" import iconButtonCommon
from "%rGui/contacts/contact.nut" import allContacts, Contact, validateNickNames
from "%rGui/contacts/contactInfoPkg.nut" import contactNameBlock
from "%rGui/contacts/contactPublicInfo.nut" import mkPublicInfo, refreshPublicInfo, allPublicInfo
from "%rGui/decorators/decoratorState.nut" import chosenNickFrame, chosenTitle
from "%rGui/clans/clanState.nut" import leaveClan
from "%rGui/mpStatistics/viewProfile.nut" import viewProfile
from "%rGui/style/gradients.nut" import simpleHorGradInv
from "%rGui/style/stdColors.nut" import selectColor, nameColor, onlineColor, rowBgEvenColor, rowBgOddColor


let selectedMemberId = Watched(null)
let myNameDecorators = Computed(@() { nickFrame = chosenNickFrame.get()?.name, title = chosenTitle.get()?.name })

const headerRowColor = 0xC0000000
const myNameColor = 0xFFFFCC00
const gradeNameColor = 0xFFFEE0A9
const iconSize = hdpx(25)
const btnIconSize = hdpx(70)
const gapSection = hdpx(20)
const rowHeight = hdpx(110)
const columnGap = hdpx(10)

const memberRowHeight = hdpx(90)
const memberAvatarSize = hdpxi(70)
const gradeIconSize = hdpxi(36)
const gradeColumnWidth = hdpx(260)

const sortDirectionIcon = "ui/gameuiskin#triangle.svg"

const CMS_CAMPAIGNS = "campaigns"
const CMS_RANK = "rank"
const CMS_NAME = "alphabet"

const memberSortPriority = [CMS_RANK, CMS_CAMPAIGNS, CMS_NAME]
const defSortValue = memberSortPriority[0]
let sortingBy = mkWatched(persist, "sortingBy", defSortValue)
let isSortAscending = mkWatched(persist, "isSortAscending", false)

let memberSortingCfg = {
  locTitle = "clans/members/sortBy"
  values = memberSortPriority
  valToString = @(v) $"clans/members/sort/{v}"
  btnMinWidth = hdpx(300)
  col = 3
}

let nickToLower = memoize(utf8ToLower)

let mkMemberAvatar = @(info) @() {
  watch = info
  size = memberAvatarSize
  rendObj = ROBJ_IMAGE
  image = Picture($"{getAvatarImage(info.get()?.decorators?.avatar)}:{memberAvatarSize}:P")
}

let mkMemberNameBlock = @(contact, info, uid, isMyUser) function() {
  let isMy = isMyUser.get()
  let pubInfo = info.get() ?? {}
  let memberInfo = !isMy ? pubInfo
    : { ...pubInfo, decorators = myNameDecorators.get() }
  let nameStyle = { size = FLEX_H, color = isMy ? myNameColor : nameColor, ...fontTiny }

  return {
    ...contactNameBlock({ realnick = contact.get()?.realnick ?? uid }, memberInfo, [], { nameStyle })
    watch = [contact, info, isMyUser, myNameDecorators]
    size = FLEX
  }
}

let mkMemberGrade = @(gradeStr) {
  size = const [gradeColumnWidth, FLEX]
  flow = FLOW_HORIZONTAL
  gap = columnGap
  valign = ALIGN_CENTER
  children = [
    mkGradeIcon(gradeStr, gradeIconSize)
    {
      size = FLEX_H
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      color = gradeNameColor
      text = loc(gradesSettingscfg.valToString(gradeStr))
      ...fontTiny
    }
  ]
}

let mkLeaveBtn = @(isMyUser, gradeStr) function() {
  let width = isGamepad.get() ? memberAvatarSize * 2 : memberAvatarSize
  return {
    watch = [isMyUser, isGamepad]
    size = [width, SIZE_TO_CONTENT]
    children = !isMyUser.get() || gradeStr == GRADE_LEADER ? null
      : iconButtonCommon("ui/gameuiskin#icon_exit.svg",
          @() openMsgBox({
            text = loc("clans/leaveRequest/confirm")
            buttons = [
              { id = "cancel", isCancel = true, styleId = "PRIMARY" }
              { text = loc("clans/leaveBtn"), cb = @() leaveClan(currentClanId.get()) }
            ]
          }),
          {
            iconOvr = {
              size = hdpx(35)
              keepAspect = true
              transform = { rotate = 180 }
            }
            ovr = {
              size = [width, memberAvatarSize]
              minWidth = memberAvatarSize
            }
          })
  }
}

let sortDirectionBtn = @() {
  watch = [isSortAscending, isGamepad]
  children = iconButtonCommon(sortDirectionIcon,
    @() isSortAscending.set(!isSortAscending.get()),
    {
      iconOvr = {
        size = iconSize
        keepAspect = true
        transform = { rotate = isSortAscending.get() ? 180 : 0 }
      }
      ovr = {
        size = isGamepad.get() ? [btnIconSize * 2, btnIconSize] : [btnIconSize, btnIconSize]
        minWidth = btnIconSize
      }
    })
}

function mkMembersText(maxMembers, curMembers) {
  let textOvr = { size = SIZE_TO_CONTENT }.__merge(fontTinyShaded)

  return @() {
    watch = [maxMembers, curMembers]
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    children = [
      mkSectionText(loc("clans/members/title"), textOvr)
      mkSectionText($"{curMembers.get()}/{maxMembers.get()}", textOvr)
    ]
  }
}

function mkHeaderActionsRow(maxMembers, curMembers) {
  let sortAction = @() openChooseValueWnd(memberSortingCfg, sortingBy, @(v) sortingBy.set(v))
  return {
    size = const [FLEX, rowHeight]
    flow = FLOW_HORIZONTAL
    rendObj = ROBJ_SOLID
    color = headerRowColor
    gap = columnGap
    padding = gapSection
    valign = ALIGN_CENTER
    children = [
      sortDirectionBtn
      @() {
        watch = sortingBy
        children = mkClanChangeBtn(mkButtonText(sortingBy.get(), memberSortingCfg),
          sortAction,
          [SIZE_TO_CONTENT, btnIconSize],
          { childOvr = { padding = [0, hdpx(20)] }})
      }
      { size = FLEX_H }
      mkMembersText(maxMembers, curMembers)
    ]
  }
}

let localLogoutTimes = hardPersistWatched("localLogoutTimes", {})
local prevOnlineUsers = {}

clanChatMembers.subscribe(function(currentOnlineUsers) {
  if (currentOnlineUsers.len() > 0) {
    let now = getServerTime()

    foreach (userId, _ in prevOnlineUsers) {
      if (userId not in currentOnlineUsers)
        localLogoutTimes.mutate(@(v) v[userId] <- now)
    }
  }

  prevOnlineUsers = clone currentOnlineUsers
})

function mkOnlineStatus(userId, isOwnClanW, loginTime) {
  let onlineStatusText = Computed(function() {
    let localLogout = localLogoutTimes.get()?[userId] ?? 0
    let lastLoginTime = localLogout > loginTime ? localLogout : loginTime
    let daysSinceLogin = (getServerTime() - lastLoginTime) / TIME_DAY_IN_SECONDS
    return !allow_clans_chat.get()
      || !isOwnClanW.get()
      || !isServerTimeValid.get()
      || lastLoginTime <= 0 ? null
        : userId in clanChatMembers.get() ? colorize(onlineColor, loc("contacts/online"))
        : daysSinceLogin <= 0 ? loc("onlineStatus/recently")
        : loc("onlineStatus/daysSinceLogin", { daysSinceLogin })
  })

  return @() !onlineStatusText.get() ? { watch = onlineStatusText }
    : {
        watch = onlineStatusText
        size = const [pw(20), FLEX]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        padding = const [hdpx(10), 0]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = onlineStatusText.get()
        ...fontVeryTinyAccentedShaded
      }
}

function mkMemberRow(clanW, member, idx) {
  let { userId, gradeStr, loginTimestamp = 0} = member
  let isSelected = Computed(@() selectedMemberId.get() == userId)
  let uid = userId.tostring()
  let info = mkPublicInfo(uid)
  let contact = Contact(uid)
  let isOwnClan = Computed(@() currentClanId.get() == clanW.get()?.clanId)
  let isMyUser = Computed(@() userId == myUserId.get())

  return {
    key = uid
    size = const [FLEX, memberRowHeight]
    rendObj = ROBJ_SOLID
    color = idx % 2 == 0 ? rowBgEvenColor : rowBgOddColor
    children = [
      @() {
        watch = isSelected
        size = FLEX
        rendObj = ROBJ_IMAGE
        image = simpleHorGradInv
        color = selectColor
        opacity = isSelected.get() ? 0.9 : 0
        transform = const { rotate = 180 }
        transitions = opacityTransition
      }
      {
        size = FLEX
        flow = FLOW_HORIZONTAL
        gap = columnGap
        padding = const [0, columnGap]
        valign = ALIGN_CENTER
        behavior = Behaviors.Button
        onAttach = @() refreshPublicInfo(uid)
        function onClick() {
          selectedMemberId.set(userId)
          viewProfile(uid)
        }
        children = [
          idx < 10 ? mkPlaceIcon(idx + 1)
            : {
                size = playerPlaceIconSize
                rendObj = ROBJ_TEXT
                halign = ALIGN_CENTER
                valign = ALIGN_CENTER
                text = idx + 1
              }.__update(fontTiny)
          mkMemberAvatar(info)
          mkMemberNameBlock(contact, info, uid, isMyUser)
          mkOnlineStatus(userId, isOwnClan, loginTimestamp)
          mkMemberGrade(gradeStr)
          mkLeaveBtn(isMyUser, gradeStr)
        ]
      }
    ]
  }
}

let mkMembersList = @(clanW, members) @() {
  watch = members
  size = FLEX_H
  flow = FLOW_VERTICAL
  children = members.get().map(@(member, idx) mkMemberRow(clanW, member, idx))
}

function mkClanMembersSection(clanW) {
  let hasClan = Computed(@() clanW.get() != null)
  let maxMembers = Computed(@() clanW.get()?.maxMembers ?? 0)
  let curMembers = Computed(@() clanW.get()?.users.len() ?? 0)

  let members = Computed(function() {
    let users = clanW.get()?.users ?? []
    let sortingId = sortingBy.get()
    let isAscending = isSortAscending.get()

    let campaigns = campaignsList.get()
    let allInfo = allPublicInfo.get()
    let contacts = allContacts.get()
    let grades = clanServerConfigs.get()?.grades ?? {}

    let decorated = users.map(function(user) {
      let uid = user.userId.tostring()
      let res = { user, uid }
      res[CMS_NAME] <- nickToLower(contacts?[uid].realnick ?? uid)
      res[CMS_RANK] <- grades?[user?.gradeStr].order ?? -1
      if (sortingId == CMS_CAMPAIGNS) {
        let userCampaigns = allInfo?[uid]?.general.campaigns
        res[CMS_CAMPAIGNS] <- campaigns.reduce(@(r, c) r + (userCampaigns?[c].level ?? 0), 0)
      }
      res.primeKey <- res?[sortingId] ?? 0
      return res
    })

    let sortPrime = sortingId == CMS_NAME ? @(a, b) b.primeKey <=> a.primeKey
      : @(a, b) a.primeKey <=> b.primeKey

    let sortFunc = @(a, b) sortPrime(a, b)
      || a[CMS_RANK] <=> b[CMS_RANK]
      || b[CMS_NAME] <=> a[CMS_NAME]
      || a.uid <=> b.uid

    decorated.sort(isAscending ? sortFunc : @(a, b) sortFunc(b, a)) 

    return decorated.map(@(item) item.user)
  })

  let onMembersChanged = @(users) users.len() > 0 ? validateNickNames(users.map(@(user) user.userId)) : null

  return @() {
    watch = hasClan
    key = onMembersChanged
    size = FLEX_H
    flow = FLOW_VERTICAL
    function onAttach() {
      members.subscribe(onMembersChanged)
      onMembersChanged(members.get())
    }
    function onDetach() {
      members.unsubscribe(onMembersChanged)
      selectedMemberId.set(null)
    }
    children = !hasClan.get()
      ? null
      : [
          mkHeaderActionsRow(maxMembers, curMembers)
          divider
          mkMembersList(clanW, members)
        ]
  }
}

return { mkClanMembersSection, selectedMemberId }
