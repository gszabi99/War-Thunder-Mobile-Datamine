from "%globalsDarg/darg_library.nut" import *
let { object_to_json_string } = require("json")
let { can_use_debug_console } = require("%appGlobals/permissions.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { registerScene } = require("%rGui/navState.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { reset_campaigns, campaignInProgress, registerHandler
} = require("%appGlobals/pServer/pServerApi.nut")
let { backButton, backButtonHeight } = require("%rGui/components/backButton.nut")
let { campaignsList, setCampaign, isAnyCampaignSelected } = require("%appGlobals/pServer/campaign.nut")
let { needFirstBattleTutorForCampaign, rewardTutorialMission, setSkippedTutor } = require("%rGui/tutorial/tutorialMissions.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { openMsgBox, closeMsgBox } = require("%rGui/components/msgBox.nut")
let { modalWndHeaderWithClose } = require("%rGui/components/modalWnd.nut")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { isInSquad, squadLeaderCampaign } = require("%appGlobals/squadState.nut")
let { unseenCampaigns, markAllCampaignsSeen } = require("%rGui/mainMenu/unseenCampaigns.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { imageBtn } = require("%rGui/components/imageButton.nut")
let { unseenUnits, markUnitsSeen } = require("%rGui/unit/unseenUnits.nut")
let { headerGradientBg, doubleSideGradientPaddingY } = require("%rGui/components/gradientDefComps.nut")
let { simpleVerGrad } = require("%rGui/style/gradients.nut")
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { textColor, goodTextColor2, selectColor } = require("%rGui/style/stdColors.nut")
let { resetTimeout } = require("dagor.workcycle")


let colorBlack = 0xFF000000
let colorTransparent = 0x00000000
let checkboxBorderColor = 0x80FFFFFF
let panelGradColor = 0xCA000000
let panelDimColor = 0x52000000
let slantBorderColor = 0xE8FFFFFF
let RESET_MSG_UID = "resetCampaignMsg"
let iconSize = evenPx(40)
let bgResetCampaignSize = (iconSize * 1.5).tointeger()
let checkboxSize = hdpx(40)
let smallGap = hdpx(10)

let ANIM_DUR = 0.31
let CAMPAIGN_APPLY_DELAY = 0.03
let CAMPAIGN_APPLY_FALLBACK = ANIM_DUR + 0.1

let SLANT_PX = hdpxi(80)
let CENTER_X = (sw(100) * 0.30).tointeger()
let CENTER_W = (sw(100) * 0.40).tointeger()
let SIDE_W = (sw(100) * 0.50).tointeger()
let SLANT_PCT = SLANT_PX.tofloat() / CENTER_W * 100.0
let SLANT_BORDER_WIDTH = hdpxi(4)
let MASK_DOWNSAMPLE = 8
let MASK_SCALE_SIDE = 0.75
let MASK_SCALE_CENTER = 1.25
let MASK_SCALE_SIDE_INV = 1.0 / MASK_SCALE_SIDE
let MASK_SCALE_CENTER_INV = 1.0 / MASK_SCALE_CENTER
let CENTER_SHIFT_SIDE = ((CENTER_W * (1.0 - MASK_SCALE_SIDE)) * 0.5).tointeger()
let TITLE_BOTTOM_PAD = clamp((sh(100) * 0.02).tointeger(), hdpxi(60), hdpxi(104))

function mkMaskColor(alphaF) {
  let a = clamp((alphaF * 255.0 + 0.5).tointeger(), 0, 255)
  return (a << 24) | (a << 16) | (a << 8) | a
}

let centerPanelMask = mkBitmapPictureLazy(max(4, (CENTER_W / MASK_DOWNSAMPLE).tointeger()),
  max(4, (sh(100) / MASK_DOWNSAMPLE).tointeger()),
  function(params, bmp) {
    let { w, h } = params
    let maxSlant = SLANT_PX.tofloat() / MASK_DOWNSAMPLE

    for (local y = 0; y < h; y++) {
      let slantAtY = maxSlant * (h - 1 - y).tofloat() / (h - 1)

      let leftEdge = slantAtY
      let rightEdge = w - slantAtY

      for (local x = 0; x < w; x++) {
        let px = x.tofloat() + 0.5

        let leftAlpha = clamp(px - leftEdge, 0.0, 1.0)
        let rightAlpha = clamp(rightEdge - px, 0.0, 1.0)

        bmp.setPixel(x, y, mkMaskColor(min(leftAlpha, rightAlpha)))
      }
    }
  })

let isOpened = mkWatched(persist, "isOpened", false)
let close = @() isOpened.set(false)
let hoveredCampaign = mkWatched(persist, "chooseCampHover", null)
let pushedCampaign = mkWatched(persist, "chooseCampPushed", null)
let focusedAnimFinishedCampaign = mkWatched(persist, "chooseCampAnimFinished", null)
let chosenCampaign = mkWatched(persist, "chooseCampChosen", null)
let focusedCampaign = Computed(@() chosenCampaign.get() ?? pushedCampaign.get() ?? hoveredCampaign.get())

let backBtn = headerGradientBg([
  backButton(close, { stopMouse = true })
  {
    rendObj = ROBJ_TEXT
    text = loc("changeCampaignShort")
  }.__update(fontBigShaded)
])

let needToForceOpen = keepref(Computed(@() isLoggedIn.get() && !isAnyCampaignSelected.get()
  && campaignsList.get().len() > 1))

let skipTutor = mkWatched(persist, "skipTutorDev", false)

isOpened.subscribe(function(v) {
  if (v)
    return

  markAllCampaignsSeen()
  chosenCampaign.set(null)
})

function applyCampaign(campaign, onChangeCamp = null) {
  onChangeCamp?()
  close()
  setCampaign(campaign)
  if (needFirstBattleTutorForCampaign(campaign))
    markUnitsSeen(unseenUnits.get())
}

function onCampaignChange(campaign, onChangeCamp = null) {
  if (skipTutor.get()) {
    setSkippedTutor(campaign)
    applyCampaign(campaign, onChangeCamp)
    return
  }

  let anyCampSelected = isAnyCampaignSelected.get()
  if (!anyCampSelected || !needFirstBattleTutorForCampaign(campaign)) {
    if (!anyCampSelected)
      sendUiBqEvent("campaign_first_choice", { id = campaign })
    applyCampaign(campaign, onChangeCamp)
    return
  }

  if (!isInSquad.get()) {
    openMsgBox({
      text = loc("msg/needTutorialToAccessCampaign")
      buttons = [
        { id = "cancel", isCancel = true, cb = @() chosenCampaign.set(null) }
        {
          text = loc("multiplayer/btnStart")
          styleId = "PRIMARY"
          isDefault = true
          cb = @() applyCampaign(campaign, onChangeCamp)
        }
      ]
    })
    return
  }

  if (squadLeaderCampaign.get() == campaign) {
    rewardTutorialMission(campaign)
    applyCampaign(campaign, onChangeCamp)
    return
  }

  openMsgBox({
    text = loc("msg/needTutorialToAccessCampaign/inSquad")
    buttons = [{ id = "ok", styleId = "PRIMARY", isDefault = true, cb = close }]
  })
}

function tryApplyChosenCampaign() {
  let campaign = chosenCampaign.get()
  if (campaign != null)
    resetTimeout(focusedAnimFinishedCampaign.get() == campaign ? CAMPAIGN_APPLY_DELAY : CAMPAIGN_APPLY_FALLBACK,
      @() chosenCampaign.get() == campaign ? onCampaignChange(campaign) : null)
}

chosenCampaign.subscribe(@(_) tryApplyChosenCampaign())
focusedAnimFinishedCampaign.subscribe(@(_) tryApplyChosenCampaign())
focusedCampaign.subscribe(@(campaign) focusedAnimFinishedCampaign.get() != campaign
  ? focusedAnimFinishedCampaign.set(null)
  : null)

registerHandler("onResetCampaign", function onResetCampaignResult(res, context) {
  if ("error" in res)
    return openMsgBox({ text = object_to_json_string(res.error?.message ?? res.error, true) })

  close()
  setCampaign(context.campaign)
})

function onResetCampaign(campaign) {
  if (campaignInProgress.get() != null)
    return
  openMsgBox({
    uid = RESET_MSG_UID
    title = modalWndHeaderWithClose($"Reset campaign {campaign} progress", @() closeMsgBox(RESET_MSG_UID))
    text = $"Reset campaign {campaign}?"
    buttons = [
      {
        text = $"Reset {campaign}"
        styleId = "PRIMARY"
        isDefault = true
        cb = @() reset_campaigns([campaign], { id = "onResetCampaign", campaign })
      }
    ]
  })
}

let titleFont = fontLarge.__merge({
  fontFx = FFT_GLOW
  fontFxColor = colorBlack
  fontFxFactor = 32
})

function mkCampaignSkipTutorButton() {
  let listCampTutors = {}
  foreach (c in campaignsList.get())
    listCampTutors[c] <- needFirstBattleTutorForCampaign(c)

  let isNeedSkipCheck = listCampTutors.findvalue(@(v) v) != null
  return !isNeedSkipCheck
    ? { watch = campaignsList }
    : {
        watch = [skipTutor, campaignsList]
        size = [SIZE_TO_CONTENT, backButtonHeight + doubleSideGradientPaddingY * 2]
        flow = FLOW_HORIZONTAL
        behavior = Behaviors.Button
        sound = { click = "click" }
        onClick = @() skipTutor.set(!skipTutor.get())
        hplace = ALIGN_RIGHT
        valign = ALIGN_CENTER
        gap = smallGap
        stopMouse = true
        children = [
          {
            size = checkboxSize
            rendObj = ROBJ_BOX
            fillColor = colorTransparent
            borderColor = checkboxBorderColor
            borderWidth = 2
            children = skipTutor.get()
              ? {
                  size = checkboxSize
                  rendObj = ROBJ_IMAGE
                  image = Picture($"ui/gameuiskin#check.svg:{checkboxSize}:P")
                  keepAspect = true
                  color = goodTextColor2
                }
              : null
          }
          {
            rendObj = ROBJ_TEXT
            text = $"{loc("options/skip")} {loc("mainmenu/btnTutorial")}"
            hplace = ALIGN_CENTER
          }.__update(fontSmall)
        ]
      }
}

let underConstructionBg = {
  size = bgResetCampaignSize
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#under_construction_line.avif:{bgResetCampaignSize}:P")
  color = textColor
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    size = iconSize
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#btn_trash.svg:{iconSize}:P")
    keepAspect = true
  }
}

let mkPanelContent = @(campaign, imagePivot = [0.5, 0.5], idleScale = 1.025, hoverScale = 1.115) @() {
  watch = focusedCampaign
  size = FLEX
  children = [
    {
      size = FLEX
      rendObj = ROBJ_SOLID
      color = 0xFF57595B
    }
    {
      size = FLEX
      rendObj = ROBJ_IMAGE
      keepAspect = KEEP_ASPECT_FILL
      imageHalign = ALIGN_CENTER
      imageValign = ALIGN_CENTER
      image = Picture(getCampaignPresentation(campaign).img)
      transform = {
        pivot = imagePivot
        scale = focusedCampaign.get() == campaign
          ? [hoverScale, hoverScale]
          : [idleScale, idleScale]
      }
      transitions = [{ prop = AnimProp.scale, duration = ANIM_DUR, easing = OutQuad }]
    }
    @() {
      watch = can_use_debug_console
      size = [FLEX, (sh(100) * (can_use_debug_console.get() ? 0.25 : 0.17)).tointeger()]
      vplace = ALIGN_BOTTOM
      rendObj = ROBJ_IMAGE
      image = simpleVerGrad
      color = panelGradColor
    }
    @() {
      watch = focusedCampaign
      size = FLEX
      rendObj = ROBJ_SOLID
      color = focusedCampaign.get() != null && focusedCampaign.get() != campaign
        ? panelDimColor
        : colorTransparent
      transitions = [{ prop = AnimProp.color, duration = ANIM_DUR, easing = OutQuad }]
    }
  ]
}

let mkCenterBorderLines = @(panelScale) {
  size = FLEX
  rendObj = ROBJ_VECTOR_CANVAS
  color = slantBorderColor
  lineWidth = SLANT_BORDER_WIDTH / panelScale
  commands = [
    [VECTOR_INNER_LINE],
    [VECTOR_LINE, 0, 0, SLANT_PCT, 100],
    [VECTOR_LINE, 100, 0, 100 - SLANT_PCT, 100],
  ]
}

function mkTitleSlot(campaign, colX, colW, activeXShift = 0, getTitleXShift = null) {
  let slotXShift = Computed(@() focusedCampaign.get() == campaign ? activeXShift : 0)
  let titleXShift = Computed(@() getTitleXShift != null ? getTitleXShift(focusedCampaign.get()) : 0)

  return @() {
    watch = [slotXShift, titleXShift, unseenCampaigns, can_use_debug_console]
    pos = [colX, 0]
    size = [colW, sh(100)]
    halign = ALIGN_CENTER
    children = {
      vplace = ALIGN_BOTTOM
      pos = [0, -TITLE_BOTTOM_PAD]
      halign = ALIGN_CENTER
      transform = { translate = [slotXShift.get(), 0] }
      transitions = [{ prop = AnimProp.translate, duration = ANIM_DUR, easing = OutQuad }]
      children = {
        halign = ALIGN_CENTER
        flow = FLOW_VERTICAL
        gap = smallGap
        transform = { translate = [titleXShift.get(), 0] }
        transitions = [{ prop = AnimProp.translate, duration = ANIM_DUR, easing = OutQuad }]
        children = [
          @() {
            watch = [focusedCampaign, pushedCampaign]
            rendObj = ROBJ_TEXT
            text = utf8ToUpper(loc(getCampaignPresentation(campaign).headerLocId))
            color = pushedCampaign.get() == campaign ? selectColor : textColor
            transform = focusedCampaign.get() == campaign
              ? { translate = [0, -hdpxi(10)], scale = [1.075, 1.075] }
              : { translate = [0, 0], scale = [1.0, 1.0] }
            transitions = [
              { prop = AnimProp.translate, duration = ANIM_DUR, easing = OutQuad }
              { prop = AnimProp.scale, duration = ANIM_DUR, easing = OutQuad }
              { prop = AnimProp.color, duration = ANIM_DUR, easing = OutQuad }
            ]
          }.__update(titleFont)
          campaign not in unseenCampaigns.get() ? null
            : priorityUnseenMark.__merge({ hplace = ALIGN_RIGHT, pos = [hdpx(6), hdpx(-6)] })
          !can_use_debug_console.get() ? null
            : imageBtn(underConstructionBg, @() onResetCampaign(campaign), {
                size = bgResetCampaignSize
                touchMarginPriority = 1
                hplace = ALIGN_CENTER
              })
        ]
      }
    }
  }
}

let mkHitArea = @(campaign, xPos, width) {
  pos = [xPos, 0]
  size = [width, sh(100)]
  behavior = Behaviors.Button
  sound = { click = "click" }
  onClick = @() chosenCampaign.get() == null ? chosenCampaign.set(campaign) : null
  function onElemState(sf) {
    if (sf & S_HOVER)
      hoveredCampaign.set(campaign)
    else if (hoveredCampaign.get() == campaign)
      hoveredCampaign.set(null)

    if (sf & S_ACTIVE)
      pushedCampaign.set(campaign)
    else if (pushedCampaign.get() == campaign)
      pushedCampaign.set(null)
  }
}

function mkCenterPanel(leftCamp, centerCamp, rightCamp, centerImageX, centerImageW, centerContent) {
  let hovered = focusedCampaign.get()
  let isCenterHovered = hovered == centerCamp
  let isLeftHovered = hovered == leftCamp
  let isRightHovered = hovered == rightCamp
  let isSideHovered = isLeftHovered || isRightHovered

  let panelScale = isCenterHovered ? MASK_SCALE_CENTER
    : isSideHovered ? MASK_SCALE_SIDE
    : 1.0
  let panelScaleInv = isCenterHovered ? MASK_SCALE_CENTER_INV
    : isSideHovered ? MASK_SCALE_SIDE_INV
    : 1.0
  let panelShiftX = isLeftHovered ? CENTER_SHIFT_SIDE
    : isRightHovered ? -CENTER_SHIFT_SIDE
    : 0

  let onFocusedAnimFinish = @() focusedAnimFinishedCampaign.set(focusedCampaign.get())

  return {
    key = {}
    watch = focusedCampaign
    pos = [CENTER_X, 0]
    size = [CENTER_W, sh(100)]
    clipChildren = true
    children = [
      {
        size = FLEX
        rendObj = ROBJ_MASK
        image = centerPanelMask()
        clipChildren = true
        children = {
          pos = [centerImageX, 0]
          size = [centerImageW, sh(100)]
          transform = { pivot = [0.5, 0.5], scale = [panelScaleInv, 1.0] }
          transitions = [{ prop = AnimProp.scale, duration = ANIM_DUR, easing = OutQuad }]
          children = centerContent
        }
      }
      mkCenterBorderLines(panelScale)
    ]
    transform = { pivot = [0.5, 0.5], translate = [panelShiftX, 0], scale = [panelScale, 1.0] }
    transitions = [
      { prop = AnimProp.translate, duration = ANIM_DUR, easing = OutQuad, onFinish = onFocusedAnimFinish }
      { prop = AnimProp.scale, duration = ANIM_DUR, easing = OutQuad }
    ]
  }
}

function mkTriplePanelSelector(campaigns) {
  let leftCamp = campaigns[0]
  let centerCamp = campaigns[1]
  let rightCamp = campaigns[2]

  let rightX = sw(100) - SIDE_W
  let rightColX = CENTER_X + CENTER_W
  let rightColW = sw(100) - rightColX

  let leftContent = mkPanelContent(leftCamp, [0.0, 0.5])
  let rightContent = mkPanelContent(rightCamp, [1.0, 0.5])

  let centerImageW = (CENTER_W * MASK_SCALE_CENTER).tointeger()
  let centerImageX = ((CENTER_W - centerImageW) * 0.5).tointeger()
  let centerContent = mkPanelContent(centerCamp, [0.5, 0.5], 1.0, 1.075)

  return {
    size = FLEX
    clipChildren = true
    children = [
      {
        pos = [0, 0]
        size = [SIDE_W, sh(100)]
        clipChildren = true
        children = leftContent
      }
      {
        pos = [rightX, 0]
        size = [SIDE_W, sh(100)]
        clipChildren = true
        children = rightContent
      }
      @() mkCenterPanel(leftCamp, centerCamp, rightCamp, centerImageX, centerImageW, centerContent)
      mkHitArea(leftCamp, 0, CENTER_X)
      mkHitArea(centerCamp, CENTER_X, CENTER_W)
      mkHitArea(rightCamp, rightColX, rightColW)
      mkTitleSlot(leftCamp, 0, CENTER_X, CENTER_SHIFT_SIDE)
      mkTitleSlot(centerCamp, CENTER_X, CENTER_W, 0, @(hovered) hovered == leftCamp ? CENTER_SHIFT_SIDE
        : hovered == rightCamp ? -CENTER_SHIFT_SIDE
        : 0)
      mkTitleSlot(rightCamp, rightColX, rightColW, -CENTER_SHIFT_SIDE)
    ]
  }
}

let topBar = @() {
  watch = [isAnyCampaignSelected, can_use_debug_console]
  size = [FLEX, SIZE_TO_CONTENT]
  padding = saBordersRv
  zOrder = 5
  children = [
    isAnyCampaignSelected.get() ? backBtn : null
    can_use_debug_console.get() ? mkCampaignSkipTutorButton : null
  ]
}

let wndSwitchTrigger = {}
let chooseCampaignScene = {
  key = {}
  size = FLEX
  function onAttach() {
    if (!isAnyCampaignSelected.get())
      sendUiBqEvent("campaign_first_choice_open")
  }
  children = [
    @() {
      watch = campaignsList
      size = FLEX
      children = mkTriplePanelSelector(campaignsList.get())
    }
    topBar
  ]
  animations = [
    { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.3, easing = OutQuad, play = true, trigger = wndSwitchTrigger }
    { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.1, easing = OutQuad, playFadeOut = true, trigger = wndSwitchTrigger }
  ]
}

registerScene("chooseCampaignWnd", chooseCampaignScene, close, isOpened)

if (needToForceOpen.get())
  isOpened.set(true)
needToForceOpen.subscribe(@(v) v ? isOpened.set(true) : null)

return {
  onCampaignChange
  chooseCampaignWnd = @() isOpened.set(true)
}
