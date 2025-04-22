from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, deferOnce } = require("dagor.workcycle")
let { get_mission_time } = require("mission")
let { getNextBulletType, changeBulletType, getBulletCountByType, getBulletNameByType
} = require("vehicleModel")
let { PI, cos, sin } = require("%sqstd/math.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let { toggleShortcut } = require("%globalScripts/controls/shortcutActions.nut")
let { scaleArr } = require("%globalsDarg/screenMath.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { SAILBOAT } = require("%appGlobals/unitConst.nut")
let { getUnitTagsCfg } = require("%appGlobals/unitTags.nut")
let { hudUnitType, playerUnitName } = require("%rGui/hudState.nut")
let { mkGamepadShortcutImage, mkGamepadHotkey } = require("%rGui/controls/shortcutSimpleComps.nut")
let { actionBarItems, updateActionBarDelayed, primaryAction, secondaryAction, actionItemsInCd
} = require("%rGui/hud/actionBar/actionBarState.nut")
let { mkCircleProgressBg, mkBtnBorder, mkBtnImage, mkCircleGlare } = require("circleTouchHudButtons.nut")
let { defShortcutOvr }  = require("hudButtonsPkg.nut")
let { isAvailableActionItem } = require("actionButtonComps.nut")
let { borderColorPushed, borderNoAmmoColor, borderColor, btnBgColor
} = require("%rGui/hud/hudTouchButtonStyle.nut")
let { currentBulletIdxPrim, currentBulletIdxSec, bulletsInfo, bulletsInfoSec, bulletsNamePrim, bulletsNameSec
} = require("%rGui/hud/bullets/hudUnitBulletsState.nut")
let { mkBigCircleBtnEditView } = require("%rGui/hud/buttons/circleTouchHudButtons.nut")
let { isBulletsRight } = require("%rGui/hudTuning/cfg/cfgOptions.nut")
let { curUnitHudTuningOptions } = require("%rGui/hudTuning/hudTuningBattleState.nut")


let bigButtonSize = evenPx(150)
let bigButtonImgSize = evenPx(112)
let bulletsButtonSize = evenPx(74)
let bulletsImgSize = evenPx(56)
let bulletsPosRaidus = hdpx(140)
let bulletBgSize = [hdpx(140), hdpx(280)]
let selBulletScale = 1.2
let bulletBgPos = [-bulletsPosRaidus + 0.2 * bulletBgSize[0], -0.05 * bulletBgSize[1]]
let bulletBorderWidthBase = 2
let selBulletBorderWidthBase = 4
let disabledColor = 0x4D4D4D4D

let bulletsAngles = [-1.2 * PI, -0.95 * PI, -0.71 * PI]


let cdPrim = mkWatched(persist, "cdPrim", array(3, 0))
let cdEndPrim = mkWatched(persist, "cdEndPrim", array(3, 0))
let cdSec = mkWatched(persist, "cdSec", array(3, 0))
let cdEndSec = mkWatched(persist, "cdEndSec", array(3, 0))

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
subscribeCdUpdate(secondaryAction, cdSec, cdEndSec, TRIGGER_GROUP_SECONDARY)

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
  size = [bgSize, bgSize]
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = borderWidth
  color = stateFlags.get() & S_ACTIVE ? borderColorPushed
    : !isAvailable ? borderNoAmmoColor
    : borderColor
  fillColor = 0
  commands = [[VECTOR_ELLIPSE, 50, 50, 50, 50]]
}

function mkBulletToggle(scale, isRight, i, onClick, icon, isCurrent, cdInfo) {
  let isAvailable = Computed(@() cdInfo.get().end <= 0)
  let stateFlags = Watched(0)
  let angle = bulletsAngles?[i] ?? 0
  let pos = [cos(angle) * bulletsPosRaidus * scale * (isRight ? -1.0 : 1.0), sin(angle) * bulletsPosRaidus * scale]
  let btnSize = scaleEven(bulletsButtonSize, scale)
  return function() {
    let color = !isAvailable.get() ? disabledColor : 0xFFFFFFFF
    let scaleExt = scale * (isCurrent.get() ? selBulletScale : 1.0)
    let bgSize = scaleEven(bulletsButtonSize, scaleExt)
    let imgSize = scaleEven(bulletsImgSize, scaleExt)
    return {
      watch = [isAvailable, icon, isCurrent, cdInfo]
      size = [btnSize, btnSize]
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
    size = flex()
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

let mkBroadsideButtonCtor = @(aType, shortcutId, isRight) function(scale, elemId) {
  let stateFlags = Watched(0)
  let bgSize = scaleEven(bigButtonSize, scale)
  let imgSize = scaleEven(bigButtonImgSize, scale)
  let actionItem = Computed(@() actionBarItems.get()?[aType])
  let isRightAlign = Computed(@() isBulletsRight(curUnitHudTuningOptions.get(), elemId))
  let bulletsToggle = toggleBulletsCtors?[aType](scale, isRightAlign)
  let isOnCd = Computed(@() actionItemsInCd.get()?[aType] ?? false)

  function onClick() {
    if (isOnCd.get() || !isAvailableActionItem(actionItem.get()))
      return
    toggleShortcut(shortcutId) 
    toggleShortcut("ID_SHIP_WEAPON_ALL") 
    updateActionBarDelayed()
  }

  return function() {
    if (actionItem.get() == null)
      return { watch = actionItem }

    let isAvailable = !isOnCd.get() && isAvailableActionItem(actionItem.get())
    let { aimReady } = actionItem.get()
    let color = !isAvailable || !aimReady ? disabledColor : 0xFFFFFFFF
    return {
      watch = [actionItem, isOnCd]
      key = aType
      size = [bgSize, bgSize]
      behavior = Behaviors.Button
      cameraControl = true
      onElemState = @(v) stateFlags.set(v)
      hotkeys = mkGamepadHotkey(shortcutId)
      onClick

      children = [
        mkCircleProgressBg(bgSize, actionItem.get())
        mkBtnBorder(bgSize, isAvailable, stateFlags)
        mkBtnImage(imgSize, "ui/gameuiskin#hud_pirate_attack.svg", color)
          .__update({ flipX = !isRight })
        mkCircleGlare(bgSize, actionItem.get()?.id)
        bulletsToggle
        mkGamepadShortcutImage(shortcutId, defShortcutOvr, scale)
      ]
    }
  }
}

function mkBulletEditView(i, icon, isRight) {
  let angle = bulletsAngles?[i] ?? 0
  let scale = i == 0 ? selBulletScale : 1.0
  let bgSize = bulletsButtonSize * scale
  return {
    size = [bgSize, bgSize]
    pos = [cos(angle) * bulletsPosRaidus * (isRight ? -1.0 : 1.0), sin(angle) * bulletsPosRaidus]
    children = [
      {
        size = flex()
        rendObj = ROBJ_VECTOR_CANVAS
        lineWidth = hdpxi(i == 0 ? selBulletBorderWidthBase : bulletBorderWidthBase)
        color = borderColor
        fillColor = btnBgColor.ready
        commands = [[VECTOR_ELLIPSE, 50, 50, 50, 50]]
      }
      mkBtnImage(scaleEven(bulletsImgSize, scale), icon, 0xFFFFFFFF)
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
  size = [bigButtonSize, bigButtonSize]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [mkBigCircleBtnEditView(icon, { flipX = !isRight })]
    .extend(bulletsEditView(isBulletsRight(options, elemId)))
}

return {
  mkBroadsideButtonCtor
  mkBroadsideButtonEditView
}