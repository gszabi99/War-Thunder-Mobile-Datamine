from "%globalsDarg/darg_library.nut" import *
from "%rGui/hudTuning/hudTuningConsts.nut" import *
let { get_time_speed, get_replay_info,
  is_replay_paused = @() !require("replays")?.is_replay_playing(),
  get_replay_anchors, move_to_anchor, is_anchor_loading
} = require("replays")
let { get_mission_time, get_mplayers_list, GET_MPLAYERS_LIST } = require("mission")
let { getSpectatorTargetId, switchSpectatorTargetById } = require("guiSpectator")
let { is_replay_markers_enabled } = require("hudState")
let { eventbus_subscribe } = require("eventbus")
let { register_command } = require("console")
let { abs, round } = require("math")
let { format } =  require("string")
let { resetTimeout, setInterval, clearTimer } = require("dagor.workcycle")
let { TouchScreenStick } = require("wt.behaviors")
let { Point2 } = require("dagor.math")
let { toggleShortcut } = require("%globalScripts/controls/shortcutActions.nut")
let { getUnitLocId, unitClassFontIcons } = require("%appGlobals/unitPresentation.nut")
let { isHudVisible } = require("%appGlobals/clientState/clientState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let getAvatarImage = require("%appGlobals/decorators/avatars.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { genBotDecorators } = require("%appGlobals/botUtils.nut")
let { getUnitTagsCfg } = require("%appGlobals/unitTags.nut")
let { isReplayPlayerOptionsOpen } = require("%rGui/cursorSharedStates.nut")
let { textColor, selectColor, premiumTextColor, collectibleTextColor } = require("%rGui/style/stdColors.nut")
let { teamBlueLightColor, teamRedLightColor, mySquadLightColor } = require("%rGui/style/teamColors.nut")
let { mkMenuButton } = require("%rGui/hud/menuButton.nut")
let { curUnitHudTuning } = require("%rGui/hudTuning/hudTuningBattleState.nut")
let { mkPublicInfo, refreshPublicInfo } = require("%rGui/contacts/contactPublicInfo.nut")
let { opacityTransition } = require("%rGui/components/selectedLine.nut")
let { mkBotInfo } = require("%rGui/mpStatistics/botsInfoState.nut")
let { mkGradRankSmall } = require("%rGui/components/gradTexts.nut")
let { simpleHorGradInv } = require("%rGui/style/gradients.nut")
let { mkButtonHoldTooltip } = require("%rGui/tooltip.nut")
let { isPlayingReplay } = require("%rGui/hudState.nut")


let optImgSize = hdpx(50)
let optBtnSize = hdpx(80)
let optBtnGap = hdpx(20)

let TIME_TO_UPDATE_CONTROLLS = 0.5
let limitDistanceStick = hdpx(20)
let stickRadius = sw(100)

let bgColor = 0xC0000000
let cellTextColor = 0xFFFFFFFF
let unitDeadTextColor = 0x28282828

let rowHeight = hdpx(68)
let rowWidth = hdpx(400)
let avatarHeight = rowHeight - hdpx(2)
let squadLabelWidth = hdpx(34)
let squadLabelHeight = hdpx(41)

let startedReplayPath = keepref(Watched(""))

let stickDelta = Watched(Point2(0, 0))

let isReplaysManageButtonOn = Watched(true)
let isPlayerOptionsOpen = isReplayPlayerOptionsOpen
let needShowPlayerOptions = Watched(true)

let replayTimeSpeed = Watched(0.0)
let replayTimeTotal = Watched(0)
let replayCurrentTime = Watched(0)

let selectedPlayerIdx = Watched(-1)
let replayMplayersList = Watched([])
let replayAnchors = Watched([])

let isPauseOptActive = Watched(false)
let isMarkersOptActive = Watched(true)
let isFreeCameraOptActive = Watched(true)
let isHudVisibilityOptActive = Watched(true)
let isPlayersListOptActive = Watched(false)

let replayMplayersListSorted = Computed(function() {
  let players = replayMplayersList.get()
  let localPlayer = players.findvalue(@(p) p.isLocal)
  let localTeam = localPlayer?.team ?? 1
  let alliesTeam = []
  let enemiesTeam = []
  foreach (player in players)
    if (player.team == localTeam)
      alliesTeam.append(player)
    else
      enemiesTeam.append(player)
  return { alliesTeam, enemiesTeam }
})

let replayCurrentTimeRounded = Computed(@() round(replayCurrentTime.get()).tointeger())
let replayTimeProgress = Computed(@() (replayTimeTotal.get() > 0)
  ? (100.0 * replayCurrentTime.get()) / replayTimeTotal.get()
  : 0)

let replayAnchorsCount = Computed(@() replayAnchors.get().len())
let curAnchorIdx = Computed(function() {
  if (replayAnchorsCount.get() == 0)
    return -1
  return (replayAnchors.get().findindex(@(v) v > (replayCurrentTimeRounded.get() * 1000)) ?? replayAnchorsCount.get()) - 1
})

let moveToAnchor = @(idx) is_anchor_loading() ? null : move_to_anchor(idx)

function moveToNextAnchor(directionIdx) {
  let nextIdx = curAnchorIdx.get() + directionIdx < 0 ? 0 : curAnchorIdx.get() + directionIdx
  if (nextIdx >= replayAnchorsCount.get())
    return

  moveToAnchor(nextIdx)
}

let replayVideoControlsList = [
  {
    shortcutId = ""
    img = "ui/gameuiskin#replay_forward.svg"
    locId = "mainmenu/replay/nav/prev"
    iconOvr = { transform = { rotate = 180 } }
    isLocked = Computed(@() curAnchorIdx.get() < 0)
    isHidden = Computed(@() replayAnchorsCount.get() == 0)
    cb = @() moveToNextAnchor(-1)
  },
  {
    shortcutId = "ID_REPLAY_SLOWER"
    img = "ui/gameuiskin#replay_speed.svg"
    locId = "mainmenu/replay/speed/slow"
    iconOvr = { transform = { rotate = 180 } }
  },
  {
    shortcutId = "ID_REPLAY_PAUSE"
    img = "ui/gameuiskin#replay_pause.svg"
    activeImg = "ui/gameuiskin#replay_play.svg"
    locId = "mainmenu/replay/playback"
    isActive = isPauseOptActive
  },
  {
    shortcutId = "ID_REPLAY_FASTER"
    img = "ui/gameuiskin#replay_speed.svg"
    locId = "mainmenu/replay/speed/fast"
  },
  {
    shortcutId = ""
    img = "ui/gameuiskin#replay_forward.svg"
    locId = "mainmenu/replay/nav/next"
    isLocked = Computed(@() curAnchorIdx.get() + 1 >= replayAnchorsCount.get())
    isHidden = Computed(@() replayAnchorsCount.get() == 0)
    cb = @() moveToNextAnchor(1)
  }
]





let replayHudControlsList = [
  {
    shortcutId = ""
    img = "ui/gameuiskin#hud_tank_arrow_segment.svg"
    locId = "hudTuning/toggle/desc/hide"
    isActive = isPlayerOptionsOpen
    isDisabled = Computed(@() !isPlayerOptionsOpen.get())
    iconOvr = { transform = { rotate = 180 } }
  },
  {
    shortcutId = "ID_HIDE_HUD"
    img = "ui/gameuiskin#hud_replay_toggle.svg"
    locId = "mainmenu/replay/hud"
    isActive = isHudVisibilityOptActive
    isDisabled = Computed(@() !isHudVisibilityOptActive.get())
  },
  {
    shortcutId = ""
    img = "ui/gameuiskin#icon_contacts.svg"
    locId = "mainmenu/replay/players"
    isActive = isPlayersListOptActive
    isDisabled = Computed(@() !isPlayersListOptActive.get())
  },
  {
    shortcutId = "ID_REPLAY_SHOW_MARKERS"
    img = "ui/gameuiskin#map_respawn_marker.svg"
    locId = "mainmenu/replay/markers"
    isActive = isMarkersOptActive
    isDisabled = Computed(@() !isMarkersOptActive.get())
  },
  {
    shortcutId = ["ID_CAMERA_DEFAULT", "ID_TOGGLE_FOLLOWING_CAMERA"]
    img = "ui/gameuiskin#hud_free_camera.svg"
    locId = "mainmenu/replay/camera"
    isActive = isFreeCameraOptActive
    isDisabled = Computed(@() !isFreeCameraOptActive.get())
  }
]

let getMplayersList = @() get_mplayers_list(GET_MPLAYERS_LIST, true)

function updateControls() {
  if (get_time_speed() != replayTimeSpeed.get())
    replayTimeSpeed.set(get_time_speed())

  replayMplayersList.set(getMplayersList())
  replayCurrentTime.set(get_mission_time())
  let paused = is_replay_paused()
  if (paused != isPauseOptActive.get())
    isPauseOptActive.set(paused)
}

function initReplay() {
  isReplaysManageButtonOn.set(true)
  isPlayerOptionsOpen.set(true)
  needShowPlayerOptions.set(true)

  replayAnchors.set(get_replay_anchors())
  replayTimeSpeed.set(get_time_speed())
  replayMplayersList.set(getMplayersList())
  selectedPlayerIdx.set(getSpectatorTargetId())
  isHudVisibilityOptActive.set(isHudVisible.get())
  isPlayersListOptActive.set(false)
  isPauseOptActive.set(is_replay_paused())
  isMarkersOptActive.set(is_replay_markers_enabled())
  isFreeCameraOptActive.set(true)

  local totalTime = 0
  let path = startedReplayPath.get()
  if (path != null) {
    let info = path.len() && get_replay_info(path)
    let comments = info?.comments
    if (comments)
      totalTime = round(comments?.timePlayed ?? 0).tointeger()
  }
  replayTimeTotal.set(totalTime)
}

function getColorUnitName(player, unit) {
  if(player.isDead && !player.isTemporary)
    return unitDeadTextColor
  else if(unit?.isCollectible)
    return collectibleTextColor
  else if(unit?.isPremium || unit?.isUpgraded)
    return premiumTextColor
  return cellTextColor
}

function getUnitNameText(unitId, unitClass, halign = null) {
  let name = loc(getUnitLocId(unitId), unitId)
  let icon = unitClassFontIcons?[unitClass] ?? ""
  let ordered = halign != ALIGN_RIGHT ? [icon, name] : [name, icon]
  return " ".join(ordered, true)
}

let cellTextProps = {
  rendObj = ROBJ_TEXT
  color = cellTextColor
}.__update(fontVeryTinyAccented)

function mkReplayAnchorMarker(anchorMs, idx) {
  let totalSec = replayTimeTotal.get()
  if (totalSec <= 0)
    return null

  let anchorPercent = clamp((100.0 * anchorMs) / (totalSec * 1000.0), 0, 100)

  return {
    size = [hdpx(10), flex()]
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    pos = [pw(anchorPercent - 50), 0]
    behavior = Behaviors.Button
    onClick = @() moveToAnchor(idx)
    sound = { click = "click" }
    rendObj = ROBJ_SOLID
    color = bgColor
  }
}

function mkOptBtn(opt, onClick, ovr = {}) {
  let { img = "", locId = "", activeImg = null, iconOvr = {}, isActive = Watched(false), isDisabled = Watched(false),
    isLocked = Watched(false), isHidden = Watched(false) } = opt
  let stateFlags = Watched(0)
  let key = {}

  return @() {
    watch = [stateFlags, isActive, isDisabled, isLocked, isHidden]
    children = isHidden.get() ? null
      : {
          key
          size = optBtnSize
          behavior = Behaviors.Button
          rendObj = ROBJ_BOX
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          opacity = isDisabled.get() || isLocked.get() ? 0.5 : 1
          children = {
            size = optImgSize
            rendObj = ROBJ_IMAGE
            image = Picture($"{isActive.get() ? (activeImg ?? img) : img}:{optImgSize}:{optImgSize}:P")
            keepAspect = true
            color = textColor
          }.__update(iconOvr)
          onElemState = @(sf) stateFlags.set(sf)
          sound = { click = "click" }
          transform = { scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.98, 0.98] : [1, 1] }
          transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]
        }.__update(mkButtonHoldTooltip(isLocked.get() ? @() null : onClick, stateFlags, key, @() { content = loc(locId) }), ovr)
  }
}

function handleOptClick(opt) {
  let { shortcutId, isActive = null, cb = null } = opt
  let hasDifferentShortcuts = type(shortcutId) == "array"

  if (isActive != null)
    isActive.set(!isActive.get())

  if (cb != null)
    return cb()

  if (hasDifferentShortcuts) {
    if (isActive != null)
      toggleShortcut(isActive.get() ? shortcutId[0] : shortcutId[1])
  } else
    toggleShortcut(shortcutId)
}

let replayProgressBar = @() {
  watch = [replayTimeProgress, replayAnchors, replayTimeTotal]
  size = [flex(), hdpx(10)]
  rendObj = ROBJ_BOX
  fillColor = textColor
  children = [
    {
      size = [pw(replayTimeProgress.get()), flex()]
      rendObj = ROBJ_SOLID
      color = selectColor
    }
    replayAnchors.get().len() == 0 ? null
      : {
          size = flex()
          children = replayAnchors.get()
            .map(mkReplayAnchorMarker)
            .filter(@(v) v != null)
        }
  ]
}

function mkSquadLabel(player, color) {
  let res = {
    rendObj = ROBJ_BOX
    size = [squadLabelWidth, flex()]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
  }
  if ((player?.squadLabel ?? -1) == -1)
    return res
  return res.__update({
    children = [
      {
        rendObj = ROBJ_IMAGE
        size = [squadLabelWidth, squadLabelHeight]
        image = Picture($"ui/gameuiskin#icon_leaderboard_squad.svg:{squadLabelWidth}:{squadLabelHeight}:P")
      }
      {
        rendObj = ROBJ_TEXT
        halign = ALIGN_RIGHT
        text = player.squadLabel
        color
      }
    ]
  })
}

let mkPlayerName = @(player, teamColor, halign) {
  valign = ALIGN_CENTER
  children = cellTextProps.__merge({
    maxWidth = pw(100)
    halign
    color = player.isLocal ? cellTextColor : teamColor
    text = player.name
  })
}

function mkUnitName(player, halign) {
  let unit = Computed(function() {
    let { allUnits = {} } = serverConfigs.get()
    let unitName = player?.aircraftName ?? ""
    let realUnitName = $"{getTagsUnitName(unitName)}_nc"
    let unitTags = getUnitTagsCfg(unitName)

    return allUnits?[unitName] ?? allUnits?[realUnitName] ?? unitTags.__merge({ name = unitName })
  })

  return @() {
    watch = unit
    size = FLEX_H
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    halign
    children = [
      halign == ALIGN_RIGHT ? null : mkGradRankSmall(unit.get()?.mRank ?? 0)
      cellTextProps.__merge({
        valign = ALIGN_CENTER
        halign
        maxWidth = pw(90)
        behavior = Behaviors.Marquee
        delay = defMarqueeDelay
        speed = hdpx(30)
        color = getColorUnitName(player, unit.get())
        text = getUnitNameText(unit.get()?.name ?? "", unit.get()?.unitClass ?? "", halign)
      })
      halign == ALIGN_RIGHT ? mkGradRankSmall(unit.get()?.mRank ?? 0) : null
    ]
  }
}

function mkAvatar(player) {
  let { userId, isBot, name } = player
  let userIdStr = userId.tostring()
  let info = isBot
    ? mkBotInfo(player.__merge({ decorators = genBotDecorators(name) }))
    : mkPublicInfo(userIdStr)

  return @() {
    watch = info
    onAttach = @() isBot ? null : refreshPublicInfo(userIdStr)
    size = [avatarHeight, avatarHeight]
    rendObj = ROBJ_IMAGE
    image = Picture($"{getAvatarImage(info.get()?.decorators.avatar)}:{avatarHeight}:{avatarHeight}:P")
  }
}

function mkPlayer(player, teamColor, halign) {
  let isSelected = Computed(@() selectedPlayerIdx.get() == player.id)
  let isOnTheRigthSide = halign == ALIGN_RIGHT
  let nameColor = player?.isInHeroSquad
      ? mySquadLightColor
    : player.isLocal
      ? cellTextColor
    : teamColor

  let children = [
    mkAvatar(player)
    mkSquadLabel(player, nameColor)
    {
      size = FLEX_H
      flow = FLOW_VERTICAL
      halign
      children = [
        mkPlayerName(player, teamColor, halign)
        mkUnitName(player, halign)
      ]
    }
  ]

  return {
    size = [flex(), rowHeight]
    children = [
      @() {
        watch = isSelected
        size = flex()
        rendObj = ROBJ_IMAGE
        image = simpleHorGradInv
        color = selectColor
        opacity = isSelected.get() ? 0.9 : 0
        transform = isOnTheRigthSide ? { rotate = 180 } : null
        transitions = opacityTransition
      }
      {
        size = flex()
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        behavior = Behaviors.Button
        sound = { click = "click" }
        padding = halign == ALIGN_RIGHT ? [hdpx(2), 0, hdpx(2), hdpx(4)] : [hdpx(2), hdpx(4), hdpx(2), 0]
        onClick = @() switchSpectatorTargetById(player.id)
        gap = hdpx(4)
        halign
        children = isOnTheRigthSide ? children.reverse() : children
      }
    ]
  }
}

let mkTeamColumn = @(team, teamColor, align) {
  minWidth = rowWidth
  flow = FLOW_VERTICAL
  rendObj = ROBJ_SOLID
  color = bgColor
  children = team.map(@(player) mkPlayer(player, teamColor, align))
}

let centerPanel = @() {
  watch = [isPlayersListOptActive, replayMplayersListSorted, serverConfigs]
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  padding = [0, saBorders[0]]
  children = !isPlayersListOptActive.get() ? null
    : [
        mkTeamColumn(replayMplayersListSorted.get().alliesTeam, teamBlueLightColor, ALIGN_LEFT)
        { size = flex() }
        mkTeamColumn(replayMplayersListSorted.get().enemiesTeam, teamRedLightColor, ALIGN_RIGHT)
      ]
}

let keyBP ={}
let bottomPanel = @() {
  watch = isPlayerOptionsOpen
  key = keyBP
  size = FLEX_H
  rendObj = ROBJ_SOLID
  stopMouse = true
  color = bgColor
  children = {
    size = FLEX_H
    padding = [hdpx(30), saBorders[0]]
    valign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = optBtnGap
    children = [
      replayProgressBar
      {
        size = FLEX_H
        valign = ALIGN_CENTER
        children = [
          {
            hplace = ALIGN_LEFT
            flow = FLOW_HORIZONTAL
            gap = optBtnGap
            children = replayHudControlsList.map(@(opt) mkOptBtn(opt, @() handleOptClick(opt),
              { borderWidth = hdpx(2), borderColor = textColor }))
          }
          {
            hplace = ALIGN_CENTER
            flow = FLOW_HORIZONTAL
            gap = optBtnGap
            children = replayVideoControlsList.map(@(opt) mkOptBtn(opt, @() handleOptClick(opt)))
          }
          @() {
            watch = replayTimeSpeed
            hplace = ALIGN_RIGHT
            children = {
              rendObj = ROBJ_TEXT
              text = format("%.3fx", replayTimeSpeed.get())
            }.__update(fontSmall)
          }
        ]
      }
    ]
  }
  transform = { translate = [0, isPlayerOptionsOpen.get() ? 0 : hdpx(800)] }
  transitions = [{ prop = AnimProp.translate, duration = 0.2, easing = InOutQuad }]
}

function onHudTouchRelease(act) {
  let { x, y } = stickDelta.get()
  if (abs(x * sw(100)) <= limitDistanceStick && abs(y * sw(100)) <= limitDistanceStick)
    act()
}

let hudReplayControls = @() {
  key = "replay-controls"
  watch = [isReplaysManageButtonOn, curUnitHudTuning]
  stopMouse = true
  behavior = TouchScreenStick
  cameraControl = true
  size = flex()
  maxValueRadius = stickRadius
  onAttach = @() setInterval(TIME_TO_UPDATE_CONTROLLS, updateControls)
  onDetach = @() clearTimer(updateControls)
  onChange = @(v) stickDelta.set(Point2(v.x, v.y))
  onTouchEnd = @() onHudTouchRelease(@() isPlayerOptionsOpen.set(true))
  children = isReplaysManageButtonOn.get()
    ? [
        @() {
          watch = [isPlayerOptionsOpen, isHudVisibilityOptActive]
          children = !isPlayerOptionsOpen.get() && !isHudVisibilityOptActive.get() ? null : mkMenuButton(curUnitHudTuning.get()?.options.scale.menuBtn ?? 1, {
            margin = [saBorders[1], saBorders[0]]
            pos = curUnitHudTuning.get()?.transforms.menuBtn.pos ?? [0, 0]
          })
        }.__update(alignToDargPlace(curUnitHudTuning.get()?.transforms.menuBtn.align ?? ALIGN_LT))
        {
          size = flex()
          flow = FLOW_VERTICAL
          valign = ALIGN_BOTTOM
          gap = rowHeight
          children = [
            centerPanel
            bottomPanel
          ]
        }
      ]
    : null
}

isPlayerOptionsOpen.subscribe(@(v) !v
  ? resetTimeout(TIME_TO_UPDATE_CONTROLLS, @() needShowPlayerOptions.set(v))
  : needShowPlayerOptions.set(v))

isPlayingReplay.subscribe(@(v) v ? initReplay() : null)
if (isPlayingReplay.get())
  initReplay()
eventbus_subscribe("WatchedHeroChanged", @(_) selectedPlayerIdx.set(getSpectatorTargetId()))

register_command(@() isReplaysManageButtonOn.set(!isReplaysManageButtonOn.get()), "ui.hideReplaysManageButtons")

return {
  hudReplayControls
  startedReplayPath
  isPlayerOptionsOpen
}
