from "%globalsDarg/darg_library.nut" import *
let { send } = require("eventbus")
let { PRIVACY_POLICY_URL } = require("%appGlobals/legal.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%rGui/globals/timeToText.nut")
let { contentWidth } = require("optionsStyle.nut")
let { textButtonCommon, textButtonPrimary } = require("%rGui/components/textButton.nut")
let { mkLevelBg, maxLevelStarChar } = require("%rGui/components/levelBlockPkg.nut")
let { isInMenu } = require("%appGlobals/clientState/clientState.nut")
let { myUserName, myAvatar, myUserId } = require("%appGlobals/profileStates.nut")
let { premiumEndsAt } = require("%rGui/state/profilePremium.nut")
let { playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { premiumTextColor } = require("%rGui/style/stdColors.nut")

let DELETE_PROFILE_URL = "https://support.gaijin.net/hc/en-us/articles/200071071-Account-Deletion-Suspension-"

let avatarSize = hdpx(200)
let levelBlockSize = hdpx(60)
let imgBtnSize = hdpx(50).tointeger()
let borderColor = 0xFF000000
let borderWidth = hdpx(1)
let gap = hdpx(20)

let levelMark = {
  size = array(2, levelBlockSize)
  pos = array(2, (0.5 * levelBlockSize + 0.5).tointeger())
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  children = [
    mkLevelBg()
    @() {
      watch = playerLevelInfo
      rendObj = ROBJ_TEXT
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      text = playerLevelInfo.value.isMaxLevel ? maxLevelStarChar : playerLevelInfo.value.level
      pos = [0, -hdpx(2)]
    }.__update(fontSmall)
  ]
}

let avatar = {
  size = array(2, avatarSize + 2 * borderWidth)
  padding = borderWidth
  rendObj = ROBJ_BOX
  borderWidth
  borderColor = borderColor
  children = [
    @() {
      watch = myAvatar
      size = flex()
      rendObj = ROBJ_IMAGE
      image = Picture($"!ui/images/avatars/{myAvatar.value}.avif")
    }
    levelMark
  ]
}

let changeNameMsgBox = @() openMsgBox({
  text = loc("mainmenu/questionChangeName")
  buttons = [
    { id = "no", isCancel = true }
    { id = "yes", styleId = "PRIMARY", isDefault = true, cb = @() send("changeName", {}) }
  ]
})

let pnStateFlags = Watched(0)
let myUserNameBtn = {
  behavior = Behaviors.Button
  onClick = changeNameMsgBox
  onElemState = @(s) pnStateFlags(s)
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap
  children = [
    @() {
      watch = myUserName
      rendObj = ROBJ_TEXT
      text = myUserName.value
    }.__update(fontMedium)
    @() {
      watch = pnStateFlags
      size = array(2, imgBtnSize)
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#menu_edit.svg:{imgBtnSize}:{imgBtnSize}")
      transform = { scale = pnStateFlags.value & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
      transitions = [{ prop = AnimProp.scale, duration = 0.1, easing = InOutQuad }]
    }
  ]
}

let premiumAccountTxt = loc("charServer/entitlement/PremiumAccount")
let mkPremiumTimeLeftText = function() {
  let res = { watch = [ premiumEndsAt ] }
  let timeLeft = max(0, premiumEndsAt.value - serverTime.value)
  if (timeLeft == 0)
    return res
  res.watch.append(serverTime)
  return res.__update({
    rendObj = ROBJ_TEXT
    text = "".concat(premiumAccountTxt, colon, secondsToHoursLoc(timeLeft))
    color = premiumTextColor
  }, fontTiny)
}

let userInfoBlock = {
  flow = FLOW_HORIZONTAL
  gap
  children = [
    avatar
    {
      flow = FLOW_VERTICAL
      gap
      children = [
        myUserNameBtn
        @() {
          watch = myUserId
          rendObj = ROBJ_TEXT
          text = "".concat(loc("options/userId"), colon, myUserId.value)
        }.__update(fontTiny)
        mkPremiumTimeLeftText
      ]
    }
  ]
}

let buttonsWidthStyle = {
  ovr = {
    minWidth = hdpx(500)
  }
}

let bottomButtons = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  children = [
    textButtonPrimary(loc("mainmenu/support"), @() send("openUrl", { baseUrl = loc("url/support") }), buttonsWidthStyle)
    { size = flex() }
    textButtonPrimary(loc("options/personalData"), @() send("openUrl", { baseUrl = PRIVACY_POLICY_URL }))
  ]
}

let logoutMsgBox = @() openMsgBox({
  text = loc("mainmenu/questionChangePlayer")
  buttons = [
    { id = "no", isCancel = true }
    { id = "yes", styleId = "PRIMARY", isDefault = true, cb = @() send("logOutManually", {}) }
  ]
})

return @() {
  watch = isInMenu
  size = [contentWidth, flex()]
  flow = FLOW_VERTICAL
  children = [
    userInfoBlock
    { size = flex() }
    !isInMenu.value ? null : textButtonCommon(loc("mainmenu/btnChangePlayer"), logoutMsgBox, buttonsWidthStyle)
    { size = flex() }
    textButtonCommon(loc("options/delete_profile"), @() send("openUrl", { baseUrl = DELETE_PROFILE_URL }), buttonsWidthStyle)
    { size = flex() }
    bottomButtons
  ]
}