from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout
from "math" import ceil
from "%sqstd/platform.nut" import is_pc
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/pServer/pServerApi.nut" import clanRequestResponseInProgress
from "%rGui/clans/clanSubmissionsState.nut" import approveClanSubmission, rejectClanSubmission,
  canCompleteClanRequest, clanSubmissions, hasClanSubmissions, rejectAllClanSubmissions, approveAllClanSubmissions,
  isAllSubmissionsInProgress
from "%rGui/clans/currentClanState.nut" import currentClan
from "%rGui/components/buttonStyles.nut" import defButtonMinWidth
from "%rGui/components/closeWndBtn.nut" import closeWndBtn
from "%rGui/components/gradientDefComps.nut" import headerHeightInSafeArea, headerMargin
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/components/paginator.nut" import mkPaginator, paginatorHeight
from "%rGui/components/spinner.nut" import spinner
from "%rGui/components/textButton.nut" import iconButtonCommon, iconButtonInactive, textButtonCommon
from "%rGui/components/textInput.nut" import floatingTextInput
from "%rGui/contacts/contact.nut" import Contact, getContactNick, allContacts
from "%rGui/contacts/contactInfoPkg.nut" import gap, rowHeight
from "%rGui/contacts/mkContactListScene.nut" import mkNoContactsMsg
import "%rGui/contacts/mkContactRow.nut" as mkContactRow
from "%rGui/mpStatistics/viewProfile.nut" import viewProfile
from "%rGui/style/stdColors.nut" import tabBgColor
from "%rGui/unit/unitNameSearch.nut" import mkSearchTokenMemoized


const textInputHeight = evenPx(80)
const searchIconSize = evenPx(40)
const resetImgHeight = evenPx(30)
const btnMargin = hdpx(8)
const bigGap = 2 * btnMargin

const btnIconSize = evenPx(50)
const listHeight = saSize[1] - headerHeightInSafeArea - headerMargin - textInputHeight - 2 * bigGap - paginatorHeight
const ROWS_IN_PAGE = (listHeight / rowHeight).tointeger()
const msgIcon = "ui/gameuiskin#icon_clan_letter.svg"

let curPage = mkWatched(persist, "curPage", 0)
let searchName = mkWatched(persist, "searchName", "")
let searchNameDeffered = Watched(searchName.get())

let hasSpaceInClan = Computed(@() (currentClan.get()?.maxMembers ?? 0) > (currentClan.get()?.users.len() ?? 0))

let updateSearchNameDeffered = @() searchNameDeffered.set(searchName.get())
searchName.subscribe(is_pc ? @(_) resetTimeout(0.8, updateSearchNameDeffered)
  : @(_) updateSearchNameDeffered())

let btnDefOvr = {
  iconOvr = { size = btnIconSize }
  ovr = {
    size = [hdpx(130), rowHeight - btnMargin * 2]
    minWidth = btnIconSize
    vplace = ALIGN_CENTER
  }
}

let askRejectSubmission = @(userId) openMsgBox({
  text = loc("clans/submissions/askReject")
  buttons = [
    { id = "cancel", isCancel = true }
    { id = "reject", cb = @() rejectClanSubmission(userId) }
  ]
})

let openSubmissionRequest = @(contact, text) openMsgBox({
  text
  title = loc("clans/manage/requestTitle", { user = getContactNick(contact) })
})

function mkClanSubmissionResponse(s) {
  let isInProgress = Computed(@() isAllSubmissionsInProgress.get() || s.userId in clanRequestResponseInProgress.get())
  return @() {
    watch = [canCompleteClanRequest, isInProgress, hasSpaceInClan]
    size = FLEX_V
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap
    margin = hdpx(8)
    children = isInProgress.get() ? spinner
      : canCompleteClanRequest.get()
        ? [
            iconButtonCommon("ui/gameuiskin#icon_party_not_ready.svg", @() askRejectSubmission(s.userId), btnDefOvr)
            hasSpaceInClan.get()
              ? iconButtonCommon("ui/gameuiskin#icon_party_ready.svg", @() approveClanSubmission(s.userId), btnDefOvr)
              : iconButtonInactive("ui/gameuiskin#icon_party_ready.svg",
                  @() openMsgBox({ text = loc("error/CLAN_IS_FULL") }),
                  btnDefOvr)
          ]
      : [
          iconButtonInactive("ui/gameuiskin#icon_party_not_ready.svg", null, btnDefOvr)
          iconButtonInactive("ui/gameuiskin#icon_party_ready.svg", null, btnDefOvr)
        ]
  }
}

let mkClanSubmissionMessage = @(s) {
  size = FLEX_V
  valign = ALIGN_CENTER
  margin = btnMargin
  children = (s?.message ?? "") == ""
    ? iconButtonInactive(msgIcon, null, btnDefOvr)
    : iconButtonCommon(msgIcon, @() openSubmissionRequest(Contact(s.userId.tostring()).get(), s.message), btnDefOvr)
}

let searchIcon = {
  size = textInputHeight
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = {
    size = [searchIconSize, searchIconSize]
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#btn_search.svg:{searchIconSize}:{searchIconSize}")
  }
}

let nameInput = floatingTextInput(searchName, {
  ovr = {
    size = const [FLEX, textInputHeight]
    padding = [0, btnMargin]
  }
  mkEditContent = @(_, inputComp) {
    size = const [FLEX, textInputHeight]
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = btnMargin
    children = [
      searchIcon
      inputComp
    ]
  }
})

let resetBtn = {
  size = const [textInputHeight, textInputHeight]
  rendObj = ROBJ_SOLID
  color = tabBgColor
  children = closeWndBtn(@() searchName.set(""),
    { size = resetImgHeight, vplace = ALIGN_CENTER, hplace = ALIGN_CENTER })
}

let searchBlock = {
  size = const [FLEX, textInputHeight]
  flow = FLOW_HORIZONTAL
  gap
  children = [
    nameInput
    resetBtn
  ]
}

let askRejectAll = @() openMsgBox({
  text = loc("clans/submissions/askRejectAll")
  buttons = [
    { id = "cancel", isCancel = true }
    { text = loc("btn/reject_all_applications"), cb = rejectAllClanSubmissions }
  ]
})

function askApproveAll() {
  let freeSlots = (currentClan.get()?.maxMembers ?? 0) - (currentClan.get()?.users.len() ?? 0)
  openMsgBox({
    text = loc(freeSlots >= clanSubmissions.get().len() ? "clans/submissions/askApproveAll"
      : "clans/submissions/askApproveAll/moreThanFull")
    buttons = [
      { id = "cancel", isCancel = true }
      { text = loc("btn/approve_all_applications"), cb = approveAllClanSubmissions }
    ]
  })
}

const btnOvr = { ovr = { size = [defButtonMinWidth, textInputHeight] } }
let buttons = @() {
  watch = [isAllSubmissionsInProgress, clanRequestResponseInProgress, hasSpaceInClan, clanSubmissions, canCompleteClanRequest]
  size = [2 * defButtonMinWidth + gap, textInputHeight]
  flow = FLOW_HORIZONTAL
  gap
  valign = ALIGN_CENTER
  halign = ALIGN_RIGHT
  children = isAllSubmissionsInProgress.get() || clanRequestResponseInProgress.get().len() > 0
      ? spinner
    : clanSubmissions.get().len() <= 1 || !canCompleteClanRequest.get() ? null
    : [
        !hasSpaceInClan.get() ? null
          : textButtonCommon(utf8ToUpper(loc("btn/approve_all_applications")),
              askApproveAll,
              btnOvr)
        textButtonCommon(utf8ToUpper(loc("btn/reject_all_applications")),
          askRejectAll,
          btnOvr)
      ]
}

let buttonsRow = @() {
  size = [FLEX, textInputHeight]
  flow = FLOW_HORIZONTAL
  gap = bigGap
  children = [
    searchBlock
    buttons
  ]
}

let watchedFalse = Watched(false)
function mkClanSubmissionsPage() {
  let filtered = Computed(function() {
    if (searchNameDeffered.get() == "")
      return clanSubmissions.get()
    let searchToken = mkSearchTokenMemoized(searchNameDeffered.get())
    if (searchToken == "")
      return clanSubmissions.get()
    let res = []
    let contacts = allContacts.get()
    foreach (s in clanSubmissions.get()) {
      let uid = s.userId.tostring()
      if (uid in contacts && mkSearchTokenMemoized(getContactNick(contacts[uid])).contains(searchToken))
        res.append(s)
    }
    return res
  })
  let pageSubmissions = Computed(function() {
    let start = ROWS_IN_PAGE * curPage.get()
    return filtered.get().slice(start, start + ROWS_IN_PAGE)
  })
  let lastPage = Computed(@() max(0, ceil(filtered.get().len().tofloat() / ROWS_IN_PAGE).tointeger() - 1))
  function validateCurPage() {
    if (curPage.get() > lastPage.get())
      curPage.set(lastPage.get())
  }
  lastPage.subscribe(@(_) validateCurPage())
  return {
    key = pageSubmissions
    size = FLEX
    flow = FLOW_VERTICAL
    gap = bigGap
    onAttach = validateCurPage
    children = [
      buttonsRow
      @() {
        watch = [pageSubmissions, hasClanSubmissions]
        size = FLEX
        flow = FLOW_VERTICAL
        children = pageSubmissions.get().len() == 0
          ? mkNoContactsMsg(loc(hasClanSubmissions.get() ? "contacts/searchNotFound" : "clan/submissions/empty"))
          : pageSubmissions.get()
              .map(@(s, idx) mkContactRow(s.userId.tostring(), idx,
                watchedFalse,
                @() viewProfile(s.userId.tostring()),
                mkClanSubmissionResponse(s),
                mkClanSubmissionMessage(s),
                false))
      }
      {
        size = [FLEX, paginatorHeight]
        children = mkPaginator(curPage, lastPage)
      }
    ]
  }
}

return mkClanSubmissionsPage