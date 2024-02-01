from "%globalsDarg/darg_library.nut" import *
let { registerScene } = require("%rGui/navState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { campaignsList, setCampaign, isAnyCampaignSelected } = require("%appGlobals/pServer/campaign.nut")
let { needFirstBattleTutorForCampaign, rewardTutorialMission } = require("%rGui/tutorial/tutorialMissions.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { isInSquad, squadLeaderCampaign } = require("%appGlobals/squadState.nut")

let isOpened = mkWatched(persist, "isOpened", false)
let close = @() isOpened(false)
let backBtn = backButton(close)

let needToForceOpen = keepref(Computed(@() isLoggedIn.value && !isAnyCampaignSelected.value
  && campaignsList.value.len() > 1))

let gap = hdpx(40)
let maxCampaignButtonsHeight = saSize[1] - gap - hdpx(60)

let imageRatio = 600.0 / 800
let campagnImages = {
  ships = "ui/bkg/login_bkg_s_2.avif"
  tanks = "ui/bkg/login_bkg_t_2.avif"
}

let mkCampaignImage = @(campaign) {
  size = flex()
  clipChildren = true
  children = {
    size = flex()
    rendObj = ROBJ_IMAGE
    keepAspect = KEEP_ASPECT_FILL
    imageHalign = ALIGN_CENTER
    imageValign = ALIGN_TOP
    image = campaign in campagnImages ? Picture(campagnImages[campaign])
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

function onCampaignButtonClick(campaign) {
  function applyCampaign() {
    close()
    setCampaign(campaign)
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

function mkCampaignButton(campaign, campaignW) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    rendObj = ROBJ_SOLID
    size = [campaignW, imageRatio * campaignW]
    padding = hdpx(6)
    color = 0XFF323232
    behavior = Behaviors.Button
    onClick = @() onCampaignButtonClick(campaign)
    onElemState = @(v) stateFlags(v)
    transform = { scale = (stateFlags.value & S_ACTIVE) != 0 ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
    sound = { click  = "click" }

    children = [
      mkCampaignImage(campaign),
      mkCampaignName(loc($"campaign/{campaign}"), stateFlags.value)
    ]
  }
}

function campaignsListUi() {
  let campaignCount = campaignsList.value.len()
  let campaignW = min(
    campaignCount <= 1 ? 0.5 * saSize[0]
      : ((saSize[0] - (campaignCount - 1) * gap) / campaignCount).tointeger(),
    maxCampaignButtonsHeight / imageRatio
  )
  return {
    watch = campaignsList
    size = [flex(), SIZE_TO_CONTENT]
    gap
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    children = campaignsList.value.map(
      @(c) mkCampaignButton(c, campaignW))
  }
}

let chooseCampaignScene = bgShaded.__merge({
  key = {}
  size = flex()
  padding = saBordersRv
  flow = FLOW_VERTICAL
  gap
  children = [
    @() {
      watch = isAnyCampaignSelected
      size = [flex(), SIZE_TO_CONTENT]
      children = [
        isAnyCampaignSelected.value ? backBtn : null
        {
          rendObj = ROBJ_TEXT
          text = loc(isAnyCampaignSelected.value ? "changeCampaign" : "chooseCampaign")
          hplace = ALIGN_CENTER
          vplace = ALIGN_CENTER
        }.__update(fontSmall)
      ]
    }
    {
      size = flex()
      children = campaignsListUi
    }
  ]
  animations = wndSwitchAnim
})

registerScene("chooseCampaignWnd", chooseCampaignScene, close, isOpened)

if (needToForceOpen.value)
  isOpened(true)
needToForceOpen.subscribe(@(v) v ? isOpened(true) : null)

return @() isOpened(true)