from "%globalsDarg/darg_library.nut" import *

let { get_mission_time } = require("%globalsDarg/mission.nut")
let { defer, resetTimeout, clearTimer } = require("dagor.workcycle")
let { getRomanNumeral, ceil } = require("%sqstd/math.nut")
let { toggleShortcut, setShortcutOn, setShortcutOff } = require("%globalScripts/controls/shortcutActions.nut")
let { updateActionBarDelayed } = require("actionBar/actionBarState.nut")
let { touchButtonSize, borderWidth, btnBgColor, getSvgImage, imageColor, imageDisabledColor,
  borderColor, borderColorPushed, borderNoAmmoColor, textColor, textDisabledColor
} = require("%rGui/hud/hudTouchButtonStyle.nut")
let { hasAimingModeForWeapon, markWeapKeyHold, unmarkWeapKeyHold, userHoldWeapKeys, userHoldWeapInside, isChainedWeapons
} = require("%rGui/hud/currentWeaponsStates.nut")
let { hasTarget, hasTargetCandidate, groupAttack, targetState, torpedoDistToLive, canZoom, isInZoom, unitType,
  groupIsInAir, group2IsInAir, group3IsInAir, group4IsInAir } = require("%rGui/hudState.nut")
let { playHapticPattern } = require("hapticVibration")
let { fire, isFullBuoyancy } = require("%rGui/hud/shipState.nut")
let { playSound } = require("sound_wt")
let { addCommonHint } = require("%rGui/hudHints/commonHintLogState.nut")
let { nextBulletIdx, currentBulletIdxPrim, currentBulletIdxSec
} = require("bullets/hudUnitBulletsState.nut")
let { AB_TORPEDO } = require("actionBar/actionType.nut")
let { mkGamepadShortcutImage, mkGamepadHotkey, mkContinuousButtonParams
} = require("%rGui/controls/shortcutSimpleComps.nut")
let { isGamepad } = require("%rGui/activeControls.nut")
let { lowerAircraftCamera } = require("camera_control")
let { mkBtnGlare, mkActionGlare, mkConsumableSpend, mkActionBtnGlare
} = require("%rGui/hud/weaponsButtonsAnimations.nut")
let { isNotOnTheSurface, isDeeperThanPeriscopeDepth } = require("%rGui/hud/submarineDepthBlock.nut")
let { TANK, SHIP, BOAT, SUBMARINE } = require("%appGlobals/unitConst.nut")
let { set_can_lower_camera } = require("controlsOptions")
let { mkIsControlDisabled } = require("%rGui/controls/disabledControls.nut")
let { mkRhombBtnBg, mkRhombBtnBorder, mkAmmoCount } = require("%rGui/hud/buttons/rhombTouchHudButtons.nut")

let defImageSize = (0.75 * touchButtonSize).tointeger()
let zoomImgSize = touchButtonSize
let weaponNumberSize = (0.3 * touchButtonSize).tointeger()
let wNumberColor = 0xFF1C9496

let cooldownImgSize = (1.42 * touchButtonSize).tointeger()
let actionBarCooldownImg = getSvgImage("controls_help_point", cooldownImgSize)

let aimImgWidth = (0.8 * touchButtonSize).tointeger()
let aimImgHeight = (0.44 * aimImgWidth).tointeger()
let aimImg = getSvgImage("hud_debuff_rotation", aimImgWidth, aimImgHeight)

let debuffImgSize = (0.6 * touchButtonSize).tointeger()
let fireImage = getSvgImage("hud_debuff_fire", debuffImgSize)
let buoyancyImage = getSvgImage("hud_debuff_water", debuffImgSize)
let repairSwithAnimImage = getSvgImage("hud_circle_animation", touchButtonSize)

let binocularsImage = getSvgImage("hud_binoculars", zoomImgSize)
let zoomImage = getSvgImage("hud_binoculars_zoom", zoomImgSize)

let divingImage = getSvgImage("hud_submarine_diving", zoomImgSize)
let surfacingImage = getSvgImage("hud_submarine_surfacing", zoomImgSize)

let { setDrawWeaponAllowableAngles } = require("hudState")

let gunImageBySizeOrder = [
  { image = "ui/gameuiskin#hud_ship_calibre_main_3_left.svg", relImageSize = 1.3 }
  { image = "ui/gameuiskin#hud_ship_calibre_medium.svg" }
  { image = "ui/gameuiskin#hud_aircraft_machine_gun.svg" }
]

let svgNullable = @(image, size) ((image ?? "") == "") ? null
  : Picture($"{image}:{size}:{size}:P")

let weaponryButtonRotate = 45
let countHeightUnderActionItem = (0.4 * touchButtonSize).tointeger()
let zoneRadiusX = 2.5 * touchButtonSize
let zoneRadiusY = touchButtonSize
let abShortcutImageOvr = { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = [pw(50), ph(-50)] }
let rotatedShortcutImageOvr = { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = [0, ph(-70)] }

function useShortcut(shortcutId) {
  toggleShortcut(shortcutId)
  updateActionBarDelayed()
}

function useShortcutOn(shortcutId) {
  setShortcutOn(shortcutId)
  updateActionBarDelayed()
}

let isAvailableActionItem = @(itemValue) itemValue.count != 0 && (itemValue?.available ?? true)

function mkActionItemProgress(itemValue, isAvailable) {
  let { cooldownEndTime = 0, cooldownTime = 1, blockedCooldownEndTime = 0, blockedCooldownTime = 1, id = null
  } = itemValue
  let isBlocked = blockedCooldownEndTime > 0 && cooldownEndTime == 0
  let endTime = isBlocked ? blockedCooldownEndTime : cooldownEndTime
  let time = isBlocked ? blockedCooldownTime : cooldownTime
  let cooldownDuration = endTime - get_mission_time()
  let hasCooldown = isAvailable && cooldownDuration > 0
  let cooldown = hasCooldown ? (1 - (cooldownDuration / max(time, 1))) : 1
  let trigger = $"action_cd_finish_{id}"
  return {
    size = flex()
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    clipChildren = true
    children = {
      size = [cooldownImgSize, cooldownImgSize]
      rendObj = ROBJ_PROGRESS_CIRCULAR
      image = actionBarCooldownImg
      fgColor = !isAvailable ? btnBgColor.noAmmo
        : (itemValue?.broken ?? false) ? btnBgColor.broken
        : btnBgColor.ready
      bgColor = btnBgColor.empty
      fValue = 1.0
      key = $"action_bg_{id}_{endTime}_{time}_{isAvailable}"
      animations = [
        { prop = AnimProp.fValue, from = cooldown, to = 1.0, duration = cooldownDuration, play = true
          onFinish = @() isAvailable ? anim_start(trigger) : null
        }
      ]
    }

    transform = {}
    animations = [{ prop = AnimProp.scale, duration = 0.2,
      from = [1.0, 1.0], to = [1.2, 1.2], easing = CosineFull, trigger }]
  }
}

let mkActionItemCount = @(count) {
  rendObj = ROBJ_TEXT
  size = [touchButtonSize, countHeightUnderActionItem]
  halign = ALIGN_CENTER
  valign = ALIGN_BOTTOM
  fontFxColor = Color(0, 0, 0, 255)
  fontFxFactor = 50
  fontFx = FFT_GLOW
  color = textColor
  text = count < 0 ? "" : count
}.__update(fontTiny)

let mkActionItemImage = @(getImage, isAvailable) @() {
  watch = unitType
  rendObj = ROBJ_IMAGE
  size = [touchButtonSize, touchButtonSize]
  image = svgNullable(getImage(unitType.value), touchButtonSize)
  keepAspect = KEEP_ASPECT_FIT
  color = !isAvailable ? imageDisabledColor : imageColor
}

function mkActionItem(buttonConfig, actionItem) {
  if (actionItem == null)
    return null
  let { getShortcut, getImage, haptPatternId = -1, key = null, sound = "", getAnimationKey = null } = buttonConfig
  let stateFlags = Watched(0)
  let isAvailable = isAvailableActionItem(actionItem)
  let shortcutId = getShortcut(unitType.value, actionItem) //FIXME: Need to calculate shortcutId on the higher level where it really rebuild on change unit
  let isDisabled = mkIsControlDisabled(shortcutId)
  let animationKey = getAnimationKey ? getAnimationKey(unitType.value) : null
  return {
    size = [touchButtonSize, touchButtonSize + countHeightUnderActionItem]
    flow = FLOW_VERTICAL
    children = [
      @() {
        watch = isDisabled
        key = key ?? shortcutId
        behavior = Behaviors.Button
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        size = [touchButtonSize, touchButtonSize]
        function onClick() {
          if ((actionItem?.cooldownEndTime ?? 0) > get_mission_time() || isDisabled.value)
            return
          if (actionItem?.available)
            playSound(sound)
          useShortcut(shortcutId)
          playHapticPattern(haptPatternId)
        }
        hotkeys = mkGamepadHotkey(shortcutId)
        onElemState = @(v) stateFlags(v)
        children = [
          mkActionItemProgress(actionItem, isAvailable && !isDisabled.value)
          @() {
            watch = [stateFlags]
            rendObj = ROBJ_BOX
            size = flex()
            borderColor = stateFlags.value & S_ACTIVE ? borderColorPushed
              : (!isAvailable || isDisabled.value) ? borderNoAmmoColor
              : borderColor
            borderWidth
          }
          mkActionItemImage(getImage, isAvailable && !isDisabled.value)
          mkActionGlare(actionItem)
          isDisabled.value ? null
            : mkGamepadShortcutImage(shortcutId, abShortcutImageOvr)
          mkConsumableSpend(animationKey)
        ]
      }
      mkActionItemCount(actionItem.count)
    ]
  }
}

let progress = Watched(null)
let progressTime = Watched(null)
function progressUpdate() {
  let timing = progressTime.get() ?? [0, 0]
  let currTime = get_mission_time()
  if (currTime < timing[0]) {//just wait for begin
    progress.set(null)
    resetTimeout(timing[0] - currTime, progressUpdate)
    return
  }
  let toEndTime = timing[1] - get_mission_time()
  if (toEndTime > 0.0) {
    local progressV = ceil(toEndTime).tointeger()
    local nextTick = toEndTime % 1.0
    if (nextTick < 0.01) {
      nextTick += 1
      progressV--
    }
    progress.set( progressV )
    resetTimeout(nextTick, progressUpdate)
  } else {
    defer(@() progressTime.set(null))
    progress.set(null)
  }
}

progressTime.subscribe(@(v) v != null ? progressUpdate() : null)

let mkProgressText = @() {
  watch = progress
  rendObj = ROBJ_TEXT
  pos = [0, -hdpx(20)]
  vplace = ALIGN_TOP
  halign = ALIGN_CENTER
  text = progress.get() ? progress.get() : ""
}.__update(fontVeryTiny)

function mkIRCMActionItem(buttonConfig, actionItem) {
  if (actionItem == null)
    return null
  let { getShortcut, getImage, haptPatternId = -1, key = null, sound = "", getAnimationKey = null } = buttonConfig
  let stateFlags = Watched(0)
  let isAvailable = isAvailableActionItem(actionItem)
  let shortcutId = getShortcut(unitType.value, actionItem) //FIXME: Need to calculate shortcutId on the higher level where it really rebuild on change unit
  let isDisabled = mkIsControlDisabled(shortcutId)
  let animationKey = getAnimationKey ? getAnimationKey(unitType.value) : null
  let endTime = actionItem?.inProgressEndTime ?? 0.0
  let beginTime = endTime - (actionItem?.inProgressTime ?? 0.0)
  defer(@() progressTime.set([beginTime, endTime]))

  return {
    size = [touchButtonSize, touchButtonSize + countHeightUnderActionItem]
    flow = FLOW_VERTICAL
    children = [
      @() {
        watch = [isDisabled, progressTime]
        key = key ?? shortcutId
        behavior = Behaviors.Button
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        size = [touchButtonSize, touchButtonSize]
        function onClick() {
          if ((actionItem?.cooldownEndTime ?? 0) > get_mission_time() || isDisabled.value)
            return
          if (actionItem?.available)
            playSound(sound)
          useShortcut(shortcutId)
          playHapticPattern(haptPatternId)
        }
        hotkeys = mkGamepadHotkey(shortcutId)
        onElemState = @(v) stateFlags(v)
        children = [
          progressTime.get() ? mkProgressText : mkActionItemProgress(actionItem, isAvailable && !isDisabled.value)
          @() {
            watch = [stateFlags]
            rendObj = ROBJ_BOX
            size = flex()
            borderColor = stateFlags.value & S_ACTIVE ? borderColorPushed
              : progressTime.get() ? borderColorPushed
              : (!isAvailable || isDisabled.value) ? borderNoAmmoColor
              : borderColor
            borderWidth
          }
          mkActionItemImage(getImage, isAvailable && !isDisabled.value)
          mkActionGlare(actionItem)
          isDisabled.value ? null
            : mkGamepadShortcutImage(shortcutId, abShortcutImageOvr)
          mkConsumableSpend(animationKey)
        ]
      }
      mkActionItemCount(actionItem.count)
    ]
  }
}

let mkActionItemEditView = @(image) {
  size = [touchButtonSize, touchButtonSize + countHeightUnderActionItem]
  flow = FLOW_VERTICAL
  children = [
    {
      size = [touchButtonSize, touchButtonSize]
      rendObj = ROBJ_BOX
      fillColor = btnBgColor.empty
      borderColor
      borderWidth
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = {
        rendObj = ROBJ_IMAGE
        size = [touchButtonSize, touchButtonSize]
        image = Picture($"{image}:{touchButtonSize}:{touchButtonSize}:P")
        keepAspect = KEEP_ASPECT_FIT
        color = imageColor
      }
    }
    mkActionItemCount(0)
  ]
}

let mkBulletEditView = @(image, bulletNumber) {
  size = [touchButtonSize, touchButtonSize]
  rendObj = ROBJ_BOX
  fillColor = btnBgColor.empty
  borderColor
  borderWidth
  children = [
    {
      rendObj = ROBJ_IMAGE
      size = [touchButtonSize, touchButtonSize]
      image = Picture($"{image}:{touchButtonSize}:{touchButtonSize}:P")
      keepAspect = KEEP_ASPECT_FIT
      color = imageColor
    }
    {
      rendObj = ROBJ_TEXT
      size = [touchButtonSize, touchButtonSize]
      padding = [0, hdpx(6), hdpx(2), 0]
      valign = ALIGN_BOTTOM
      halign = ALIGN_RIGHT
      text = getRomanNumeral(bulletNumber)
    }.__update(fontVeryTiny)
  ]
}

let debuffImages = Computed(function() {
  let res = []
  if ([ SHIP, BOAT, SUBMARINE ].contains(unitType.value)) {
    if (fire.value)
      res.append(fireImage)
    if (!isFullBuoyancy.value)
      res.append(buoyancyImage)
  }
  return res
})

let curRepairImageIdx = Watched(-1) //-1 for show repair image
unitType.subscribe(@(_) curRepairImageIdx(-1))

function setNextRepairImage() {
  let nextIdx = curRepairImageIdx.value + 1
  if (nextIdx in debuffImages.value)
    curRepairImageIdx(nextIdx)
  else
    curRepairImageIdx(-1)
}

function mkRepairActionItem(buttonConfig, actionItem) {
  let { getShortcut, getImage, haptPatternId = -1, actionKey = "btn_repair", getAnimationKey = null } = buttonConfig
  let stateFlags = Watched(0)
  let isAvailable = actionItem != null && isAvailableActionItem(actionItem)
  let isInCooldown = (actionItem?.cooldownEndTime ?? 0) > get_mission_time()
  let shortcutId = actionItem == null ? null
    : getShortcut(unitType.value, actionItem) //FIXME: Need to calculate shortcutId on the higher level where it really rebuild on change unit
  let isDisabled = mkIsControlDisabled(shortcutId)
  let animationKey = getAnimationKey ? getAnimationKey(unitType.value) : null
  let hotkey = (unitType.value != TANK || isAvailable) ? shortcutId : null
  return {
    size = [touchButtonSize, touchButtonSize + countHeightUnderActionItem]
    flow = FLOW_VERTICAL
    children = [
      @() {
        watch = isDisabled
        key = actionKey
        behavior = Behaviors.Button
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        size = [touchButtonSize, touchButtonSize]
        function onClick() {
          if (actionItem == null) {
            addCommonHint(loc("hint/noItemsForRepair"))
            return
          }
          if ((actionItem?.cooldownEndTime ?? 0) > get_mission_time() || isDisabled.value)
            return
          if (actionItem?.available)
            playSound("repair")
          useShortcut(shortcutId)
          playHapticPattern(haptPatternId)
        }
        hotkeys = mkGamepadHotkey(hotkey)
        onElemState = @(v) stateFlags(v)
        children = [
          mkActionItemProgress(actionItem, (isAvailable || isInCooldown) && !isDisabled.value)
          @() {
            watch = [stateFlags]
            rendObj = ROBJ_BOX
            size = flex()
            borderColor = stateFlags.value & S_ACTIVE ? borderColorPushed
              : (!isAvailable || isDisabled.value) ? borderNoAmmoColor
              : borderColor
            borderWidth
          }
          @() {
            watch = [debuffImages, curRepairImageIdx, unitType]
            size = flex()
            valign = ALIGN_CENTER
            halign = ALIGN_CENTER
            clipChildren = true
            children = [
                isAvailable && debuffImages.value.len() > 0
                ? {
                    rendObj = ROBJ_IMAGE
                    size = flex()
                    image = repairSwithAnimImage
                    keepAspect = KEEP_ASPECT_FIT
                    color = isInCooldown ? Color(0, 0, 0, 0)
                      : !isAvailable ? imageDisabledColor
                      : imageColor
                    key = $"switch_repair_image_{curRepairImageIdx.value}"
                    animations = [
                      { prop = AnimProp.scale, from = [0.2, 0.2], to = [1.6, 1.6], play = true,
                        duration = 3.0, easing = Linear,
                        onFinish = @() setNextRepairImage()
                      }
                    ]
                    transform = { pivot = [0.5, 0.5] }
                }
                : null,
              {
                size = debuffImages.value?[curRepairImageIdx.value] != null
                  ? [debuffImgSize, debuffImgSize]
                  : [touchButtonSize, touchButtonSize]
                rendObj = ROBJ_IMAGE
                image = debuffImages.value?[curRepairImageIdx.value] ?? svgNullable(getImage(unitType.value), touchButtonSize)
                keepAspect = KEEP_ASPECT_FIT
                color = !isAvailable ? imageDisabledColor : imageColor
              }
            ]
          }
          mkActionGlare(actionItem)
          isDisabled.value ? null
            : mkGamepadShortcutImage(shortcutId, abShortcutImageOvr)
          mkConsumableSpend(animationKey)
        ]
      }
      mkActionItemCount(actionItem?.count ?? 0)
    ]
  }
}

let isActionAvailable = @(actionItem) (actionItem?.available ?? true)
  && (actionItem.count != 0 || actionItem?.control
    || (actionItem?.cooldownEndTime ?? 0) > get_mission_time())

let mkWaitForAimImage = @(isWaitForAim) {
  rendObj = ROBJ_IMAGE
  size = [aimImgWidth, aimImgHeight]
  pos = [0, 0.9 * aimImgHeight]
  vplace = ALIGN_BOTTOM
  image = aimImg
  keepAspect = KEEP_ASPECT_FIT
  opacity = isWaitForAim ? 1.0 : 0.0
  transitions = [{ prop = AnimProp.opacity, duration = 0.3, easing = Linear }]
}

function mkBtnZone(key) {
  let isVisible = Computed(@() !isGamepad.value && (userHoldWeapKeys.value?[key] ?? false))
  let isInside = Computed(@() userHoldWeapInside.value?[key] ?? true)
  return @() !isVisible.value ? { watch = isVisible }
    : {
        watch = isVisible
        size = [2 * zoneRadiusX, 2 * zoneRadiusY]
        vplace = ALIGN_CENTER
        hplace = ALIGN_CENTER
        children = @() {
          watch = isInside
          size = flex()
          rendObj = ROBJ_VECTOR_CANVAS
          color = isInside.value ? 0x20404040 : 0x20602020
          fillColor = 0
          lineWidth = hdpx(3)
          commands = [[VECTOR_ELLIPSE, 50, 50, 50, 50]]
          animations = [{ prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.5,
            easing = OutQuad, play = true }]
        }
      }
}

let weaponryItemStateFlags = {}
function getWeapStateFlags(key) {
  if (key not in weaponryItemStateFlags)
    weaponryItemStateFlags[key] <- Watched(0)
  return weaponryItemStateFlags[key]
}

let lowerCamera = @() lowerAircraftCamera(true)

let mkWeaponBlockReasonIcon = @(isAvailable, iconComponent) @() {
  watch = isAvailable
  pos = [0, hdpx(10)]
  vplace = ALIGN_BOTTOM
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = isAvailable.value
    ? [
      {
        rendObj = ROBJ_BOX
        size = [ touchButtonSize / 2, touchButtonSize / 2 ]
        fillColor = Color(255, 110, 110, 255)
        transform = { rotate = weaponryButtonRotate }
        borderWidth = 2
        borderColor = 0xFFDADADA
      },
      iconComponent
    ]
    : null
}

function mkWeaponryItem(buttonConfig, actionItem, ovr = {}) {
  if (actionItem == null)
    return null
  let { key, getShortcut, getImage, getAlternativeImage = @() null, selShortcut = null,
    hasAim = false, fireAnimKey = "fire", canShootWithoutTarget = true,
    needCheckTargetReachable = false, haptPatternId = -1, relImageSize = 1.0 , canLowerCamera = false, canShipLowerCamera = false,
    addChild = null, needCheckTargetRocket = false } = buttonConfig
  let imgSize = (relImageSize * defImageSize + 0.5).tointeger()
  let altImage = getAlternativeImage()
  let stateFlags = getWeapStateFlags(key)
  let hasReachableTarget = Computed(@() !needCheckTargetReachable || targetState.value == 0)
  let canShoot = Computed(@() (canShootWithoutTarget || hasTarget.value) && hasReachableTarget.value)

  let isAvailable = isActionAvailable(actionItem)
  let isBlocked = Computed(@() unitType.value == SUBMARINE && isNotOnTheSurface.value
    && (key == TRIGGER_GROUP_PRIMARY || key == TRIGGER_GROUP_SECONDARY))
  let isAltImage = (altImage ?? "") != "" && actionItem.count < (actionItem?.countEx ?? 0)
  let isWaitForAim = hasAim && !(actionItem?.aimReady ?? true)
  let isInDeadZone = hasAim && (actionItem?.inDeadzone ?? false)
  let mainShortcut = getShortcut(unitType.value, actionItem) //FIXME: Need to calculate shortcutId on the higher level where it really rebuild on change unit
  let hotkeyShortcut = selShortcut ?? mainShortcut
  let isDisabled = mkIsControlDisabled(mainShortcut)

  local isTouchPushed = false
  local isHotkeyPushed = false
  function onStopTouch() {
    isTouchPushed = false
    if (canLowerCamera) {
      clearTimer(lowerCamera)
      lowerAircraftCamera(false)
    }
    set_can_lower_camera(false)
    unmarkWeapKeyHold(key)
    setDrawWeaponAllowableAngles(false, -1)
    if (key in userHoldWeapInside.value)
      userHoldWeapInside.mutate(@(v) v.$rawdelete(key))
  }

  function onButtonReleaseWhileActiveZone() {
    onStopTouch()
    if (needCheckTargetRocket) {
      if (!hasTarget.value) {
        addCommonHint(loc("hints/select_enemy_to_shoot"))
        return
      } else if (isWaitForAim) {
        addCommonHint(loc("hints/select_cooldown_rocket"))
        return
      }
    }
    if (!canShoot.value) {
      if (targetState.value < 3) {
        addCommonHint(!needCheckTargetReachable || targetState.value == 0 ? loc("hints/select_enemy_to_shoot")
          : targetState.value == 1 ? loc("hints/submarine_deeper_periscope")
          : loc("hints/target_is_far_for_effective_hit", { dist = torpedoDistToLive.value }))
      }
      return
    }
    if (isWaitForAim) {
      if (isInDeadZone) {
        let deadzoneHintText = (buttonConfig?.actionType ?? -1) == AB_TORPEDO ? "hints/torpedoes_in_deadzone" : "hints/guns_in_deadzone"
        addCommonHint(loc(deadzoneHintText), "", "simpleText")
      } else
        addCommonHint(loc("hints/wait_for_aiming"))
      return
    }
    if (!isAvailable || isBlocked.value || (actionItem?.cooldownEndTime ?? 0) > get_mission_time())
      return
    anim_start(fireAnimKey)
    if (selShortcut != null)
      useShortcut(selShortcut)
    useShortcut(mainShortcut)
    playHapticPattern(haptPatternId)
  }

  function onButtonPush() {
    if (canLowerCamera)
      resetTimeout(0.3, lowerCamera)
    markWeapKeyHold(key)
    userHoldWeapInside.mutate(@(v) v[key] <- true)
  }

  function onTouchBegin() {
    isTouchPushed = true
    onButtonPush()
    if (canShipLowerCamera)
      set_can_lower_camera(true)
    if (isInDeadZone)
      setDrawWeaponAllowableAngles(true, actionItem?.triggerGroupNo ?? -1)
  }

  function onStatePush() {
    if (isTouchPushed)
      return
    isHotkeyPushed = true
    onButtonPush()
  }
  function onStateRelease() {
    if (!isHotkeyPushed)
      return
    isHotkeyPushed = false
    onButtonReleaseWhileActiveZone()
  }

  let res = mkContinuousButtonParams(onStatePush, onStateRelease, hotkeyShortcut, stateFlags)

  return @() res.__update({
    watch = isDisabled
    size = [touchButtonSize, touchButtonSize]
    behavior = Behaviors.TouchAreaOutButton
    eventPassThrough = mainShortcut != "ID_BOMBS"
    zoneRadiusX
    zoneRadiusY
    onTouchInsideChange = @(isInside) userHoldWeapInside.mutate(@(v) v[key] <- isInside)
    onTouchInterrupt = onStopTouch
    onTouchBegin
    onTouchEnd = onButtonReleaseWhileActiveZone
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [
      mkRhombBtnBg(isAvailable && !isDisabled.value, actionItem,
        @() playSound(key == TRIGGER_GROUP_PRIMARY ? "weapon_primary_ready" : "weapon_secondary_ready"))
      mkRhombBtnBorder(stateFlags, isAvailable && !isDisabled.value)
      mkBtnZone(key)
      @() {
        watch = [canShoot, unitType, isBlocked]
        rendObj = ROBJ_IMAGE
        size = [imgSize, imgSize]
        pos = [0, -hdpx(5)] //gap over amount text
        image = svgNullable(isAltImage ? altImage : getImage(unitType.value), imgSize)
        keepAspect = KEEP_ASPECT_FIT
        color = !isAvailable || isDisabled.value || (hasAim && !(actionItem?.aimReady ?? true)) || !canShoot.value || isBlocked.value
          ? imageDisabledColor
          : imageColor
      }
      mkAmmoCount(actionItem.count, !hasAim || (actionItem?.aimReady ?? true))
      hasAim ? mkWaitForAimImage(isWaitForAim) : null
      mkActionBtnGlare(actionItem)
      isDisabled.value ? null
        : mkGamepadShortcutImage(hotkeyShortcut, rotatedShortcutImageOvr)
      addChild
    ]
  }, ovr)
}

let groupsInAirByIdx = [groupIsInAir, group2IsInAir, group3IsInAir, group4IsInAir]

function mkPlaneItem(buttonConfig, actionItem, ovr = {}) {
  if (actionItem == null)
    return null
  let { key, getShortcut, getPlaneImage, groupInAirIdx = -1 } = buttonConfig
  let imgSize = (defImageSize + 0.5).tointeger()
  let stateFlags = getWeapStateFlags(key)
  let isAvailable = isActionAvailable(actionItem)
  let shortcutId = getShortcut(unitType.value, actionItem) //FIXME: Need to calculate shortcutId on the higher level where it really rebuild on change unit
  let isGroupInAir = groupsInAirByIdx?[groupInAirIdx] ?? Watched(false)

  return @() {
    watch = isGroupInAir
    size = [touchButtonSize, touchButtonSize]
    behavior = Behaviors.Button
    eventPassThrough = true
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    hotkeys = mkGamepadHotkey(shortcutId)
    onClick = @() toggleShortcut(shortcutId)
    onElemState = @(v) stateFlags(v)
    children = [
      mkRhombBtnBg(isAvailable, actionItem, @() playSound("weapon_secondary_ready"))
      mkRhombBtnBorder(stateFlags, isAvailable)
      isGroupInAir.value ? null : mkBtnZone(key)
      {
        rendObj = ROBJ_IMAGE
        size = isGroupInAir.value ? [imgSize * 1.15, imgSize * 1.15] : [imgSize, imgSize]
        pos = isGroupInAir.value ? [hdpx(3), 0] : [0, -hdpx(5)]
        image = svgNullable(getPlaneImage(isGroupInAir.value), imgSize)
        keepAspect = KEEP_ASPECT_FIT
        color = !isAvailable ? imageDisabledColor : imageColor
      }
      isGroupInAir.value ? null : mkAmmoCount(actionItem.count)
      mkActionBtnGlare(actionItem)
      mkGamepadShortcutImage(shortcutId, rotatedShortcutImageOvr)
    ]
  }.__update(ovr)
}

function mkWeaponryContinuous(buttonConfig, actionItem, ovr = {}) {
  if (actionItem == null)
    return null
  let { key, getShortcut, getImage, hasAim = false, haptPatternId = -1, relImageSize = 1.0, additionalShortcutId = {}
  } = buttonConfig
  let imgSize = (relImageSize * defImageSize + 0.5).tointeger()
  let stateFlags = Watched(0)
  let isAvailable = isActionAvailable(actionItem)
  let isBlocked = Computed(@() unitType.value == SUBMARINE && isNotOnTheSurface.value
    && (key == TRIGGER_GROUP_PRIMARY || key == TRIGGER_GROUP_SECONDARY))
  let shortcutId = getShortcut(unitType.value, actionItem) //FIXME: Need to calculate shortcutId on the higher level where it really rebuild on change unit

  let res = mkContinuousButtonParams(
    function onTouchBegin() {
      useShortcutOn(shortcutId)
      useShortcutOn(isChainedWeapons.value ? additionalShortcutId : "")
      playHapticPattern(haptPatternId)
    },
    function(){ setShortcutOff(shortcutId)
         setShortcutOff(isChainedWeapons.value ? additionalShortcutId : "")},
    shortcutId,
    stateFlags)
  return res.__update({
    size = [touchButtonSize, touchButtonSize]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    eventPassThrough = true
    children = [
      mkRhombBtnBg(isAvailable, actionItem,
        @() playSound(key == TRIGGER_GROUP_PRIMARY ? "weapon_primary_ready" : "weapon_secondary_ready"))
      mkRhombBtnBorder(stateFlags, isAvailable)
      @() {
        watch = [ unitType, isBlocked ]
        rendObj = ROBJ_IMAGE
        size = [imgSize, imgSize]
        pos = [0, -hdpx(5)] //gap over amount text
        image = svgNullable(getImage(unitType.value), imgSize)
        keepAspect = KEEP_ASPECT_FIT
        color = !isAvailable || (hasAim && !(actionItem?.aimReady ?? true)) || isBlocked.value
          ? imageDisabledColor
          : imageColor
      }
      mkAmmoCount(actionItem.count, !hasAim || (actionItem?.aimReady ?? true))
      hasAim ? mkWaitForAimImage(!(actionItem?.aimReady ?? true)) : null
      mkActionBtnGlare(actionItem)
      mkGamepadShortcutImage(shortcutId, rotatedShortcutImageOvr)
    ]
  }, ovr)
}

function mkWeaponryItemSelfAction(buttonConfig, _actionItem, ovr = {}) {
  let { itemComputed } = buttonConfig
  return @() {
    watch = itemComputed
    children = mkWeaponryItem(buttonConfig, itemComputed.value)
  }.__update(ovr)
}

function mkWeaponryContinuousSelfAction(buttonConfig, _actionItem, ovr = {}) {
  let { itemComputed } = buttonConfig
  return @() { watch = itemComputed }
    .__update(mkWeaponryContinuous(buttonConfig, itemComputed.value, ovr) ?? {})
}

let mkWeaponRightBlock = @(content) {
  pos = [pw(30), 0]
  vplace = ALIGN_CENTER
  hplace = ALIGN_RIGHT
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    {
      size = [weaponNumberSize, weaponNumberSize]
      rendObj = ROBJ_BOX
      fillColor = 0xFFFFFFFF
      borderColor = wNumberColor
      borderWidth = [hdpx(3)]
      transform = { rotate = 45 }
    }
    content
  ]
}

let weaponNumber = @(number) mkWeaponRightBlock({
  rendObj = ROBJ_TEXT
  color = wNumberColor
  text = getRomanNumeral(number + 1)
}.__update(fontVeryTiny))

let changeMarkSize = hdpxi(20)
let weaponChangeMark = mkWeaponRightBlock({
  size = [changeMarkSize, changeMarkSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#cursor_size_hor.svg:{changeMarkSize}:{changeMarkSize}")
  color = wNumberColor
  keepAspect = true
})

function weaponRightBlockPrimary(number, curBulletIdxW) {
  if (curBulletIdxW == null)
    return weaponNumber(number)
  let isNeedChange = Computed(@() curBulletIdxW.value != nextBulletIdx.value)
  return @() { watch = isNeedChange }.__update(
    isNeedChange.value ? weaponChangeMark
      : number >= 0 ? weaponNumber(number)
      : {})
}

let curBulletIdxByTrigger = {
  [TRIGGER_GROUP_PRIMARY] = currentBulletIdxPrim,
  [TRIGGER_GROUP_SECONDARY] = currentBulletIdxSec,
}

let periscopIconWidth = touchButtonSize / 2
let periscopIconHeight = (periscopIconWidth * 0.7).tointeger()
let periscopIcon = {
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#hud_periscope.svg:{periscopIconWidth}:{periscopIconHeight}:P")
  size = [ periscopIconWidth, periscopIconHeight ]
}

function mkSubmarineWeaponryItem(buttonConfig, actionItem, ovr = {}) {
  local btnCfg = {
    addChild = mkWeaponBlockReasonIcon(Computed(@()
      unitType.value == SUBMARINE && isDeeperThanPeriscopeDepth.value), periscopIcon)
  }
  return mkWeaponryItem(buttonConfig.__merge(btnCfg), actionItem, ovr)
}

let surfacingIconSize = (touchButtonSize / 2 * 0.8).tointeger()
let surfacingIcon = {
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#hud_submarine_surfacing.svg:{surfacingIconSize}:{surfacingIconSize}:P")
  size = [ surfacingIconSize, surfacingIconSize ]
}

function mkWeaponryItemByTrigger(buttonConfig, actionItem, ovr = {}) {
  let { trigger, sizeOrder, number, shortcut, selShortcut = null } = buttonConfig
  let { image, relImageSize = 1.0 } = gunImageBySizeOrder?[sizeOrder] ?? gunImageBySizeOrder.top()
  local btnCfg = {
    key = trigger
    selShortcut
    getShortcut = @(_, __) shortcut
    getImage = @(_) image
    relImageSize
    hasAim = true
    hasCrosshair = true
    addChild = mkWeaponBlockReasonIcon(Computed(@()
      unitType.value == SUBMARINE && isNotOnTheSurface.value), surfacingIcon)
  }
  let key = $"btn_weapon_{trigger}"
  let isMainCaliber = sizeOrder == 0
  return number < 0 && (trigger not in curBulletIdxByTrigger)
    ? mkWeaponryItem(btnCfg, actionItem, ovr.__merge({ key }))
    : {
        key
        size = [touchButtonSize, touchButtonSize]
        children = [
          mkWeaponryItem(btnCfg, actionItem)
          isMainCaliber ? weaponRightBlockPrimary(number, curBulletIdxByTrigger?[trigger])
            : number >= 0 ? weaponNumber(number)
            : null
        ]
      }.__update(ovr)
}

function mkSimpleButton(buttonConfig, actionItem, ovr = {}) {
  let stateFlags = Watched(0)
  let { image, getShortcut, relImageSize = 1.0 } = buttonConfig
  let imgSize = (relImageSize * defImageSize + 0.5).tointeger()
  let shortcutId = getShortcut(unitType.value, actionItem) //FIXME: Need to calculate shortcutId on the higher level where it really rebuild on change unit
  return {
    behavior = Behaviors.Button
    eventPassThrough = true
    size = [touchButtonSize, touchButtonSize]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    onClick = @() toggleShortcut(shortcutId)
    onElemState = @(v) stateFlags(v)
    hotkeys = mkGamepadHotkey(shortcutId)
    children = [
      @() {
        watch = stateFlags
        size = flex()
        rendObj = ROBJ_BOX
        borderColor = (stateFlags.value & S_ACTIVE) != 0 ? borderColorPushed : borderColor
        borderWidth = [hdpx(3)]
        fillColor = btnBgColor.empty
        transform = { rotate = 45 }
      }
      {
        rendObj = ROBJ_IMAGE
        size = [imgSize, imgSize]
        image = Picture($"{image}:{imgSize}:{imgSize}")
        keepAspect = KEEP_ASPECT_FIT
      }
      mkGamepadShortcutImage(shortcutId, rotatedShortcutImageOvr)
    ]
  }.__update(ovr)
}

let hasTargetCandidateTrigger = {}
hasTargetCandidate.subscribe(@(v) v && !hasTarget.value ? anim_start(hasTargetCandidateTrigger) : null)

function mkFlagButton(getShortcut, iconComp, ovr) {
  let shortcutId = getShortcut(unitType.value, null) //FIXME: Need to calculate shortcutId on the higher level where it really rebuild on change unit
  let stateFlags = Watched(0)
  return {
    key = shortcutId
    size = [touchButtonSize, touchButtonSize]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    behavior = Behaviors.Button
    eventPassThrough = true
    onElemState = @(v) stateFlags(v)
    onClick = @() toggleShortcut(shortcutId)
    hotkeys = mkGamepadHotkey(shortcutId)
    children = [
      @() {
        watch = stateFlags
        size = flex()
        rendObj = ROBJ_BOX
        borderColor = (stateFlags.value & S_ACTIVE) != 0 ? borderColorPushed : borderColor
        borderWidth = [hdpx(3)]
        fillColor = btnBgColor.empty
        transform = { rotate = 45 }
      }
      iconComp
      mkGamepadShortcutImage(shortcutId, rotatedShortcutImageOvr)
    ]
  }.__update(ovr)
}

let targetTrackingImgSize = (0.63 * touchButtonSize).tointeger()
let targetTrackingImage = Picture($"ui/gameuiskin#hud_target_tracking.svg:{targetTrackingImgSize}:{targetTrackingImgSize}")
let targetTrackingOffImgSize = (0.79 * touchButtonSize).tointeger()
let targetTrackingOffImage = Picture($"ui/gameuiskin#hud_target_tracking_off.svg:{targetTrackingOffImgSize}:{targetTrackingOffImgSize}")

let canLock = Computed(@() ((hasTargetCandidate.value && !hasTarget.value) || hasTarget.value ))

let lockButtonIcon = @(){
  watch = [hasTarget, canLock]
  rendObj = ROBJ_IMAGE
  size = hasTarget.value ? [targetTrackingImgSize, targetTrackingImgSize] : [targetTrackingOffImgSize, targetTrackingOffImgSize]
  image = hasTarget.value ? targetTrackingImage : targetTrackingOffImage
  keepAspect = KEEP_ASPECT_FIT
  color = canLock.value ? imageColor : textDisabledColor
}

function mkLockButtonImpl(getShortcut, ovr) {
  let shortcutId = getShortcut(unitType.value, null) //FIXME: Need to calculate shortcutId on the higher level where it really rebuild on change unit
  let stateFlags = Watched(0)
  return {
    key = shortcutId
    size = [touchButtonSize, touchButtonSize]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    behavior = Behaviors.Button
    eventPassThrough = true
    onElemState = @(v) stateFlags(v)
    onClick = @() toggleShortcut(shortcutId)
    hotkeys = mkGamepadHotkey(shortcutId)
    children = [
      @() {
        watch = [stateFlags, canLock]
        size = flex()
        rendObj = ROBJ_BOX
        borderColor = (stateFlags.value & S_ACTIVE) != 0 ? borderColorPushed : canLock.value ? borderColor: borderNoAmmoColor
        borderWidth = [hdpx(3)]
        fillColor = btnBgColor.empty
        transform = { rotate = 45 }
      }
      lockButtonIcon
      mkGamepadShortcutImage(shortcutId, rotatedShortcutImageOvr)
      mkBtnGlare(hasTargetCandidateTrigger)
    ]
  }.__update(ovr)
}

let mkFlagImage = @(flag, iconOn, iconOnSize, iconOff, iconOffSize) @() {
  watch = flag
  rendObj = ROBJ_IMAGE
  size = flag.value ? [iconOnSize, iconOnSize] : [iconOffSize, iconOffSize]
  image = flag.value ? iconOn : iconOff
  keepAspect = KEEP_ASPECT_FIT
  color = imageColor
}

let mkLockButton = @(buttonConfig, _, ovr = {}) mkLockButtonImpl(buttonConfig.getShortcut, ovr)

let groupAttackIconComp = mkFlagImage(groupAttack, zoomImage, zoomImgSize, binocularsImage, zoomImgSize)
let mkGroupAttackButton = @(buttonConfig, _, ovr = {}) mkFlagButton(buttonConfig.getShortcut, groupAttackIconComp, ovr)

function mkDivingLockButton(buttonConfig, actionItem, ovr = {}) {
  let { getShortcut } = buttonConfig
  let stateFlags = Watched(0)
  let shortcutId = getShortcut(unitType.value, actionItem) //FIXME: Need to calculate shortcutId on the higher level where it really rebuild on change unit
  let isInCooldown = (actionItem?.cooldownEndTime ?? 0) > get_mission_time()
  return {
    key = shortcutId
    behavior = Behaviors.Button
    eventPassThrough = true
    size = [touchButtonSize, touchButtonSize]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    onClick = @() toggleShortcut(shortcutId)
    hotkeys = mkGamepadHotkey(shortcutId)
    onElemState = @(v) stateFlags(v)
    children = [
      mkRhombBtnBg(true, actionItem)
      mkRhombBtnBorder(stateFlags, !isInCooldown)
      @() {
        rendObj = ROBJ_IMAGE
        size = [zoomImgSize, zoomImgSize]
        image = (actionItem?.active ?? true) ? divingImage : surfacingImage
        keepAspect = KEEP_ASPECT_FIT
        color = imageColor
      }
      mkActionBtnGlare(actionItem)
      mkGamepadShortcutImage(shortcutId, rotatedShortcutImageOvr)
    ]
  }.__update(ovr)
}

function mkZoomButton(buttonConfig, actionItem, ovr = {}) {
  let { getShortcut } = buttonConfig
  let stateFlags = Watched(0)
  let shortcutId = getShortcut(unitType.value, actionItem) //FIXME: Need to calculate shortcutId on the higher level where it really rebuild on change unit
  let isDisabled = mkIsControlDisabled(shortcutId)
  return @() {
    watch = [ canZoom, isDisabled, hasAimingModeForWeapon, isInZoom, unitType ]
    key = "btn_zoom"
    behavior = Behaviors.Button
    eventPassThrough = true
    size = [touchButtonSize, touchButtonSize]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    function onClick() {
      if (isDisabled.value)
        return
      if (canZoom.value && ((hasAimingModeForWeapon.value) ||
          (isInZoom.value && !hasAimingModeForWeapon.value))) {
        toggleShortcut(shortcutId)
        return
      }

      if (!canZoom.value) {
        addCommonHint(loc("hints/select_enemy_to_aim"))
        return
      }

      addCommonHint(loc("hints/aiming_not_available_for_weapon"))
    }
    onElemState = @(v) stateFlags(v)
    hotkeys = mkGamepadHotkey(shortcutId)
    children = [
      @() {
        watch = [stateFlags, isDisabled, isInZoom, hasAimingModeForWeapon]
        size = flex()
        rendObj = ROBJ_BOX
        borderColor = (stateFlags.value & S_ACTIVE) != 0 ? borderColorPushed
          : (canZoom.value && !isDisabled.value && (isInZoom.value || hasAimingModeForWeapon.value)) ? borderColor
          : borderNoAmmoColor
        borderWidth
        fillColor = btnBgColor.empty
        transform = { rotate = 45 }
      }
      {
        rendObj = ROBJ_IMAGE
        size = [zoomImgSize, zoomImgSize]
        image = isInZoom.value ? zoomImage : binocularsImage
        keepAspect = KEEP_ASPECT_FIT
        color = (canZoom.value && !isDisabled.value && (isInZoom.value || hasAimingModeForWeapon.value))
          ? imageColor
          : imageDisabledColor
      }
      isDisabled.value ? null
        : mkGamepadShortcutImage(shortcutId, rotatedShortcutImageOvr)
    ]
  }.__update(ovr)
}

return {
  mkWeaponryItem
  mkWeaponryItemSelfAction
  mkWeaponryContinuousSelfAction
  mkWeaponryItemByTrigger
  mkSubmarineWeaponryItem
  mkActionItem
  mkRepairActionItem
  mkIRCMActionItem
  mkSimpleButton
  mkDivingLockButton
  mkLockButton
  mkGroupAttackButton
  mkZoomButton
  mkPlaneItem

  mkActionItemEditView
  mkBulletEditView

  defImageSize
}
