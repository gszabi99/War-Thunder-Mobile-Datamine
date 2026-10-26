from "%globalScripts/weaponConsts.nut" import *
from "%globalsDarg/darg_library.nut" import *
from "dagor.time" import get_time_msec
from "dagor.workcycle" import resetTimeout, deferOnce
from "math" import fabs
from "mission" import get_mission_time
from "vehicleModel" import getNextBulletType, changeBulletType, getBulletCountByType, getBulletNameByType,
  setSideGunRange
from "wt.behaviors" import TouchScreenButton
from "%sqstd/math.nut" import PI, cos, sin, lerpClamped
from "%sqstd/underscore.nut" import isEqual
from "%globalScripts/controls/shortcutActions.nut" import toggleShortcut
from "%appGlobals/clientState/clientState.nut" import isInBattle
from "%appGlobals/unitConst.nut" import SAILBOAT
from "%appGlobals/unitTags.nut" import getUnitTagsCfg
from "%globalsDarg/screenMath.nut" import scaleArr
import "%rGui/controls/axisListener.nut" as axisListener
from "%rGui/controls/shortcutConsts.nut" import JOY_XBOX_REAL_AXIS_R_THUMB_H, JOY_XBOX_REAL_AXIS_R_THUMB_V,
  AXIS_MODIFIEER_LT, AXIS_MODIFIEER_RT
from "%rGui/controls/shortcutSimpleComps.nut" import mkGamepadShortcutImage, mkGamepadHotkey,
  mkContinuousButtonParams, mkShortcutHoldListener, isLtPressed, isRtPressed, isLtModActive, isRtModActive
from "%rGui/hud/actionBar/actionBarState.nut" import actionBarItems, updateActionBarDelayed, primaryAction,
  primaryExtraAction, secondaryAction, actionItemsInCd
from "%rGui/hud/bullets/hudUnitBulletsState.nut" import currentBulletIdxPrim, currentBulletIdxSec, bulletsInfo,
  bulletsInfoSec, bulletsNamePrim, bulletsNameSec
from "%rGui/hud/buttons/actionButtonComps.nut" import isAvailableActionItem
from "%rGui/hud/buttons/circleTouchHudButtons.nut" import mkBigCircleBtnEditView, mkCircleProgressBg, mkBtnBorder,
  mkBtnImage, mkCircleGlare
from "%rGui/hud/buttons/hudButtonsPkg.nut" import defShortcutOvr, mkBtnZone
from "%rGui/hud/currentWeaponsStates.nut" import markWeapKeyHold, unmarkWeapKeyHold, userHoldWeapInside
from "%rGui/hud/hudTouchButtonStyle.nut" import borderColorPushed, borderNoAmmoColor, borderColor, btnBgStyle
from "%rGui/hudState.nut" import playerUnitName, isUnitAlive, isUnitDelayed
from "%rGui/hudStateExt.nut" import hudUnitType
from "%rGui/hudTuning/cfg/cfgOptions.nut" import isBulletsRight
from "%rGui/hudTuning/hudTuningBattleState.nut" import curUnitHudTuningOptions
from "%rGui/options/options/shipControlsOptions.nut" import isSailboatGunsRangeByStick
from "%rGui/style/hudColors.nut" import hudSmokyGreyColor, hudWhiteColor


const DISTANCE_CHANGE_DELAY = 0.1
const BTN_SIZE_TO_DIST_RANGE = 1.0
const RANGE_CHANGE_PER_SEC = 0.8
const RANGE_STICK_DEAD_ZONE = 0.2
const RANGE_UPDATE_TIME = 0.02

let bigButtonSize = evenPx(150)
let bigButtonImgSize = evenPx(112)
let bulletsButtonSize = evenPx(74)
let bulletsImgSize = evenPx(56)
const bulletsPosRaidus = hdpx(140)
let bulletBgSize = [hdpx(140), hdpx(280)]
const selBulletScale = 1.2
let bulletBgPos = [-bulletsPosRaidus + 0.2 * bulletBgSize[0], -0.05 * bulletBgSize[1]]
const bulletBorderWidthBase = 2
const selBulletBorderWidthBase = 4
let disabledColor = hudSmokyGreyColor

let bulletsAngles = [-1.2 * PI, -0.95 * PI, -0.71 * PI]


let cdPrim = mkWatched(persist, "cdPrim", array(3, 0))
let cdEndPrim = mkWatched(persist, "cdEndPrim", array(3, 0))
let cdSec = mkWatched(persist, "cdSec", array(3, 0))
let cdEndSec = mkWatched(persist, "cdEndSec", array(3, 0))
let rangePrim = mkWatched(persist, "rangePrim", 0.0)
let rangeSec = mkWatched(persist, "rangeSec", 0.0)

let getBulletCd = @(unitName, weaponName, bulletName)
  getUnitTagsCfg(unitName)?.bullets[weaponName][bulletName].cooldown ?? 0

function subscribeCdUpdate(action, cdList, cdEnd, trigger) {
  let counts = []
  function onActionChange(a) {
    if (a == null || hudUnitType.get() != SAILBOAT)
      return
    if (counts.len() == 0) {
      for (local i = 0; i < 3; i++)
        counts.append(getBulletCountByType(trigger, i))
      return
    }
    if ((a?.cooldownEndTime ?? 0) < get_mission_time())
      return
    let newCounts = array(3, trigger).map(getBulletCountByType)
    foreach(i, count in newCounts)
      if (counts[i] > count) {
        let cd = getBulletCd(playerUnitName.get(), a.weaponName, getBulletNameByType(trigger, i))
        if (cd <= 0)
          continue
        let t = get_mission_time()
        cdList.mutate(@(v) v[i] = cd) 
        cdEnd.mutate(@(v) v[i] = t + cd) 
        foreach(idx, end in cdEnd.get())
          if (end < t) {
            changeBulletType(trigger, idx)
            updateActionBarDelayed()
            break
          }
      }
    counts.clear().extend(newCounts)
  }
  action.subscribe(onActionChange)
  if (isInBattle.get())
    onActionChange(action.get())

  isInBattle.subscribe(function(_) {
    cdList.set(array(3, 0))
    cdEnd.set(array(3, 0))
    counts.clear()
  })

  function clearOldTimers() {
    let t = get_mission_time()
    cdEnd.set(cdEnd.get().map(@(v) v > t ? v : 0))
  }

  function updateCdTimer() {
    let t = get_mission_time()
    local next = 0
    local hasChanges = false
    foreach(cd in cdEnd.get())
      if (cd > t)
        next = next <= 0 ? cd : min(next, cd)
      else
        hasChanges = hasChanges || cd > 0
    let timeLeft = next - t
    if (timeLeft > 0)
      resetTimeout(timeLeft, updateCdTimer)
    if (hasChanges)
      deferOnce(clearOldTimers)
  }
  updateCdTimer()
  cdEnd.subscribe(@(_) updateCdTimer())
}

subscribeCdUpdate(primaryAction, cdPrim, cdEndPrim, TRIGGER_GROUP_PRIMARY)
subscribeCdUpdate(primaryExtraAction, cdPrim, cdEndPrim, TRIGGER_GROUP_PRIMARY)
subscribeCdUpdate(secondaryAction, cdSec, cdEndSec, TRIGGER_GROUP_SECONDARY)

let isSideGunsHeroReady = keepref(Computed(@() isUnitAlive.get() && !isUnitDelayed.get()
  && hudUnitType.get() == SAILBOAT))

isSideGunsHeroReady.subscribe(function(isReady) {
  if (!isReady)
    return
  rangePrim.set(0.0)
  rangeSec.set(0.0)
})

function subscribeSideGunRange(trigger, range) {
  range.subscribe(@(v) setSideGunRange(trigger, v))
}

subscribeSideGunRange(TRIGGER_GROUP_PRIMARY, rangePrim)
subscribeSideGunRange(TRIGGER_GROUP_SECONDARY, rangeSec)

let sideGunRanges = {
  AB_PRIMARY_WEAPON = rangePrim
  AB_SECONDARY_WEAPON = rangeSec
}

let isRangeIncPushed = Watched(false)
let isRangeDecPushed = Watched(false)
let isHeldRangeIncPushed = Watched(false)
let isHeldRangeDecPushed = Watched(false)
let mkKeysDir = @(isInc, isDec) Computed(@() (isInc.get() ? 1 : 0) - (isDec.get() ? 1 : 0))
let rangeKeysDir = mkKeysDir(isRangeIncPushed, isRangeDecPushed)
let heldRangeKeysDir = mkKeysDir(isHeldRangeIncPushed, isHeldRangeDecPushed)

function mkSideGunRangeCtrl(range, isHeld, axisModifier) {
  let stickDir = Watched(0.0)
  let dir = Computed(@() clamp(rangeKeysDir.get() + stickDir.get()
      + (isHeld.get() && isSailboatGunsRangeByStick.get() ? heldRangeKeysDir.get() : 0),
    -1.0, 1.0))
  return { range, axisModifier, stickDir, dir }
}

let sideGunRangeCtrls = {
  AB_PRIMARY_WEAPON = mkSideGunRangeCtrl(rangePrim, isRtModActive, AXIS_MODIFIEER_RT)
  AB_SECONDARY_WEAPON = mkSideGunRangeCtrl(rangeSec, isLtModActive, AXIS_MODIFIEER_LT)
}

local isRangeUpdateActive = false
local rangeUpdateMsec = 0
function updateRanges() {
  let curMsec = get_time_msec()
  let dt = isRangeUpdateActive ? 0.001 * (curMsec - rangeUpdateMsec) : 0.0
  rangeUpdateMsec = curMsec
  isRangeUpdateActive = false
  foreach (ctrl in sideGunRangeCtrls) {
    let dir = ctrl.dir.get()
    if (dir == 0)
      continue
    isRangeUpdateActive = true
    ctrl.range.set(clamp(ctrl.range.get() + dir * RANGE_CHANGE_PER_SEC * dt, 0.0, 1.0))
  }
  if (isRangeUpdateActive)
    resetTimeout(RANGE_UPDATE_TIME, updateRanges)
}

function startRangeUpdate(_) {
  if (!isRangeUpdateActive)
    updateRanges()
}

foreach (ctrl in sideGunRangeCtrls)
  ctrl.dir.subscribe(startRangeUpdate)

let mkRangeKey = @(shortcutId, isPushed)
  mkContinuousButtonParams(@() isPushed.set(true), @() isPushed.set(false), shortcutId)

function mkStickRangeListener(ctrl) {
  let { axisModifier, stickDir } = ctrl
  function onStick(v) {
    let value = lerpClamped(RANGE_STICK_DEAD_ZONE, 1.0, 0.0, 1.0, fabs(v))
    stickDir.set(v > 0 ? value : -value)
  }
  return axisListener({
    [JOY_XBOX_REAL_AXIS_R_THUMB_V | axisModifier] = onStick,
    [JOY_XBOX_REAL_AXIS_R_THUMB_H | axisModifier] = @(_) null,
  })
}

let rangeControls = [
  mkRangeKey("ID_SAILBOAT_GUNS_RANGE_INC", isRangeIncPushed)
  mkRangeKey("ID_SAILBOAT_GUNS_RANGE_DEC", isRangeDecPushed)
  mkRangeKey("ID_SAILBOAT_HELD_GUN_RANGE_INC", isHeldRangeIncPushed)
  mkRangeKey("ID_SAILBOAT_HELD_GUN_RANGE_DEC", isHeldRangeDecPushed)
  mkShortcutHoldListener("ID_SHIP_WEAPON_PRIMARY", isRtPressed)
  mkShortcutHoldListener("ID_SHIP_WEAPON_SECONDARY", isLtPressed)
]
let rangeControlsWithStick = (clone rangeControls).extend(sideGunRangeCtrls.values().map(mkStickRangeListener))

let sailboatGunsRangeControls = @() {
  watch = [hudUnitType, isSailboatGunsRangeByStick]
  children = hudUnitType.get() != SAILBOAT ? null
    : isSailboatGunsRangeByStick.get() ? rangeControlsWithStick
    : rangeControls
}

let prevIfEqual = @(prev, cur) isEqual(cur, prev) ? prev : cur

function onChangeBullet(trigger, idx, cdEndTime) {
  if (getNextBulletType(trigger) == idx || cdEndTime > get_mission_time())
    return
  changeBulletType(trigger, idx)
  updateActionBarDelayed()
}

let mkIconComp = @(bInfo, name) Computed(function() {
  local icon = bInfo.get()?.fromUnitTags[name]?.icon
  return icon != null ? $"ui/gameuiskin#{icon}.svg" : "ui/gameuiskin#hud_ammo_ap1_he1.svg"
})

let mkBulletBorder = @(bgSize, borderWidth, isAvailable, stateFlags) @() {
  watch = stateFlags
  size = bgSize
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = borderWidth
  color = stateFlags.get() & S_ACTIVE ? borderColorPushed
    : !isAvailable ? borderNoAmmoColor
    : borderColor
  fillColor = 0
  commands = const [[VECTOR_ELLIPSE, 50, 50, 50, 50]]
}

function mkBulletToggle(scale, isRight, i, onClick, icon, isCurrent, cdInfo) {
  let isAvailable = Computed(@() cdInfo.get().end <= 0)
  let stateFlags = Watched(0)
  let angle = bulletsAngles?[i] ?? 0
  let pos = [cos(angle) * bulletsPosRaidus * scale * (isRight ? -1.0 : 1.0), sin(angle) * bulletsPosRaidus * scale]
  let btnSize = scaleEven(bulletsButtonSize, scale)
  return function() {
    let color = !isAvailable.get() ? disabledColor : hudWhiteColor
    let scaleExt = scale * (isCurrent.get() ? selBulletScale : 1.0)
    let bgSize = scaleEven(bulletsButtonSize, scaleExt)
    let imgSize = scaleEven(bulletsImgSize, scaleExt)
    return {
      watch = [isAvailable, icon, isCurrent, cdInfo]
      size = btnSize
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      pos

      behavior = Behaviors.Button
      cameraControl = true
      onElemState = @(v) stateFlags.set(v)
      onClick

      children = [
        mkCircleProgressBg(bgSize, {
          count = 1000
          cooldownEndTime = cdInfo.get().end
          cooldownTime = cdInfo.get().cd
        })
        mkBulletBorder(bgSize,
          hdpxi(scale * (isCurrent.get() ? selBulletBorderWidthBase : bulletBorderWidthBase)),
          isAvailable.get(), stateFlags)
        mkBtnImage(imgSize, icon.get(), color)
      ]
    }
  }
}

function mkBulletsBg(scale, isRight) {
  let bgSize = scaleArr(bulletBgSize, scale)
  let pos = scaleArr(bulletBgPos, scale)
  return {
    size = bgSize
    pos = isRight ? [-pos[0], pos[1]] : pos
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#hud_pirate_ammo_bg.svg:{bgSize[0]}:{bgSize[1]}:P")
    keepAspect = true
    flipX = !isRight
  }
}

let mkToggleBulletsButtonsCtor = @(trigger, bInfo, bNames, currentIdx, cd, cdEnd
) function(scale, isRightAlign) {
  let bOrder = Computed(function() {
    let res = []
    let used = {}
    foreach (idx, name in bNames.get())
      if (name not in used) {
        used[name] <- true
        res.append({ idx, name })
      }
    return res
  })
  return @() {
    watch = [bOrder, isRightAlign]
    size = FLEX
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [ mkBulletsBg(scale, isRightAlign.get()) ]
      .extend(bOrder.get().map(function(v, i) {
        let { idx, name } = v
        let cdInfo = Computed(@(prev) prevIfEqual(prev, { cd = cd.get()[i], end = cdEnd.get()[i] }))
        return mkBulletToggle(scale, isRightAlign.get(), i,
          @() onChangeBullet(trigger, idx, cdEnd.get()[i]),
          mkIconComp(bInfo, name),
          Computed(@() currentIdx.get() == idx),
          cdInfo)
      }))
  }
}

let toggleBulletsCtors = {
  AB_PRIMARY_WEAPON = mkToggleBulletsButtonsCtor(TRIGGER_GROUP_PRIMARY, bulletsInfo, bulletsNamePrim,
    currentBulletIdxPrim, cdPrim, cdEndPrim)
  AB_SECONDARY_WEAPON = mkToggleBulletsButtonsCtor(TRIGGER_GROUP_SECONDARY, bulletsInfoSec, bulletsNameSec,
    currentBulletIdxSec, cdSec, cdEndSec)
}

let lengthSq = @(x, y) x * x + y * y

let mkBroadsideButtonCtor = @(aType, shortcutId, isRight) function(scale, elemId) {
  let key = $"broadside_{aType}"
  let stateFlags = Watched(0)
  local point = null
  local startPoint = null
  local startRange = 0.0
  local allowDistanceUpdateMsec = 0
  let bgSize = scaleEven(bigButtonSize, scale)
  let imgSize = scaleEven(bigButtonImgSize, scale)
  let actionItem = Computed(@() actionBarItems.get()?[aType])
  let isRightAlign = Computed(@() isBulletsRight(curUnitHudTuningOptions.get(), elemId))
  let bulletsToggle = toggleBulletsCtors?[aType](scale, isRightAlign)
  let range = sideGunRanges?[aType]
  let isOnCd = Computed(@() actionItemsInCd.get()?[aType] ?? false)

  function onTouchBegin() {
    markWeapKeyHold(key)
    userHoldWeapInside.mutate(@(v) v[key] <- true)
  }

  function onStopTouch() {
    startPoint = null
    unmarkWeapKeyHold(key)
    if (key in userHoldWeapInside.get())
      userHoldWeapInside.mutate(@(v) v.$rawdelete(key))
  }

  function shoot() {
    if (isOnCd.get() || !isAvailableActionItem(actionItem.get()))
      return
    toggleShortcut(shortcutId) 
    toggleShortcut("ID_SHIP_WEAPON_ALL") 
    updateActionBarDelayed()
  }

  function onTouchEnd() {
    if (userHoldWeapInside.get()?[key])
      shoot()
    onStopTouch()
  }

  let hotkey = mkGamepadHotkey(shortcutId, shoot)
  let gamepadShortcut = mkGamepadShortcutImage(shortcutId, defShortcutOvr, scale)

  let zRadiusX = (bgSize * 0.75).tointeger()
  let zRadiusY = (bgSize * 1.5).tointeger()
  let btnZone = mkBtnZone(key, zRadiusX, zRadiusY)

  function updateDistance() {
    if (startPoint == null || point == null || range == null)
      return
    let dy = point.y - startPoint.y
    let dRange = -dy * BTN_SIZE_TO_DIST_RANGE / bgSize
    range.set(clamp(startRange + dRange, 0.0, 1.0))
  }

  function onChange(p) {
    point = p
    if (startPoint == null) {
      startPoint = p
      startRange = range?.get() ?? 0.0
      resetTimeout(DISTANCE_CHANGE_DELAY, updateDistance)
      allowDistanceUpdateMsec = get_time_msec() + (1000 * DISTANCE_CHANGE_DELAY).tointeger()
    }
    else if (allowDistanceUpdateMsec <= get_time_msec())
      updateDistance()

    let isInside = lengthSq((p.x - bgSize / 2) / zRadiusX, (p.y - bgSize / 2) / zRadiusY) <= 1
    if (userHoldWeapInside.get()?[key] != isInside)
      userHoldWeapInside.mutate(@(v) v[key] <- isInside)
  }

  return function() {
    if (actionItem.get() == null)
      return { watch = actionItem }

    let isAvailable = !isOnCd.get() && isAvailableActionItem(actionItem.get())
    let { aimReady } = actionItem.get()
    let color = !isAvailable || !aimReady ? disabledColor : hudWhiteColor

    return {
      watch = [actionItem, isOnCd]
      key = aType
      size = bgSize
      behavior = TouchScreenButton
      onElemState = @(v) stateFlags.set(v)
      onTouchBegin
      onTouchEnd
      onTouchInterrupt = onStopTouch
      onChange
      hotkeys = hotkey

      children = [
        mkCircleProgressBg(bgSize, actionItem.get())
        mkBtnBorder(bgSize, isAvailable, stateFlags)
        mkBtnImage(imgSize, "ui/gameuiskin#hud_pirate_attack.svg", color)
          .__update({ flipX = !isRight })
        mkCircleGlare(bgSize, actionItem.get()?.id)
        bulletsToggle
        btnZone
        gamepadShortcut
      ]
    }
  }
}

function mkBulletEditView(i, icon, isRight) {
  let angle = bulletsAngles?[i] ?? 0
  let scale = i == 0 ? selBulletScale : 1.0
  let bgSize = bulletsButtonSize * scale
  return {
    size = bgSize
    pos = [cos(angle) * bulletsPosRaidus * (isRight ? -1.0 : 1.0), sin(angle) * bulletsPosRaidus]
    children = [
      @() {
        watch = btnBgStyle
        size = FLEX
        rendObj = ROBJ_VECTOR_CANVAS
        lineWidth = hdpxi(i == 0 ? selBulletBorderWidthBase : bulletBorderWidthBase)
        color = borderColor
        fillColor = btnBgStyle.get().ready
        commands = const [[VECTOR_ELLIPSE, 50, 50, 50, 50]]
      }
      mkBtnImage(scaleEven(bulletsImgSize, scale), icon, hudWhiteColor)
    ]
  }
}

let bulletsEditView = @(isRight) [
  {
    size = bulletBgSize
    pos = isRight ? [-bulletBgPos[0], bulletBgPos[1]] : bulletBgPos
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#hud_pirate_ammo_bg.svg:{bulletBgSize[0]}:{bulletBgSize[1]}:P")
    keepAspect = true
    flipX = !isRight
  }
  mkBulletEditView(0, "ui/gameuiskin#hud_ammo_pirate_cannonball.svg", isRight)
  mkBulletEditView(1, "ui/gameuiskin#hud_ammo_pirate_knipel.svg", isRight)
  mkBulletEditView(2, "ui/gameuiskin#hud_ammo_pirate_fire.svg", isRight)
]

let mkBroadsideButtonEditView = @(icon, isRight) @(options, elemId) {
  size = bigButtonSize
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [mkBigCircleBtnEditView(icon, { flipX = !isRight })]
    .extend(bulletsEditView(isBulletsRight(options, elemId)))
}

return {
  mkBroadsideButtonCtor
  mkBroadsideButtonEditView
  sailboatGunsRangeControls
}