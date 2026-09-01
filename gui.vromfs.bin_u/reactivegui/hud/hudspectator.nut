from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_game_params_blk
from "eventbus" import eventbus_subscribe, eventbus_send
from "guiSpectator" import switchSpectatorTarget, getSpectatorTargetId
from "mission" import get_mplayer_by_id
from "wt.behaviors" import TouchCameraControl
from "%globalScripts/controls/shortcutActions.nut" import toggleShortcut
from "%appGlobals/clientState/clientState.nut" import localMPlayerTeam
from "%appGlobals/clientState/hudState.nut" import isHudAttached
from "%appGlobals/clientState/missionState.nut" import battleCampaign
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%rGui/components/playerPlaceIcon.nut" import playerPlaceIconSize
from "%rGui/hud/capZones/capZones.nut" import capZonesList
from "%rGui/hud/components/tacticalMap.nut" import tacticalMap
from "%rGui/hud/hudEventManager.nut" import subscribeHudEvent
import "%rGui/hud/hudTopMainLog.nut" as hudTopMainLog
from "%rGui/hud/menuButton.nut" import mkMenuButton
from "%rGui/hud/myScores.nut" import mkMyPlaceUi, mkMyScoresUi, isPlaceVisible, isScoreVisible
from "%rGui/hud/scoreBoard.nut" import scoreBoardType, scoreBoardCfgByType, needScoreBoard
from "%rGui/hudState.nut" import isInSpectatorMode, isPlayingReplay
from "%rGui/missionState.nut" import isGtBattleRoyale
from "%rGui/respawn/spawnScore.nut" import spawnScoreBalance
from "%rGui/style/hudColors.nut" import hudWhiteColor, hudGraphiteColor, hudCharcoalColor, hudPearlGrayColor,
  hudAshGrayColor
from "%rGui/style/teamColors.nut" import teamBlueColor, teamRedColor


let bgButtonColor = hudGraphiteColor
let bgButtonColorPushed = hudCharcoalColor
let borderColor = hudPearlGrayColor
let borderColorPushed = hudAshGrayColor
let textColor = hudPearlGrayColor
let textColorPushed = hudAshGrayColor

const buttonHeight = hdpx(82)
let buttonWidth = (1.5 * buttonHeight).tointeger()
let buttonImageSize = (0.9 * buttonHeight).tointeger()
const gap = hdpx(40)

let isAttached = Watched(false)
let needShowTapHint = mkWatched(persist, "needShowTapHint", true)

let watchedHeroId = mkWatched(persist, "watchedHeroId", -1)
subscribeHudEvent("WatchedHeroChanged", @(_) watchedHeroId.set(getSpectatorTargetId()))
eventbus_subscribe("toggleMpstatscreen", @(_) isInSpectatorMode.get() && !isPlayingReplay.get() ? needShowTapHint.set(false) : null)

let watchedHero = Computed(@() isAttached.get() ? get_mplayer_by_id(watchedHeroId.get()) : null)
let watchedHeroName = Computed(@() watchedHero.get() == null ? "" : watchedHero.get().name)
let watchedHeroColor = Computed(@() watchedHero.get() == null ? hudWhiteColor
  : watchedHero.get().team == localMPlayerTeam.get() ? teamBlueColor : teamRedColor)
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

let topRight = {
  hplace = ALIGN_RIGHT
  children = spawnScoreBalance
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
    color = isActive(stateFlags.get()) ? bgButtonColorPushed
      : bgButtonColor
    onElemState = @(v) stateFlags.set(v)
    onClick = @() switchSpectatorTarget(isNext)
    children = {
      size = [buttonImageSize, buttonImageSize]
      rendObj = ROBJ_IMAGE
      image = switchTargetImage
      color = isActive(stateFlags.get()) ? textColorPushed
        : hudWhiteColor
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
  size = const [SIZE_TO_CONTENT, buttonHeight]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  padding = const [0, gap]
  rendObj = ROBJ_BOX
  fillColor = isActive(returnBtnSf.get()) ? bgButtonColorPushed
    : bgButtonColor
  borderColor = isActive(returnBtnSf.get()) ? borderColorPushed
    : borderColor
  onElemState = @(v) returnBtnSf.set(v)
  onClick = @() eventbus_send("quitMission", {})
  children = @() {
    watch = battleCampaign
    rendObj = ROBJ_TEXT
    text = loc(getCampaignPresentation(battleCampaign.get()).returnToHangarLocId)
    color = isActive(returnBtnSf.get()) ? textColorPushed
      : textColor
  }.__update(fontTiny)
}

let watchedHeroLabel = @() {
  watch = [ watchedHeroName, watchedHeroColor ]
  rendObj = ROBJ_TEXT
  text = watchedHeroName.get()
  color = watchedHeroColor.get()
}.__update(fontSmallShaded)

let spectatorControlsBlock = {
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = hdpx(32)
  children = [
    watchedHeroLabel
    @() {
      watch = isGtBattleRoyale
      flow = FLOW_HORIZONTAL
      gap
      children = get_game_params_blk()?.allowSpectatingEnemiesInLastManStanding == false && isGtBattleRoyale.get() ? returnToHangarButton
          : [
            prevTargetButton
            returnToHangarButton
            nextTargetButton
          ]
    }
  ]
}

let hudTopCenter = @() {
  watch = [needScoreBoard, hasTapHint, scoreBoardType]
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = hdpx(10)
  children = [
    {
      children = [
        needScoreBoard.get() ? scoreBoardCfgByType?[scoreBoardType.get()].comp : null
        !scoreBoardCfgByType?[scoreBoardType.get()].addMyScores ? null
          : {
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
  onAttach = @() isAttached.set(true)
  onDetach = @() isAttached.set(false)
  size = saSize
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    {
      size = FLEX
      behavior = TouchCameraControl
      touchMarginPriority = TOUCH_BACKGROUND
    }
    topLeft
    topRight
    hudTopCenter
    hudTopMainLog
    spectatorControlsBlock
  ]
}
