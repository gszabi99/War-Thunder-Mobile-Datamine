from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%rGui/clans/clanCfg.nut" import gradesSettingscfg
from "%rGui/clans/clanPermissions.nut" import clanGrades
from "%rGui/clans/clanState.nut" import memberGrade, assignableGrades, canKickMember, canChangeMemberGrade,
  changeMemberGrade, kickMember
from "%rGui/clans/components/clanPropertyBtn.nut" import mkClanChangeBtn, propertyBtnDefHeight
from "%rGui/clans/components/chooseValueWnd.nut" import openChooseValueWnd
from "%rGui/clans/currentClanState.nut" import currentClan, myClanGrade
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/components/textButton.nut" import textButtonCommon
from "%rGui/mpStatistics/viewProfile.nut" import selectedPlayerForInfo


const btnWidth = hdpx(500)
let btnSize = [btnWidth, propertyBtnDefHeight]

let onKickMember = @(userId) openMsgBox({
  text = loc("clans/manage/kickConfirm")
  buttons = [
    { id = "cancel", isCancel = true }
    {
      id = "ok"
      styleId = "PRIMARY"
      isDefault = true
      function cb() {
        kickMember(userId)
        selectedPlayerForInfo.set(null)
      }
    }
  ]
})

function onChangeGrade(userId, grade) {
  if (!clanGrades.get()?[grade].unique) {
    changeMemberGrade(userId, grade)
    return
  }
  openMsgBox({
    text = loc("clans/manage/makeLeader")
    buttons = [
      { id = "cancel", isCancel = true }
      {
        id = "ok"
        styleId = "PRIMARY"
        function cb() {
          changeMemberGrade(userId, grade)
          selectedPlayerForInfo.set(null)
        }
      }
    ]
  })
}

function mkChangeGradeBtn(targetUserId) {
  let currentGradeName = Computed(@() memberGrade(currentClan.get(), targetUserId))
  let grades = Computed(@() assignableGrades(clanGrades.get(), myClanGrade.get(), currentClan.get(), targetUserId))

  return {
    children = mkClanChangeBtn(
      utf8ToUpper(loc(gradesSettingscfg.locTitle)),
      @() openChooseValueWnd(gradesSettingscfg.__merge({ values = grades.get() }), currentGradeName,
        @(v) v != currentGradeName.get() ? onChangeGrade(targetUserId, v) : null),
      btnSize)
  }
}

function mkManageSection(targetUserId) {
  let canKickUser = Computed(@() canKickMember(clanGrades.get(), myClanGrade.get(), currentClan.get(), targetUserId))
  let canChangeGrade = Computed(@() canChangeMemberGrade(clanGrades.get(), myClanGrade.get(), currentClan.get(), targetUserId))
  let kickBtn = textButtonCommon(utf8ToUpper(loc("clans/manage/kick")), @() onKickMember(targetUserId), { ovr = { size = btnSize } })

  return @() {
    watch = [canKickUser, canChangeGrade]
    size = FLEX_H
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = hdpx(30)
    children = [
      canKickUser.get()
        ? kickBtn
        : null
      canChangeGrade.get() ? mkChangeGradeBtn(targetUserId) : null
    ]
  }
}

return { mkManageSection }
