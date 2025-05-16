from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { object_to_json_string } = require("json")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { can_use_debug_console } = require("%appGlobals/permissions.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { registerScene } = require("%rGui/navState.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { reset_campaigns, campaignInProgress, registerHandler, copy_campaign_progress
} = require("%appGlobals/pServer/pServerApi.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { campaignsList, setCampaign, isAnyCampaignSelected } = require("%appGlobals/pServer/campaign.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { needFirstBattleTutorForCampaign, rewardTutorialMission, setSkippedTutor } = require("%rGui/tutorial/tutorialMissions.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { openMsgBox, closeMsgBox } = require("%rGui/components/msgBox.nut")
let { modalWndHeaderWithClose } = require("%rGui/components/modalWnd.nut")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { isInSquad, squadLeaderCampaign } = require("%appGlobals/squadState.nut")
let { unseenCampaigns, markAllCampaignsSeen } = require("unseenCampaigns.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { imageBtn } = require("%rGui/components/imageButton.nut")
let { unseenUnits, markUnitsSeen } = require("%rGui/unit/unseenUnits.nut")

let iconSize = evenPx(40)
let RESET_MSG_UID = "resetCampaignMsg"

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
  ships_new = { img = $"ui/bkg/login_bkg_s_2.avif", srcSize = [2700, 1080] }
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
    if (needFirstBattleTutorForCampaign(campaign))
      markUnitsSeen(unseenUnits.get())
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

registerHandler("onResetCampaign",
  function onLvlPurchase(res, context) {
    if ("error" in res) {
      openMsgBox({ text = object_to_json_string(res.error?.message ?? res.error, true) })
      return
    }
    let { campaign } = context
    close()
    setCampaign(campaign)
  })

function onResetCampaign(campaign) {
  if (campaignInProgress.get() != null)
    return

  let { campaignCfg = {} } = serverConfigs.get()
  let { convertFrom = "" } = campaignCfg?[campaign]
  let campGroup = [convertFrom]
  foreach(c, cfg in campaignCfg)
    if (cfg?.convertFrom == campaign)
      campGroup.append(c)
  let otherCamps = campGroup.filter(@(c) c != campaign && campaignsList.get().contains(c))

  let otherNames = comma.join(otherCamps)
  let buttons = [
    { text = $"Reset {campaign}", styleId = "PRIMARY", isDefault = true,
      cb = @() reset_campaigns([campaign], { id = "onResetCampaign", campaign })
    }
  ]
  if (campaignsList.get().contains(convertFrom))
    buttons.append({ text = $"Fill by {convertFrom}",
      styleId = "PRIMARY",
      cb = @() copy_campaign_progress(campaign, convertFrom, { id = "onResetCampaign", campaign }),
    })
  if (otherCamps.len() > 0)
    buttons.append({ text = "Reset with linked",
      cb = @() reset_campaigns([campaign].extend(otherCamps), { id = "onResetCampaign", campaign })
    })
  openMsgBox({
    uid = RESET_MSG_UID
    title = modalWndHeaderWithClose($"Reset campaign {campaign} progress", @() closeMsgBox(RESET_MSG_UID))
    text = otherCamps.len() == 0 ? $"Reset campaign {campaign}?"
      : $"Campaign {campaign} has linked campaigns:\n{otherNames}\nYou can reset them all at once."
    buttons
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

let bgResetCampaignSize = iconSize * 1.5

let underConstructionBg = {
  size = [bgResetCampaignSize, bgResetCampaignSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#under_construction_line.avif:{bgResetCampaignSize}:{bgResetCampaignSize}:P")
  color = 0xFFFFFFFF
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    size = [iconSize, iconSize]
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#btn_trash.svg:{iconSize}:{iconSize}:P")
    keepAspect = true
  }
}


let mkResetCampaignBtn = @(campaign) imageBtn(underConstructionBg,
  @() onResetCampaign(campaign),
  {
    size = [bgResetCampaignSize, bgResetCampaignSize]
    touchMarginPriority = 1
    hplace = ALIGN_RIGHT
  })

function mkCampaignButton(campaign) {
  let stateFlags = Watched(0)
  let campaignImage = mkCampaignImage(campaign)
  return @() {
    watch = [stateFlags, unseenCampaigns, can_use_debug_console]
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
      mkCampaignName(utf8ToUpper(loc(getCampaignPresentation(campaign).headerLocId)), stateFlags.value)
      campaign not in unseenCampaigns.get() ? null
        : priorityUnseenMark.__merge({ hplace = ALIGN_RIGHT, pos = [hdpx(-20), hdpx(20)] })
      !can_use_debug_console.get() ? null
        : mkResetCampaignBtn(campaign)
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