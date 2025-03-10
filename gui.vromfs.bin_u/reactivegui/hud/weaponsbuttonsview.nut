from "%globalsDarg/darg_library.nut" import *
let { TouchAreaOutButton } = require("wt.behaviors")
let { get_mission_time } = require("mission")
let { defer, resetTimeout } = require("dagor.workcycle")
let { round } =  require("math")
let { setDrawWeaponAllowableAngles } = require("hudState")
let { activateActionBarAction } = require("hudActionBar")
let { getRomanNumeral, ceil } = require("%sqstd/math.nut")
let { getScaledFont, scaleFontWithTransform } = require("%globalsDarg/fontScale.nut")
let { scaleArr } = require("%globalsDarg/screenMath.nut")
let { toggleShortcut, setShortcutOn, setShortcutOff } = require("%globalScripts/controls/shortcutActions.nut")
let { updateActionBarDelayed } = require("actionBar/actionBarState.nut")
let { touchButtonSize, touchSizeForRhombButton, borderWidth, btnBgColor, imageColor, imageDisabledColor,
  borderColor, borderColorPushed, zoneRadiusX, zoneRadiusY
} = require("%rGui/hud/hudTouchButtonStyle.nut")
let { markWeapKeyHold, unmarkWeapKeyHold, userHoldWeapInside
} = require("%rGui/hud/currentWeaponsStates.nut")
let { hasTarget, targetState, torpedoDistToLive, unitType, isInAntiairMode
} = require("%rGui/hudState.nut")
let { playHapticPattern } = require("hapticVibration")
let { fire, isFullBuoyancy, isAsmCaptureAllowed } = require("%rGui/hud/shipState.nut")
let { playSound } = require("sound_wt")
let { addCommonHint } = require("%rGui/hudHints/commonHintLogState.nut")
let { nextBulletIdx, currentBulletIdxPrim, currentBulletIdxSec
} = require("bullets/hudUnitBulletsState.nut")
let { AB_TORPEDO } = require("actionBar/actionType.nut")
let { mkGamepadShortcutImage, mkGamepadHotkey, mkContinuousButtonParams
} = require("%rGui/controls/shortcutSimpleComps.nut")
let { mkActionGlare, mkConsumableSpend, mkActionBtnGlare
} = require("%rGui/hud/weaponsButtonsAnimations.nut")
let { isNotOnTheSurface, isDeeperThanPeriscopeDepth } = require("%rGui/hud/submarineDepthBlock.nut")
let { TANK, SHIP, BOAT, SUBMARINE } = require("%appGlobals/unitConst.nut")
let { set_can_lower_camera } = require("controlsOptions")
let { mkIsControlDisabled } = require("%rGui/controls/disabledControls.nut")
let { mkRhombBtnBg, mkRhombBtnBorder, mkAmmoCount } = require("%rGui/hud/buttons/rhombTouchHudButtons.nut")
let { mkBtnZone } = require("%rGui/hud/buttons/hudButtonsPkg.nut")
let { getOptValue, OPT_HAPTIC_INTENSITY_ON_SHOOT } = require("%rGui/options/guiOptions.nut")
let { isAvailableActionItem, mkActionItemProgress, mkActionItemCount, mkActionItemImage,
  countHeightUnderActionItem, mkActionItemBorder, abShortcutImageOvr
} = require("buttons/actionButtonComps.nut")

let defImageSize = (0.75 * touchButtonSize).tointeger()
let weaponNumberSize = (0.3 * touchButtonSize).tointeger()
let wNumberColor = 0xFF1C9496

let aimImgWidth = (0.8 * touchButtonSize).tointeger()
let aimImgHeight = (0.44 * aimImgWidth).tointeger()
let debuffImgSize = (0.6 * touchButtonSize).tointeger()
let periscopIconWidth = touchButtonSize / 2
let periscopIconHeight = (periscopIconWidth * 0.7).tointeger()
let surfacingIconSize = (touchButtonSize * 0.4).tointeger()
let changeMarkSize = hdpxi(20)

let gunImageBySizeOrder = [
  { image = "ui/gameuiskin#hud_ship_calibre_main_3_left.svg", relImageSize = 1.3 }
  { image = "ui/gameuiskin#hud_ship_calibre_medium.svg" }
]

let svgNullable = @(image, size) ((image ?? "") == "") ? null
  : Picture($"{image}:{size}:{size}:P")

let weaponryButtonRotate = 45
let rotatedShortcutImageOvr = { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = [0, ph(-70)] }

function useShortcut(shortcutId) {
  toggleShortcut(shortcutId)
  updateActionBarDelayed()
}

function useShortcutOn(shortcutId) {
  setShortcutOn(shortcutId)
  updateActionBarDelayed()
}

function mkActionItem(buttonConfig, actionItem, scale) {
  if (actionItem == null)
    return null
  let { getShortcut, getImage, haptPatternId = -1, key = null, sound = "", getAnimationKey = null, alternativeImage = null } = buttonConfig
  let { shortcutIdx = -1 } = actionItem
  let stateFlags = Watched(0)
  let isAvailable = isAvailableActionItem(actionItem)
  let shortcutId = getShortcut(unitType.value, actionItem) //FIXME: Need to calculate shortcutId on the higher level where it really rebuild on change unit
  let isDisabled = mkIsControlDisabled(shortcutId)
  let animationKey = getAnimationKey ? getAnimationKey(unitType.value) : null
  let btnSize = scaleEven(touchButtonSize, scale)
  let footerHeight = round(countHeightUnderActionItem * scale).tointeger()
  let borderW = round(borderWidth * scale).tointeger()
  return {
    size = [btnSize, btnSize + footerHeight]
    flow = FLOW_VERTICAL
    children = [
      @() {
        watch = isDisabled
        key = key ?? shortcutId
        behavior = Behaviors.Button
        cameraControl = true
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        size = [btnSize, btnSize]
        function onClick() {
          if ((actionItem?.cooldownEndTime ?? 0) > get_mission_time() || isDisabled.value)
            return
          if (actionItem?.available)
            playSound(sound)
          activateActionBarAction(shortcutIdx)
          playHapticPattern(haptPatternId)
        }
        hotkeys = mkGamepadHotkey(shortcutId)
        onElemState = @(v) stateFlags(v)
        children = [
          mkActionItemProgress(actionItem, isAvailable && !isDisabled.value)
          mkActionItemBorder(borderW, stateFlags, isAvailable ? isDisabled : Watched(true))
          mkActionItemImage(actionItem?.isAlternativeImage ? alternativeImage : getImage,
            isAvailable && !isDisabled.value,
            btnSize)
          mkActionGlare(actionItem, btnSize)
          isDisabled.value ? null
            : mkGamepadShortcutImage(shortcutId, abShortcutImageOvr, scale)
          mkConsumableSpend(animationKey)
        ]
      }
      mkActionItemCount(actionItem.count, scale)
    ]
  }
}

function mkCountermeasureItem(buttonConfig, actionItem, scale) {
  if (actionItem == null)
    return null
  let { getShortcut, getImage, alternativeImage = null, haptPatternId = -1, key = null, sound = "", getAnimationKey = null } = buttonConfig
  let stateFlags = Watched(0)
  let isAvailable = isAvailableActionItem(actionItem)
  let shortcutId = getShortcut(unitType.value, actionItem) //FIXME: Need to calculate shortcutId on the higher level where it really rebuild on change unit
  let isDisabled = mkIsControlDisabled(shortcutId)
  let animationKey = getAnimationKey ? getAnimationKey(unitType.value) : null
  let endTime = actionItem?.inProgressEndTime ?? 0.0
  let beginTime = endTime - (actionItem?.inProgressTime ?? 0.0)
  let progress = Watched(null)
  let progressTime = Watched(null)
  defer(@() progressTime.set([beginTime, endTime]))

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

  let font = getScaledFont(fontVeryTiny, scale)
  let progressText = @() {
    watch = progress
    rendObj = ROBJ_TEXT
    pos = [0, -hdpx(30)]
    vplace = ALIGN_TOP
    halign = ALIGN_CENTER
    text = progress.get() ? progress.get() : ""
  }.__update(font)

  let btnSize = scaleEven(touchButtonSize, scale)
  let footerHeight = round(countHeightUnderActionItem * scale).tointeger()
  let borderW = round(borderWidth * scale).tointeger()
  return {
    size = [btnSize, btnSize + footerHeight]
    flow = FLOW_VERTICAL
    children = [
      @() {
        watch = [isDisabled, progressTime]
        key = key ?? shortcutId
        size = [btnSize, btnSize]
        behavior = Behaviors.Button
        cameraControl = true
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
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        children = [
          progressTime.get() ? progressText : null
          mkActionItemProgress(actionItem, isAvailable && !isDisabled.value)
          mkActionItemBorder(borderW,
            Computed(@() progressTime.get() ? S_ACTIVE : stateFlags.get()),
            isAvailable ? isDisabled : Watched(true))
          mkActionItemImage(alternativeImage && actionItem?.isAlternativeImage ? alternativeImage : getImage,
            isAvailable && !isDisabled.value,
            btnSize)
          mkActionGlare(actionItem, btnSize)
          isDisabled.value ? null
            : mkGamepadShortcutImage(shortcutId, abShortcutImageOvr, scale)
          mkConsumableSpend(animationKey)
        ]
      }
      mkActionItemCount(actionItem.count, scale)
    ]
  }
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
      res.append("hud_debuff_fire.svg")
    if (!isFullBuoyancy.value)
      res.append("hud_debuff_water.svg")
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

function mkRepairActionItem(buttonConfig, actionItem, scale) {
  let { getShortcut, getImage, haptPatternId = -1, actionKey = "btn_repair", getAnimationKey = null } = buttonConfig
  let { shortcutIdx = -1 } = actionItem
  let stateFlags = Watched(0)
  let isAvailable = actionItem != null && isAvailableActionItem(actionItem)
  let isInCooldown = (actionItem?.cooldownEndTime ?? 0) > get_mission_time()
  let shortcutId = actionItem == null ? null
    : getShortcut(unitType.value, actionItem) //FIXME: Need to calculate shortcutId on the higher level where it really rebuild on change unit
  let isDisabled = mkIsControlDisabled(shortcutId)
  let animationKey = getAnimationKey ? getAnimationKey(unitType.value) : null
  let hotkey = (unitType.value != TANK || isAvailable) ? shortcutId : null
  let btnSize = scaleEven(touchButtonSize, scale)
  let debuffSize = scaleEven(debuffImgSize, scale)
  let footerHeight = round(countHeightUnderActionItem * scale).tointeger()
  let borderW = round(borderWidth * scale).tointeger()
  return {
    size = [btnSize, btnSize + footerHeight]
    flow = FLOW_VERTICAL
    children = [
      @() {
        watch = isDisabled
        key = actionKey
        behavior = Behaviors.Button
        cameraControl = true
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        size = [btnSize, btnSize]
        function onClick() {
          if (actionItem == null) {
            addCommonHint(loc("hint/noItemsForRepair"))
            return
          }
          if ((actionItem?.cooldownEndTime ?? 0) > get_mission_time() || isDisabled.value || !isAvailable)
            return
          playSound("repair")
          activateActionBarAction(shortcutIdx)
          playHapticPattern(haptPatternId)
        }
        hotkeys = mkGamepadHotkey(hotkey)
        onElemState = @(v) stateFlags(v)
        children = [
          mkActionItemProgress(actionItem, (isAvailable || isInCooldown) && !isDisabled.value)
          mkActionItemBorder(borderW, stateFlags, isAvailable ? isDisabled : Watched(true))
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
                    image = Picture($"ui/gameuiskin#hud_circle_animation.svg:{btnSize}:{btnSize}:P")
                    keepAspect = KEEP_ASPECT_FIT
                    color = isInCooldown ? 0
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
              curRepairImageIdx.get() in debuffImages.get()
                ? {
                    size = [debuffSize, debuffSize]
                    rendObj = ROBJ_IMAGE
                    image = Picture($"ui/gameuiskin#{debuffImages.get()[curRepairImageIdx.value]}:{debuffSize}:{debuffSize}:P")
                    keepAspect = KEEP_ASPECT_FIT
                    color = !isAvailable ? imageDisabledColor : imageColor
                  }
                : {
                    size = [btnSize, btnSize]
                    rendObj = ROBJ_IMAGE
                    image = svgNullable(getImage(unitType.value), btnSize)
                    keepAspect = KEEP_ASPECT_FIT
                    color = !isAvailable ? imageDisabledColor : imageColor
                  }
            ]
          }
          mkActionGlare(actionItem)
          isDisabled.value ? null
            : mkGamepadShortcutImage(shortcutId, abShortcutImageOvr, scale)
          mkConsumableSpend(animationKey)
        ]
      }
      mkActionItemCount(actionItem?.count ?? 0, scale)
    ]
  }
}

let isActionAvailable = @(actionItem) (actionItem?.available ?? true)
  && (actionItem.count != 0 || actionItem?.control
    || (actionItem?.cooldownEndTime ?? 0) > get_mission_time())

function mkWaitForAimImage(isWaitForAim, scale) {
  let w = scaleEven(aimImgWidth, scale)
  let h = scaleEven(aimImgHeight, scale)
  return {
    size = [w, h]
    pos = [0, 0.9 * h]
    vplace = ALIGN_BOTTOM
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#hud_debuff_rotation.svg:{w}:{h}:P")
    keepAspect = KEEP_ASPECT_FIT
    opacity = isWaitForAim ? 1.0 : 0.0
    transitions = [{ prop = AnimProp.opacity, duration = 0.3, easing = Linear }]
  }
}

let weaponryItemStateFlags = {}
function getWeapStateFlags(key) {
  if (key not in weaponryItemStateFlags)
    weaponryItemStateFlags[key] <- Watched(0)
  return weaponryItemStateFlags[key]
}

let mkWeaponBlockReasonIcon = @(isAvailable, iconComponent, scale) @() {
  watch = isAvailable
  pos = [0, hdpx(10 * scale)]
  vplace = ALIGN_BOTTOM
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = !isAvailable.get() ? null
    : [
        {
          size = array(2, scaleEven(touchButtonSize, scale) / 2)
          rendObj = ROBJ_BOX
          fillColor = Color(255, 110, 110, 255)
          transform = { rotate = weaponryButtonRotate }
          borderWidth = 2
          borderColor = 0xFFDADADA
        },
        iconComponent
      ]
}

let mkWeaponRightBlock = @(scale, content) {
  pos = [pw(30), 0]
  vplace = ALIGN_CENTER
  hplace = ALIGN_RIGHT
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    {
      size = array(2, round(weaponNumberSize * scale))
      rendObj = ROBJ_BOX
      fillColor = 0xFFFFFFFF
      borderColor = wNumberColor
      borderWidth = round(borderWidth * scale).tointeger()
      transform = { rotate = 45 }
    }
    content
  ]
}

let weaponNumber = @(number, scale) mkWeaponRightBlock(scale,
  {
    rendObj = ROBJ_TEXT
    color = wNumberColor
    text = getRomanNumeral(number + 1)
  }.__update(scaleFontWithTransform(fontVeryTiny, scale, [0.5, 0.5])))

function mkWeaponryItem(buttonConfig, actionItem, scale) {
  if (actionItem == null)
    return null
  let { key, getShortcut, getImage, alternativeImage = null, selShortcut = null,
    hasAim = false, fireAnimKey = "fire", canShootWithoutTarget = true,
    needCheckTargetReachable = false, haptPatternId = -1, relImageSize = 1.0 , canShipLowerCamera = false,
    addChild = null, needCheckRocket = false, number = -1  } = buttonConfig
  let stateFlags = getWeapStateFlags(key)
  let hasReachableTarget = Computed(@() !needCheckTargetReachable || targetState.value == 0)
  let canShoot = Computed(@() (canShootWithoutTarget || hasTarget.value) && hasReachableTarget.value)

  let isAvailable = isActionAvailable(actionItem)
  let isBlocked = Computed(@() unitType.value == SUBMARINE && isNotOnTheSurface.value
    && (key == TRIGGER_GROUP_PRIMARY || key == TRIGGER_GROUP_SECONDARY))
  let isWaitForAim = hasAim && !(actionItem?.aimReady ?? true)
  let isInDeadZone = hasAim && (actionItem?.inDeadzone ?? false)
  let mainShortcut = getShortcut(unitType.value, actionItem) //FIXME: Need to calculate shortcutId on the higher level where it really rebuild on change unit
  let hotkeyShortcut = selShortcut ?? mainShortcut
  let isDisabled = mkIsControlDisabled(mainShortcut)
  let isBulletBelt = actionItem?.isBulletBelt
    && (key == TRIGGER_GROUP_PRIMARY || key == TRIGGER_GROUP_MACHINE_GUN)
  let vibrationMult = getOptValue(OPT_HAPTIC_INTENSITY_ON_SHOOT)

  local isTouchPushed = false
  local isHotkeyPushed = false

  function onStopTouch() {
    isTouchPushed = false
    set_can_lower_camera(false)
    unmarkWeapKeyHold(key)
    setDrawWeaponAllowableAngles(false, -1)
    if (key in userHoldWeapInside.value)
      userHoldWeapInside.mutate(@(v) v.$rawdelete(key))
    if(isBulletBelt)
      setShortcutOff(mainShortcut)
  }

  function onButtonReleaseWhileActiveZone() {
    onStopTouch()
    if(isBulletBelt)
      return
    if (needCheckRocket) {
      if (!isAsmCaptureAllowed.value) {
        addCommonHint(loc("hints/submarine_deeper_periscope"))
        return
      }
      if (!hasTarget.value) {
        addCommonHint(loc("hints/select_enemy_to_shoot"))
        return
      }
      if (isWaitForAim) {
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
    playHapticPattern(haptPatternId, vibrationMult)
  }

  function onButtonPush() {
    if(isBulletBelt) {
      if (!isAvailable || isBlocked.value || (actionItem?.cooldownEndTime ?? 0) > get_mission_time())
        return
      anim_start(fireAnimKey)
      useShortcutOn(mainShortcut)
      playHapticPattern(haptPatternId, vibrationMult)
    }
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

  let behavior = [TouchAreaOutButton]

  let btnSize = scaleEven(touchButtonSize, scale)
  let btnTouchSize = scaleEven(touchSizeForRhombButton, scale)
  let imgSize = scaleEven(relImageSize * defImageSize, scale)
  let zRadiusX = scaleEven(zoneRadiusX, scale)
  let zRadiusY = scaleEven(zoneRadiusY, scale)
  return @() {
    watch = isDisabled
    size = [btnSize, btnSize]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [
      mkRhombBtnBg(isAvailable && !isDisabled.value, actionItem, scale,
        @() playSound(key == TRIGGER_GROUP_PRIMARY ? "weapon_primary_ready" : "weapon_secondary_ready"))
      mkRhombBtnBorder(stateFlags, isAvailable && !isDisabled.value, scale)
      mkBtnZone(key, zRadiusX, zRadiusY)
      @() {
        watch = [canShoot, unitType, isBlocked]
        rendObj = ROBJ_IMAGE
        size = [imgSize, imgSize]
        pos = [0, -hdpx(5)] //gap over amount text
        image = svgNullable(alternativeImage && actionItem?.isAlternativeImage ? alternativeImage : getImage(unitType.value), imgSize)
        keepAspect = KEEP_ASPECT_FIT
        color = !isAvailable || isDisabled.value || (hasAim && !(actionItem?.aimReady ?? true)) || !canShoot.value || isBlocked.value
          ? imageDisabledColor
          : imageColor
      }
      mkAmmoCount(actionItem.count, scale, !hasAim || (actionItem?.aimReady ?? true))
      hasAim ? mkWaitForAimImage(isWaitForAim, scale) : null
      mkActionBtnGlare(actionItem, btnSize)
      isDisabled.value ? null
        : mkGamepadShortcutImage(hotkeyShortcut, rotatedShortcutImageOvr, scale)
      addChild
      number != -1 ? weaponNumber(number, scale) : null
      mkContinuousButtonParams(onStatePush, onStateRelease, hotkeyShortcut, stateFlags,
        isBulletBelt && (!isAvailable || isBlocked.value || (actionItem?.cooldownEndTime ?? 0) > get_mission_time()),  onStopTouch).__update({
        size = [btnTouchSize, btnTouchSize]
        behavior
        cameraControl = mainShortcut != "ID_BOMBS"
        zoneRadiusX = zRadiusX
        zoneRadiusY = zRadiusY
        onTouchInsideChange = @(isInside) userHoldWeapInside.mutate(@(v) v[key] <- isInside)
        onTouchInterrupt = onStopTouch
        onTouchBegin
        onTouchEnd = onButtonReleaseWhileActiveZone
      })
    ]
  }
}

function weaponRightBlockPrimary(number, curBulletIdxW, scale) {
  if (curBulletIdxW == null)
    return weaponNumber(number, scale)
  let isNeedChange = Computed(@() curBulletIdxW.value != nextBulletIdx.value)
  let changeSize = scaleEven(changeMarkSize, scale)
  let weaponChangeMark = mkWeaponRightBlock(scale, {
    size = [changeSize, changeSize]
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#cursor_size_hor.svg:{changeSize}:{changeSize}")
    color = wNumberColor
    keepAspect = true
  })
  return @() { watch = isNeedChange }.__update(
    isNeedChange.value ? weaponChangeMark
      : number >= 0 ? weaponNumber(number, scale)
      : {})
}

let curBulletIdxByTrigger = {
  [TRIGGER_GROUP_PRIMARY] = currentBulletIdxPrim,
  [TRIGGER_GROUP_SECONDARY] = currentBulletIdxSec,
}

let periscopIcon = @(size) {
  size
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#hud_periscope.svg:{size[0]}:{size[1]}:P")
}

function mkSubmarineWeaponryItem(buttonConfig, actionItem, scale) {
  let { needCheckRocket = false } = buttonConfig
  local btnCfg = {
    addChild = mkWeaponBlockReasonIcon(
      Computed(@() unitType.value == SUBMARINE
        && (needCheckRocket ? !isAsmCaptureAllowed.value : isDeeperThanPeriscopeDepth.value)),
      periscopIcon(scaleArr([periscopIconWidth, periscopIconHeight], scale)),
      scale)
  }
  return mkWeaponryItem(buttonConfig.__merge(btnCfg), actionItem, scale)
}

let surfacingIcon = @(size) {
  size = [size, size]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#hud_submarine_surfacing.svg:{size}:{size}:P")
}

function mkWeaponryItemByTrigger(buttonConfig, actionItem, scale) {
  let { trigger, sizeOrder, number, shortcut, selShortcut = null } = buttonConfig
  let { image, relImageSize = 1.0 } =
    trigger != TRIGGER_GROUP_MACHINE_GUN ? gunImageBySizeOrder?[sizeOrder] ?? gunImageBySizeOrder.top()
    : isInAntiairMode.get() ? { image = "ui/gameuiskin#hud_anti_air_def_fire.svg" }
    : { image = "ui/gameuiskin#hud_aircraft_machine_gun.svg" }
  local btnCfg = {
    key = trigger
    selShortcut
    getShortcut = @(_, __) shortcut
    getImage = @(_) image
    relImageSize
    hasAim = true
    hasCrosshair = true
    addChild = mkWeaponBlockReasonIcon(
      Computed(@() unitType.value == SUBMARINE && isNotOnTheSurface.value),
      surfacingIcon(scaleEven(surfacingIconSize, scale)),
      scale)
  }
  let isMainCaliber = sizeOrder == 0
  let btnSize = scaleEven(touchButtonSize, scale)
  return {
    key = $"btn_weapon_{trigger}"
    size = [btnSize, btnSize]
    children = [
      mkWeaponryItem(btnCfg, actionItem, scale)
      number < 0 && (trigger not in curBulletIdxByTrigger) ? null
        : isMainCaliber ? weaponRightBlockPrimary(number, curBulletIdxByTrigger?[trigger], scale)
        : number >= 0 ? weaponNumber(number, scale)
        : null
    ]
  }
}

function mkSimpleButton(buttonConfig, actionItem, scale) {
  let stateFlags = Watched(0)
  let { image, getShortcut, relImageSize = 1.0 } = buttonConfig
  let shortcutId = getShortcut(unitType.value, actionItem) //FIXME: Need to calculate shortcutId on the higher level where it really rebuild on change unit
  let imgSize = scaleEven(relImageSize * defImageSize, scale)
  let btnSize = scaleEven(touchButtonSize, scale)
  let borderW = round(borderWidth * scale).tointeger()
  return {
    behavior = Behaviors.Button
    cameraControl = true
    size = [btnSize, btnSize]
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
        borderWidth = borderW
        fillColor = btnBgColor.empty
        transform = { rotate = 45 }
      }
      {
        rendObj = ROBJ_IMAGE
        size = [imgSize, imgSize]
        image = Picture($"{image}:{imgSize}:{imgSize}:P")
        keepAspect = KEEP_ASPECT_FIT
      }
      mkGamepadShortcutImage(shortcutId, rotatedShortcutImageOvr, scale)
    ]
  }
}

return {
  mkWeaponryItem
  mkWeaponryItemByTrigger
  mkSubmarineWeaponryItem
  mkActionItem
  mkRepairActionItem
  mkCountermeasureItem
  mkSimpleButton

  mkBulletEditView

  defImageSize
}
