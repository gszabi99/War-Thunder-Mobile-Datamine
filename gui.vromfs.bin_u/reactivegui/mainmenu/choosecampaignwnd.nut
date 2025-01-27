from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { can_use_debug_console } = require("%appGlobals/permissions.nut")
let { registerScene } = require("%rGui/navState.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { campaignsList, setCampaign, isAnyCampaignSelected } = require("%appGlobals/pServer/campaign.nut")
let { needFirstBattleTutorForCampaign, rewardTutorialMission, setSkippedTutor } = require("%rGui/tutorial/tutorialMissions.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { isInSquad, squadLeaderCampaign } = require("%appGlobals/squadState.nut")
let { unseenCampaigns, markAllCampaignsSeen } = require("unseenCampaigns.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { arrayByRows } = require("%sqstd/underscore.nut")

let isOpened = mkWatched(persist, "isOpened", false)
let close = @() isOpened(false)
let backBtn = backButton(close)

let needToForceOpen = keepref(Computed(@() isLoggedIn.value && !isAnyCampaignSelected.value
  && campaignsList.value.len() > 1))

let skipTutor = mkWatched(persist, "skipTutorDev", false)

isOpened.subscribe(@(v) v ? null : markAllCampaignsSeen())

let gap = hdpx(40)
let campImageFrameWidth = hdpxi(6)
let campBtnSize = [hdpxi(540), hdpxi(340)]
let campImageSize = [campBtnSize[0] - (campImageFrameWidth * 2), campBtnSize[1] - (campImageFrameWidth * 2)]

let campagnImages = {
  ships = { img = $"ui/bkg/login_bkg_s_2.avif", srcSize = [2700, 1080] }
  tanks = { img = $"ui/bkg/login_bkg_t_2.avif", srcSize = [2700, 1080] }
  air   = { img = $"ui/bkg/login_bkg_a_2.avif", srcSize = [800, 600] }
}

function mkResampledImgPath(imgCfg, destSize) {
  let { img, srcSize } = imgCfg
  foreach (n in [ srcSize[0], srcSize[1], destSize[0], destSize[1] ])
    assert(n != 0 && type(n) == "integer", "Bad params in mkResampledImgPath")
  let srcAR = 1.0 * srcSize[0] / srcSize[1]
  let destAR = 1.0 * destSize[0] / destSize[1]
  let resampleSize = (srcAR >= destAR)
    ? [ round(destSize[1] * srcAR).tointeger(), destSize[1] ]
    : [ destSize[0], round(destSize[0] / srcAR).tointeger() ]
  return $"{img}:{resampleSize[0]}:{resampleSize[1]}"
}

let mkCampaignImage = @(campaign) {
  size = flex()
  clipChildren = true
  children = {
    size = campImageSize
    rendObj = ROBJ_IMAGE
    keepAspect = KEEP_ASPECT_FILL
    imageHalign = ALIGN_CENTER
    imageValign = ALIGN_TOP
    image = campaign in campagnImages ? Picture(mkResampledImgPath(campagnImages[campaign], campImageSize))
      : null
  }
}

let mkCampaignName = @(name, sf) {
  rendObj = ROBJ_SOLID
  size = [flex(), SIZE_TO_CONTENT]
  padding = hdpx(12)
  vplace = ALIGN_BOTTOM
  halign = ALIGN_CENTER
  color = sf & S_HOVER ? 0x20143139 : 0x78000000
  children = {
    rendObj = ROBJ_TEXT
    text = name
  }.__update(fontSmall)
}

function onCampaignChange(campaign, onChangeCamp = null) {
  function applyCampaign() {
    onChangeCamp?()
    close()
    setCampaign(campaign)
  }

  if(skipTutor.get()) {
    setSkippedTutor(campaign)
    applyCampaign()
    return
  }

  if (!isAnyCampaignSelected.value)
    sendUiBqEvent("campaign_first_choice", { id = campaign })

  if (!isAnyCampaignSelected.value || !needFirstBattleTutorForCampaign(campaign)) {
    applyCampaign()
    return
  }

  if (!isInSquad.value) {
    openMsgBox({
      text = loc("msg/needTutorialToAccessCampaign")
      buttons = [
        { id = "cancel", isCancel = true }
        { text = loc("multiplayer/btnStart"), styleId = "PRIMARY", isDefault = true, cb = applyCampaign }
      ]
    })
    return
  }

  if (squadLeaderCampaign.value == campaign) {
    rewardTutorialMission(campaign)
    applyCampaign()
    return
  }

  openMsgBox({
    text = loc("msg/needTutorialToAccessCampaign/inSquad")
    buttons = [{ id = "ok", styleId = "PRIMARY", isDefault = true, cb = close }]
  })
}

function mkCampaignSkipTutorButton(){
  let listCampTutors = {}
  campaignsList.get().map(@(c) listCampTutors.__update({
    [c] = needFirstBattleTutorForCampaign(c)
  }))
  let isNeedSkipCheck = listCampTutors.findvalue(@(v) v)
  return !isNeedSkipCheck
    ? { watch = campaignsList }
    : {
      watch = [skipTutor, campaignsList]
      flow = FLOW_HORIZONTAL
      behavior = Behaviors.Button
      onClick = @() skipTutor.set(!skipTutor.get())
      hplace = ALIGN_RIGHT
      valign = ALIGN_CENTER
      gap = hdpx(10)
      children = [
        {
          size = [hdpx(40), hdpx(40)]
          rendObj = ROBJ_BOX
          fillColor = 0
          borderColor = 0x80FFFFFF
          borderWidth = 2
          children = skipTutor.get()
            ? {
              size = [hdpx(40), hdpx(40)]
              rendObj = ROBJ_IMAGE
              image = Picture($"ui/gameuiskin#check.svg:{hdpx(40)}:{hdpx(40)}:P")
              keepAspect = true
              color = 0xFF78FA78
            }
            : null
        }
        {
          rendObj = ROBJ_TEXT
          text = $"{loc("options/skip")} {loc("mainmenu/btnTutorial")}"
          hplace = ALIGN_CENTER
          sound = { click  = "click" }
        }.__update(fontSmall)
      ]
    }
}


function mkCampaignButton(campaign) {
  let stateFlags = Watched(0)
  let campaignImage = mkCampaignImage(campaign)
  return @() {
    watch = [stateFlags, unseenCampaigns]
    rendObj = ROBJ_SOLID
    size = campBtnSize
    padding = campImageFrameWidth
    color = 0XFF323232
    behavior = Behaviors.Button
    onClick = @() onCampaignChange(campaign)
    onElemState = @(v) stateFlags(v)
    transform = { scale = (stateFlags.value & S_ACTIVE) != 0 ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
    sound = { click  = "click" }

    children = [
      campaignImage
      mkCampaignName(utf8ToUpper(loc($"campaign/{campaign}")), stateFlags.value)
      campaign not in unseenCampaigns.get() ? null
        : priorityUnseenMark.__merge({ hplace = ALIGN_RIGHT, pos = [hdpx(-20), hdpx(20)] })
    ]
  }
}

function campaignsListUi(){
  let campaignBtns = campaignsList.get().map(mkCampaignButton)
  return {
    watch = campaignsList
    gap
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    children = arrayByRows(campaignBtns, 3).map(@(children) {
      flow = FLOW_HORIZONTAL
      gap
      children
    })
  }
}

let changeCampaignDesc = @() {
  watch = campaignsList
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = loc("changeCampaign/desc")
  color = 0xFFBCBCBC
}.__update(fontTinyAccented)

let content = {
  flow = FLOW_VERTICAL
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  halign = ALIGN_LEFT
  gap = hdpx(5)
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("changeCampaign")
    }.__update(fontMedium)
    changeCampaignDesc
    campaignsListUi
  ]
}

let chooseCampaignScene = bgShaded.__merge({
  key = {}
  size = flex()
  padding = saBordersRv
  gap
  function onAttach() {
    if (!isAnyCampaignSelected.value)
      sendUiBqEvent("campaign_first_choice_open")
  }
  children = [
    @() {
      watch = isAnyCampaignSelected
      size = [flex(), SIZE_TO_CONTENT]
      children = [
        isAnyCampaignSelected.get() ? backBtn : null
        can_use_debug_console.get() ? mkCampaignSkipTutorButton : null
      ]
    }
    content
  ]
  animations = wndSwitchAnim
})
registerScene("chooseCampaignWnd", chooseCampaignScene, close, isOpened)

if (needToForceOpen.value)
  isOpened(true)
needToForceOpen.subscribe(@(v) v ? isOpened(true) : null)

return {
  onCampaignChange
  chooseCampaignWnd = @() isOpened(true)
}