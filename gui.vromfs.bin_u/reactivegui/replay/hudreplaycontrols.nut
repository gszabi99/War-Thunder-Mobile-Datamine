from "%globalsDarg/darg_library.nut" import *
let { isPlayingReplay } = require("%rGui/hudState.nut")
let { toggleShortcut } = require("%globalScripts/controls/shortcutActions.nut")
let { mkGamepadHotkey } = require("%rGui/controls/shortcutSimpleComps.nut")
let { eventbus_subscribe } = require("eventbus")
let { get_mplayer_by_id } = require("mission")
let { getSpectatorTargetId } = require("guiSpectator")
let { get_replay_anchors } = require("replays")

let buttonSize = hdpxi(70)
let btnColor = 0xFFFFFFFF
let bltColorPressed = 0x4D4D4D4D
let unitNameSize = hdpxi(600)

let watchedHeroId = mkWatched(persist, "watchedHeroId", -1)
let watchedHero = Computed(@() get_mplayer_by_id(watchedHeroId.get()))
let watchedHeroName = Computed(@() watchedHero.get() == null ? "" : watchedHero.get().name)
let hasAncors = Watched(false)

eventbus_subscribe("WatchedHeroChanged", @(_) watchedHeroId.set(getSpectatorTargetId()))

let namePlate = {
  children = [
    @() {
      rendObj = ROBJ_TEXT
      watch = watchedHeroName
      size = [unitNameSize, buttonSize]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      text = watchedHeroName.get()
      fontFxColor = 0xFF000000
    }.__update(fontMedium)
    {
      rendObj = ROBJ_VECTOR_CANVAS
      size = [unitNameSize, buttonSize]
      halign = ALIGN_RIGHT
      commands = [[VECTOR_POLY, 0, 0, 100, 0, 100, 100, 0, 100]]
      fillColor = 0x00000000
    }
  ]
}

function makeArrow(isLeft, shortcutId) {
  let stateFlags = Watched(0)
  return {
    behavior = Behaviors.Button
    cameraControl = true
    hotkeys = mkGamepadHotkey(shortcutId)
    onClick = @() toggleShortcut(shortcutId)
    onElemState = @(v) stateFlags.set(v)
    children = @() {
      watch = stateFlags
      rendObj = ROBJ_IMAGE
      size = [buttonSize, buttonSize]
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      image = Picture($"ui/gameuiskin#hud_replay_switch_unit.svg:{buttonSize}:{buttonSize}")
      keepAspect = KEEP_ASPECT_FIT
      transform = { rotate = isLeft ? 0 : 180 }
      color = stateFlags.get() & S_ACTIVE ? bltColorPressed : btnColor
    }
  }
}

let prevAnchor = makeArrow(true, "ID_REPLAY_PREVIOUS_ANCHOR")
let nextAnchor = makeArrow(false, "ID_REPLAY_NEXT_ANCHOR")

let rewindControls = {
  size = SIZE_TO_CONTENT
  pos = [pw(-20), ph(5)]
  rendObj = ROBJ_VECTOR_CANVAS
  vplace = ALIGN_TOP
  hplace = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  gap = hdpx(40)
  children = [
    prevAnchor
    nextAnchor
  ]
  fillColor = 0x00000000
  commands = [[VECTOR_POLY, 0, 0, 100, 0, 100, 100, 0, 100]]
}

let prevUnit = makeArrow(true, "ID_PREV_PLANE")
let nextUnit = makeArrow(false, "ID_NEXT_PLANE")

function makeButton(label, shortcutId) {
  let stateFlags = Watched(0)
  return {
    behavior = Behaviors.Button
    cameraControl = true
    hotkeys = mkGamepadHotkey(shortcutId)
    onClick = @() toggleShortcut(shortcutId)
    onElemState = @(v) stateFlags.set(v)
    children = [
      @() {
        watch = stateFlags
        rendObj = ROBJ_TEXT
        size = [unitNameSize * 0.5, buttonSize]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        text = label
        color = stateFlags.get() & S_ACTIVE ? bltColorPressed : btnColor
      }.__update(fontMedium)
      @() {
        watch = stateFlags
        rendObj = ROBJ_VECTOR_CANVAS
        size = [unitNameSize  * 0.5, buttonSize]
        halign = ALIGN_RIGHT
        commands = [[VECTOR_POLY, 0, 0, 100, 0, 100, 100, 0, 100]]
        fillColor = 0x00000000
        color = stateFlags.get() & S_ACTIVE ? bltColorPressed : btnColor
      }
    ]
  }
}

let playersView = makeButton("Player's view", "ID_TOGGLE_FOLLOWING_CAMERA")
let defaultView = makeButton("Default view", "ID_CAMERA_DEFAULT")

let heroControls = {
  size = SIZE_TO_CONTENT
  pos = [0, ph(-20)]
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  children = [
    prevUnit
    {
      flow = FLOW_VERTICAL
      children = [
        namePlate
        {
          flow = FLOW_HORIZONTAL
          children = [
            playersView
            defaultView
          ]
        }
      ]
    }
    nextUnit
  ]
}

let hudReplayControls = @() {
  key = "replay-controls"
  watch = [ isPlayingReplay, watchedHero, hasAncors ]
  size = flex()
  function onAttach() {
    hasAncors(get_replay_anchors().len() > 0)
  }
  children = isPlayingReplay.get()
    ? [
      hasAncors.get() ? rewindControls : null
      heroControls
    ] : null
}

return hudReplayControls