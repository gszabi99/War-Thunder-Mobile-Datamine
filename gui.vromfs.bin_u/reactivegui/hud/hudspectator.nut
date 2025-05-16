from "%globalsDarg/darg_library.nut" import *
let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { get_mplayer_by_id } = require("mission")
let { TouchCameraControl } = require("wt.behaviors")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { toggleShortcut } = require("%globalScripts/controls/shortcutActions.nut")
let { isHudAttached } = require("%appGlobals/clientState/hudState.nut")
let { battleCampaign } = require("%appGlobals/clientState/missionState.nut")
let { localMPlayerTeam } = require("%appGlobals/clientState/clientState.nut")
let { teamBlueColor, teamRedColor } = require("%rGui/style/teamColors.nut")
let { mkMenuButton } = require("%rGui/hud/menuButton.nut")
let { switchSpectatorTarget, getSpectatorTargetId } = require("guiSpectator")
let { tacticalMap } = require("components/tacticalMap.nut")
let { scoreBoard, needScoreBoard } = require("%rGui/hud/scoreBoard.nut")
let { capZonesList } = require("capZones/capZones.nut")
let hudTopMainLog = require("%rGui/hud/hudTopMainLog.nut")
let { isInSpectatorMode } = require("%rGui/hudState.nut")
let { mkMyPlaceUi, mkMyScoresUi, isPlaceVisible, isScoreVisible } = require("%rGui/hud/myScores.nut")
let { playerPlaceIconSize } = require("%rGui/components/playerPlaceIcon.nut")


let bgButtonColor = Color(32, 34, 38, 216)
let bgButtonColorPushed = Color(16, 18, 22, 216)
let borderColor = Color(192, 192, 192)
let borderColorPushed = Color(129, 128, 128, 229)
let textColor = Color(192, 192, 192)
let textColorPushed = Color(129, 128, 128, 229)

let buttonHeight = hdpx(82)
let buttonWidth = (1.5 * buttonHeight).tointeger()
let buttonImageSize = (0.9 * buttonHeight).tointeger()
let gap = hdpx(40)

let isAttached = Watched(false)
let needShowTapHint = mkWatched(persist, "needShowTapHint", true)

let watchedHeroId = mkWatched(persist, "watchedHeroId", -1)
eventbus_subscribe("WatchedHeroChanged", @(_) watchedHeroId(getSpectatorTargetId()))
eventbus_subscribe("toggleMpstatscreen", @(_) isInSpectatorMode.get() ? needShowTapHint.set(false) : null)

let watchedHero = Computed(@() isAttached.get() ? get_mplayer_by_id(watchedHeroId.get()) : null)
let watchedHeroName = Computed(@() watchedHero.value == null ? "" : watchedHero.value.name)
let watchedHeroColor = Computed(@() watchedHero.value == null ? 0xFFFFFFFF
  : watchedHero.value.team == localMPlayerTeam.value ? teamBlueColor : teamRedColor)
let hasTapHint = Computed(@() needShowTapHint.get() && (isPlaceVisible.get() || isScoreVisible.get()))

let switchTargetImage = Picture($"!ui/gameuiskin#spinnerListBox_arrow_up.svg:{buttonImageSize}:{buttonImageSize}")

let menuButton = mkMenuButton(1.0, { onClick = @() eventbus_send("openFlightMenuInRespawn", {}) })

let topLeft = {
  flow = FLOW_HORIZONTAL
  gap = hdpx(40)
  children = [
    menuButton
    tacticalMap
  ]
}

let isActive = @(sf) (sf & S_ACTIVE) != 0

function mkTargetButton(isNext = false) {
  let stateFlags = Watched(0)
  return @() {
    behavior = Behaviors.Button
    cameraControl = true
    watch = stateFlags
    size = [buttonWidth, buttonHeight]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    rendObj = ROBJ_SOLID
    color = isActive(stateFlags.value) ? bgButtonColorPushed
      : bgButtonColor
    onElemState = @(v) stateFlags(v)
    onClick = @() switchSpectatorTarget(isNext)
    children = {
      size = [buttonImageSize, buttonImageSize]
      rendObj = ROBJ_IMAGE
      image = switchTargetImage
      color = isActive(stateFlags.value) ? textColorPushed
        : Color(255, 255, 255)
      transform = { rotate = isNext ? 90 : -90 }
    }
  }
}

let prevTargetButton =  mkTargetButton()
let nextTargetButton = mkTargetButton(true)

let returnBtnSf = Watched(0)
let returnToHangarButton = @() {
  behavior = Behaviors.Button
  cameraControl = true
  watch = returnBtnSf
  size = [SIZE_TO_CONTENT, buttonHeight]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  padding = [0, gap]
  rendObj = ROBJ_BOX
  fillColor = isActive(returnBtnSf.value) ? bgButtonColorPushed
    : bgButtonColor
  borderColor = isActive(returnBtnSf.value) ? borderColorPushed
    : borderColor
  onElemState = @(v) returnBtnSf(v)
  onClick = @() eventbus_send("quitMission", {})
  children = @() {
    watch = battleCampaign
    rendObj = ROBJ_TEXT
    text = loc(getCampaignPresentation(battleCampaign.get()).returnToHangarLocId)
    color = isActive(returnBtnSf.value) ? textColorPushed
      : textColor
  }.__update(fontTiny)
}

let watchedHeroLabel = @() {
  watch = [ watchedHeroName, watchedHeroColor ]
  rendObj = ROBJ_TEXT
  text = watchedHeroName.value
  color = watchedHeroColor.value
  fontFx = FFT_GLOW
  fontFxFactor = hdpx(48)
  fontFxColor = 0xFF000000
}.__update(fontSmall)

let spectatorControlsBlock = {
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = hdpx(32)
  children = [
    watchedHeroLabel
    {
      flow = FLOW_HORIZONTAL
      gap
      children = [
        prevTargetButton
        returnToHangarButton
        nextTargetButton
      ]
    }
  ]
}

let hudTopCenter = @() {
  watch = [needScoreBoard, hasTapHint]
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = hdpx(10)
  children = [
    {
      children = [
        needScoreBoard.get() ? scoreBoard : null
        {
          pos = [playerPlaceIconSize * 2, 0]
          hplace = ALIGN_RIGHT
          flow = FLOW_HORIZONTAL
          children = [
            mkMyPlaceUi(1)
            mkMyScoresUi(1)
          ]
        }
      ]
    }
    !hasTapHint.get() ? null
      : {
          key = {}
          rendObj = ROBJ_TEXTAREA
          behavior = [Behaviors.TextArea, Behaviors.Button]
          maxWidth = hdpx(200)
          halign = ALIGN_CENTER
          onClick = @() isHudAttached.get() ? toggleShortcut("ID_MPSTATSCREEN") : eventbus_send("toggleMpstatscreen", {})
          sound = { click  = "click" }
          text = loc("hints/tap_for_stats")
          transform = {}
          animations = [{
            prop = AnimProp.scale, from = [1.0, 1.0], to = [1.1, 1.1], easing = InOutCubic
            duration = 2, play = true, loop = true
          }]
        }
    capZonesList(1)
  ]
}

return {
  key = {}
  onAttach = @() isAttached(true)
  onDetach = @() isAttached(false)
  size = saSize
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    {
      size = flex()
      behavior = TouchCameraControl
      touchMarginPriority = TOUCH_BACKGROUND
    }
    topLeft
    hudTopCenter
    hudTopMainLog
    spectatorControlsBlock
  ]
}
