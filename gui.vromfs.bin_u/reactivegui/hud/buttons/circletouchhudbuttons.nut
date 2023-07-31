from "%globalsDarg/darg_library.nut" import *
let { playSound } = require("sound_wt")
let { btnBgColor, borderColorPushed, borderNoAmmoColor, borderColor
} = require("%rGui/hud/hudTouchButtonStyle.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { toggleShortcut, setShortcutOn, setShortcutOff } = require("%globalScripts/controls/shortcutActions.nut")
let { updateActionBarDelayed } = require("%rGui/hud/actionBar/actionBarState.nut")
let { canZoom, isInZoom } = require("%rGui/hudState.nut")
let { addCommonHint } = require("%rGui/hudHints/commonHintLogState.nut")
let { mkGamepadShortcutImage, mkGamepadHotkey, mkContinuousButtonParams
} = require("%rGui/controls/shortcutSimpleComps.nut")
let { weaponTouchIcons } = require("%appGlobals/weaponPresentation.nut")
let { gradTranspDoubleSideX } = require("%rGui/style/gradients.nut")
let { allowShoot } = require("%rGui/hud/tankState.nut")

let bigButtonSize = hdpxi(150)
let bigButtonImgSize = (0.65 * bigButtonSize + 0.5).tointeger()
let buttonSize = hdpxi(120)
let buttonImgSize = (0.65 * buttonSize + 0.5).tointeger()
let aimImageSize = hdpxi(80)
let disabledColor = 0x4D4D4D4D

let isActionAvailable = @(actionItem) (actionItem?.available ?? true)
  && (actionItem.count != 0 || actionItem?.control
    || (actionItem?.cooldownEndTime ?? 0) > ::get_mission_time())

let function useShortcut(shortcutId) {
  toggleShortcut(shortcutId)
  updateActionBarDelayed()
}

let function useShortcutOn(shortcutId) {
  setShortcutOn(shortcutId)
  updateActionBarDelayed()
}

let mkBtnBg = @(size, color) {
  size = [size, size]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#hud_bg_round_bg.svg:{size}:{size}")
  color
}

let function mkCircleProgressBg(size, actionItem, onFinishExt = @() playSound("weapon_primary_ready")) {
  let { available = true, cooldownEndTime = 0, cooldownTime = 1 } = actionItem

  let misTime = ::get_mission_time()
  let hasCooldown = available && cooldownEndTime > misTime
  let cooldownLeft = hasCooldown ? cooldownEndTime - misTime : 0
  let animations = [
    {
      prop = AnimProp.scale, duration = 0.2,
      from = [1.0, 1.0], to = [1.2, 1.2], easing = CosineFull,
      trigger = $"action_cd_finish_{actionItem?.id}"
    }
  ]
  if (hasCooldown)
    animations.append({
      prop = AnimProp.fValue, duration = cooldownLeft, play = true,
      from = 1.0 - (cooldownLeft / max(cooldownTime, 1.0)), to = 1.0,
      function onFinish() {
        onFinishExt()
        anim_start($"action_cd_finish_{actionItem?.id}")
      }
    })

  let { empty, ready, broken, noAmmo } = btnBgColor
  return {
    key = $"action_bg_{actionItem?.id}_{cooldownEndTime}"
    size = [size, size]
    rendObj = ROBJ_PROGRESS_CIRCULAR
    image = Picture($"ui/gameuiskin#hud_bg_round_bg.svg:{size}:{size}:P")
    fgColor = !isActionAvailable(actionItem) ? noAmmo
      : (actionItem?.broken ?? false) ? broken
      : ready
    bgColor = empty
    fValue = 1.0
    transform = {}
    animations
  }
}

let mkBtnBorder = @(size, isAvailable, stateFlags) @() {
  watch = stateFlags
  size = [size, size]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#hud_bg_round_border.svg:{size}:{size}:P")
  color = stateFlags.value & S_ACTIVE ? borderColorPushed
    : !isAvailable ? borderNoAmmoColor
    : borderColor
}

let function mkCircleGlare(baseSize, actionItem) {
  let size = (1.15 * baseSize).tointeger()
  let trigger = $"action_cd_finish_{actionItem?.id}"
  return {
    size = [size, size]
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    rendObj = ROBJ_MASK
    image = Picture($"ui/gameuiskin#hud_bg_round_glare_mask.svg:{size}:{size}:P")
    clipChildren = true
    children = {
      size = [0.4 * size, 2 * size]
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      rendObj = ROBJ_IMAGE
      image = gradTranspDoubleSideX
      color = 0x00A0A0A0
      transform = { rotate = 25, translate = [-size, -size] }
      animations = [{
        prop = AnimProp.translate, from = [-size, -size], to = [0.5 * size, 0.5 * size], duration = 0.4,
        delay = 0.05, trigger
      }]
    }

    transform = { scale = [0.0, 0.0] } //zero size mask will not render. So just optimization
    animations = [{ prop = AnimProp.scale, from = [1.0, 1.0], to = [1.0, 1.0], duration = 0.5, trigger }]
  }
}

let mkBtnImage = @(size, image, color = 0xFFFFFFFF) {
  rendObj = ROBJ_IMAGE
  size = [size, size]
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  image = Picture($"{image}:{size}:{size}")
  keepAspect = KEEP_ASPECT_FIT
  color
}

let countTextStyle = {
  rendObj = ROBJ_TEXT
  vplace = ALIGN_BOTTOM
  fontFxColor = 0xFF000000
  fontFxFactor = 50
  fontFx = FFT_GLOW
}.__update(fontVeryTiny)

let mkCountTextRight = @(text, color)
  countTextStyle.__merge({
    pos = [pw(80), ph(-90)]
    color
    text
  })

let mkCountTextLeft = @(text, color)
  countTextStyle.__merge({
    hplace = ALIGN_RIGHT
    pos = [pw(-80), ph(-90)]
    color
    text
  })

let waitForAimIcon = {
  rendObj = ROBJ_IMAGE
  size = [aimImageSize, aimImageSize]
  pos = [0, 0.5 * aimImageSize]
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_CENTER
  valign = ALIGN_BOTTOM
  image = Picture($"ui/gameuiskin#hud_debuff_rotation.svg:{aimImageSize}:{aimImageSize}")
  keepAspect = KEEP_ASPECT_FIT
  animations = wndSwitchAnim
}

let defShortcutOvr = { hplace = ALIGN_CENTER, vplace = ALIGN_CENTER, pos = [0, ph(-50)] }

let primStateFlags = Watched(0) //same state flags for all primary buttons on the screen
let primGroup = ElemGroup()
let mkCircleTankPrimaryGun = @(actionItem, key = "btn_weapon_primary", countCtor = mkCountTextLeft) function() {
  let isAvailable = isActionAvailable(actionItem)
  let { count, countEx, isBulletBelt = false } = actionItem
  let isWaitForAim = !(actionItem?.aimReady ?? true)
  let isWaitToShoot = !allowShoot.value
  let color = !isAvailable || isWaitToShoot ? disabledColor : 0xFFFFFFFF
  let isContinuous = actionItem.isBulletBelt
  let image = weaponTouchIcons?[actionItem.weaponName] ?? "ui/gameuiskin#hud_main_weapon_fire.svg"
  let function onTouchBegin() {
    if (isWaitForAim && isWaitToShoot)
      addCommonHint(loc("hints/wait_for_aiming"))
    else if (isActionAvailable(actionItem)) {
      if (isContinuous)
        useShortcutOn("ID_FIRE_GM")
      else
        useShortcut("ID_FIRE_GM")
    }
  }

  let res = isContinuous
    ? mkContinuousButtonParams(onTouchBegin, @() setShortcutOff("ID_FIRE_GM"), "ID_FIRE_GM", primStateFlags)
        .__update({
          behavior = Behaviors.TouchAreaOutButton
          eventPassThrough = true
        })
    : {
        behavior = Behaviors.Button
        onElemState = @(v) primStateFlags(v)
        hotkeys = mkGamepadHotkey("ID_FIRE_GM")
        onClick = onTouchBegin
      }

  return res.__update({ //warning disable: -unwanted-modification
    watch = allowShoot
    key
    size = [bigButtonSize, bigButtonSize]
    group = primGroup
    children = [
      mkCircleProgressBg(bigButtonSize, actionItem)
      mkBtnBorder(bigButtonSize, isAvailable, primStateFlags)
      mkBtnImage(bigButtonImgSize, image, color)
      count < 0 ? null : countCtor(isBulletBelt ? $"{count}/{countEx}" : count, color)
      isWaitForAim ? waitForAimIcon : null
      mkCircleGlare(bigButtonSize, actionItem)
      mkGamepadShortcutImage("ID_FIRE_GM", defShortcutOvr)
    ]
  })
}

let mkCircleTankMachineGun = @(actionItem) function() {
  let isAvailable = isActionAvailable(actionItem)
  let isWaitForAim = !(actionItem?.aimReady ?? true)
  let isWaitToShoot = !allowShoot.value
  let color = !isAvailable || isWaitToShoot ? disabledColor : 0xFFFFFFFF
  let stateFlags = Watched(0)
  let res = mkContinuousButtonParams(
    function onTouchBegin() {
      if (isWaitForAim && isWaitToShoot)
        addCommonHint(loc("hints/wait_for_aiming"))
      else if (isActionAvailable(actionItem))
        useShortcutOn("ID_FIRE_GM_MACHINE_GUN")
    },
    @() setShortcutOff("ID_FIRE_GM_MACHINE_GUN"),
    "ID_FIRE_GM_MACHINE_GUN",
    stateFlags
  )

  return res.__update({
    watch = allowShoot
    key = "btn_machinegun"
    size = [buttonSize, buttonSize]
    behavior = Behaviors.TouchAreaOutButton
    eventPassThrough = true
    children = [
      mkCircleProgressBg(buttonSize, actionItem)
      mkBtnBorder(buttonSize, isAvailable, stateFlags)
      mkBtnImage(buttonImgSize, "ui/gameuiskin#hud_aircraft_machine_gun.svg", color)
      actionItem.count < 0 ? null : mkCountTextLeft(actionItem.count, color)
      isWaitForAim ? waitForAimIcon : null
      mkGamepadShortcutImage("ID_FIRE_GM_MACHINE_GUN", defShortcutOvr)
    ]
  })
}

let mkCircleTankSecondaryGun = @(shortcutId, img = null) @(actionItem) function() {
  let isAvailable = isActionAvailable(actionItem)
  let isWaitForAim = !(actionItem?.aimReady ?? true)
  let isWaitToShoot = !allowShoot.value
  let color = !isAvailable || isWaitToShoot ? disabledColor : 0xFFFFFFFF
  let stateFlags = Watched(0)
  let image = weaponTouchIcons?[actionItem.weaponName] ?? img
  let res = mkContinuousButtonParams(
    function onTouchBegin() {
      if (isWaitForAim && isWaitToShoot)
        addCommonHint(loc("hints/wait_for_aiming"))
      else if (isActionAvailable(actionItem))
        useShortcutOn(shortcutId)
    },
    @() setShortcutOff(shortcutId),
    shortcutId,
    stateFlags
  )

  return res.__update({
    watch = allowShoot
    key = "btn_weapon_secondary"
    size = [buttonSize, buttonSize]
    children = [
      mkCircleProgressBg(buttonSize, actionItem)
      mkBtnBorder(buttonSize, isAvailable, stateFlags)
      mkBtnImage(buttonImgSize, image,  color)
      actionItem.count < 0 ? null : mkCountTextLeft(actionItem.count, color)
      isWaitForAim ? waitForAimIcon : null
      mkGamepadShortcutImage(shortcutId, defShortcutOvr)
    ]
  })
}

let function mkCircleZoom() {
  let stateFlags = Watched(0)
  let imgSize = (0.9 * buttonSize).tointeger()
  return @() {
    watch = [canZoom, isInZoom]
    key = "btn_zoom_circle"
    size = [buttonSize, buttonSize]
    behavior = Behaviors.Button
    hotkeys = mkGamepadHotkey("ID_ZOOM_TOGGLE")
    function onClick() {
      if (canZoom.value)
        toggleShortcut("ID_ZOOM_TOGGLE")
      else
        addCommonHint(loc("hints/select_enemy_to_aim"))
    }
    onElemState = @(v) stateFlags(v)
    children = [
      mkBtnBg(buttonSize, btnBgColor.empty)
      mkBtnBorder(buttonSize, canZoom.value, stateFlags)
      mkBtnImage(imgSize,
        isInZoom.value ? "ui/gameuiskin#hud_binoculars_zoom.svg" : "ui/gameuiskin#hud_binoculars.svg")
      mkGamepadShortcutImage("ID_ZOOM_TOGGLE", defShortcutOvr)
    ]
  }
}

let function mkSimpleCircleTouchBtn(image, shortcutId, ovr = {}) {
  let stateFlags = Watched(0)
  let imgSize = (0.9 * buttonSize).tointeger()
  return @() {
    watch = [canZoom, isInZoom]
    key = "btn_zoom_circle"
    size = [buttonSize, buttonSize]
    behavior = Behaviors.TouchScreenButton
    hotkeys = mkGamepadHotkey(shortcutId)
    onTouchBegin = @() useShortcutOn(shortcutId)
    onTouchEnd = @() setShortcutOff(shortcutId)
    onElemState = @(v) stateFlags(v)
    children = [
      mkBtnBg(buttonSize, btnBgColor.empty)
      mkBtnBorder(buttonSize, true, stateFlags)
      mkBtnImage(imgSize, image)
      mkGamepadShortcutImage(shortcutId, defShortcutOvr)
    ]
  }.__update(ovr)
}

return {
  mkCircleTankPrimaryGun
  mkCircleTankMachineGun
  mkCircleTankSecondaryGun
  mkCircleZoom
  mkSimpleCircleTouchBtn
  mkCountTextRight
}