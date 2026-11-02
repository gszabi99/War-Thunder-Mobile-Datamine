from "%globalsDarg/darg_library.nut" import *
from "math" import ceil
from "%rGui/clans/clanSubmissionsState.nut" import approveClanSubmission, rejectClanSubmission,
  clanRequestResponseInProgress, canCompleteClanRequest, clanSubmissions
from "%rGui/components/gradientDefComps.nut" import headerHeightInSafeArea, headerMargin
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/components/paginator.nut" import mkPaginator, paginatorHeight
from "%rGui/components/textButton.nut" import iconButtonCommon, iconButtonInactive
from "%rGui/contacts/contact.nut" import Contact, getContactNick
from "%rGui/contacts/contactInfoPkg.nut" import gap, rowHeight
from "%rGui/contacts/mkContactListScene.nut" import mkNoContactsMsg
import "%rGui/contacts/mkContactRow.nut" as mkContactRow
from "%rGui/mpStatistics/viewProfile.nut" import viewProfile


const btnIconSize = evenPx(50)
const listHeight = saSize[1] - headerHeightInSafeArea - headerMargin - paginatorHeight
const ROWS_IN_PAGE = (listHeight / rowHeight).tointeger()
const btnMargin = hdpx(8)
const msgIcon = "ui/gameuiskin#icon_clan_letter.svg"

let curPage = mkWatched(persist, "curPage", 0)

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
    {
      id = "reject"
      styleId = "PRIMARY"
      isDefault = true
      cb = @() rejectClanSubmission(userId)
    }
  ]
})

let openSubmissionRequest = @(contact, text) openMsgBox({
  text
  title = loc("clans/manage/requestTitle", { user = getContactNick(contact) })
})

function mkClanSubmissionResponse(s) {
  let inactiveButtons = [
    iconButtonInactive("ui/gameuiskin#icon_party_not_ready.svg", null, btnDefOvr)
    iconButtonInactive("ui/gameuiskin#icon_party_ready.svg", null, btnDefOvr)
  ]
  let activeButtons = [
    iconButtonCommon("ui/gameuiskin#icon_party_not_ready.svg", @() askRejectSubmission(s.userId), btnDefOvr)
    iconButtonCommon("ui/gameuiskin#icon_party_ready.svg", @() approveClanSubmission(s.userId), btnDefOvr)
  ]

  return @() {
    watch = [clanRequestResponseInProgress, canCompleteClanRequest]
    size = FLEX_V
    flow = FLOW_HORIZONTAL
    gap
    margin = hdpx(8)
    children = (!canCompleteClanRequest.get() || s.userId in clanRequestResponseInProgress.get())
      ? inactiveButtons
      : activeButtons
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

let watchedFalse = Watched(false)
function mkClanSubmissionsPage() {
  let pageSubmissions = Computed(function() {
    let start = ROWS_IN_PAGE * curPage.get()
    return clanSubmissions.get().slice(start, start + ROWS_IN_PAGE)
  })
  let lastPage = Computed(@() max(0, ceil(clanSubmissions.get().len().tofloat() / ROWS_IN_PAGE).tointeger() - 1))
  function validateCurPage() {
    if (curPage.get() > lastPage.get())
      curPage.set(lastPage.get())
  }
  lastPage.subscribe(@(_) validateCurPage())
  return {
    key = pageSubmissions
    size = FLEX
    flow = FLOW_VERTICAL
    gap
    onAttach = validateCurPage
    children = [
      @() {
        watch = pageSubmissions
        size = FLEX
        flow = FLOW_VERTICAL
        children = pageSubmissions.get().len() == 0 ? mkNoContactsMsg(loc("clan/submissions/empty"))
          : pageSubmissions.get()
              .map(@(s, idx) mkContactRow(s.userId.tostring(), idx,
                watchedFalse,
                @() viewProfile(s.userId.tostring()),
                mkClanSubmissionResponse(s),
                mkClanSubmissionMessage(s)))
      }
      {
        size = [FLEX, paginatorHeight]
        children = mkPaginator(curPage, lastPage)
      }
    ]
  }
}

return mkClanSubmissionsPage