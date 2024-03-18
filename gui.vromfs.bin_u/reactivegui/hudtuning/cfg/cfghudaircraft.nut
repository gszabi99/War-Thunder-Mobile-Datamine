from "%globalsDarg/darg_library.nut" import *
let { allow_voice_messages } = require("%appGlobals/permissions.nut")
let { set_chat_handler = null } = require("chat")
let { missionPlayVoice = null } = require("sound_wt")
let { isInMpSession } = require("%appGlobals/clientState/clientState.nut")
let { mkZoomButton, mkLockButton, mkWeaponryItemSelfAction, mkWeaponryContinuousSelfAction, mkSimpleButton, mkGroupAttackButton
} = require("%rGui/hud/weaponsButtonsView.nut")
let { mkWeaponBtnEditView } = require("%rGui/hudTuning/weaponBtnEditView.nut")
let { Z_ORDER, mkLBPos, mkLTPos, mkRBPos, mkRTPos, mkCTPos,
  weaponryButtonCtor, weaponryButtonsGroupCtor, weaponryButtonsChainedCtor } = require("hudTuningPkg.nut")
let { touchButtonSize } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { mkSimpleChainIcon } = require("%rGui/hud/weaponryBlockImpl.nut")
let {
  aircraftMovement,
  aircraftIndicators,
  aircraftMovementEditView,
  aircraftIndicatorsEditView
} = require("%rGui/hud/aircraftMovementBlock.nut")
let { voiceMsgStickBlock, voiceMsgStickView } = require("%rGui/hud/voiceMsg/voiceMsgStick.nut")
let { aircraftRadarEditView, aircraftRadar } = require("%rGui/hud/aircraftRadar.nut")
let cfgHudCommon = require("cfgHudCommon.nut")
let { hitCamera, hitCameraCommonEditView } = require("%rGui/hud/hitCamera/hitCamera.nut")
let mkFreeCameraButton = require("%rGui/hud/buttons/freeCameraButton.nut")
let mkSquareBtnEditView = require("%rGui/hudTuning/squareBtnEditView.nut")
let { mkMyPlace, myPlaceUi, mkMyScores, myScoresUi } = require("%rGui/hud/myScores.nut")
let { doll, dollEditView } = require("%rGui/hud/aircraftStateModule.nut")

let allow_voice_messages_compatibility = Computed(@() allow_voice_messages.get() && !!set_chat_handler && !!missionPlayVoice)

return cfgHudCommon.__merge({
  bomb = weaponryButtonCtor("ID_BOMBS", mkWeaponryItemSelfAction,
    {
      defTransform = mkLBPos([hdpx(108), hdpx(-220)])
      editView = mkWeaponBtnEditView("ui/gameuiskin#hud_bomb.svg")
      priority = Z_ORDER.BUTTON_PRIMARY
    })

  rocket = weaponryButtonCtor("ID_ROCKETS", mkWeaponryItemSelfAction,
    {
      defTransform = mkLBPos([hdpx(108), hdpx(-5)])
      editView = mkWeaponBtnEditView("ui/gameuiskin#hud_rb_rocket.svg", 0.8)
      priority = Z_ORDER.BUTTON_PRIMARY
    })

  guns = weaponryButtonsChainedCtor(["ID_FIRE_MGUNS", "ID_FIRE_CANNONS"], mkWeaponryContinuousSelfAction,
    {
      defTransform = mkLBPos([hdpx(216), hdpx(-5)])
      editView = {
        size = [touchButtonSize * 2, touchButtonSize * 2]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = [
          mkWeaponBtnEditView("ui/gameuiskin#hud_aircraft_machine_gun.svg", 1,
            { pos = [- touchButtonSize * 0.5, - touchButtonSize * 0.5] })
          mkSimpleChainIcon
          mkWeaponBtnEditView("ui/gameuiskin#hud_aircraft_canons.svg", 1,
            { pos = [touchButtonSize * 0.5, touchButtonSize * 0.5] })
        ]
      }
    })

  lock = weaponryButtonCtor("ID_LOCK_TARGET", mkLockButton,
    {
      defTransform = mkLBPos([hdpx(325), hdpx(-220)])
      editView = mkWeaponBtnEditView("ui/gameuiskin#hud_target_tracking_off.svg", 1.05)
    })

  zoom = weaponryButtonCtor("ID_ZOOM", mkZoomButton,
    {
      defTransform = mkLBPos([hdpx(216), hdpx(-330)])
      editView = mkWeaponBtnEditView("ui/gameuiskin#hud_binoculars.svg", 1.34)
    })
//












  groupReturn = weaponryButtonCtor("ID_WTM_AIRCRAFT_RETURN", mkSimpleButton,
    {
      defTransform = mkLBPos([hdpx(431), hdpx(-335)])
      editView = mkWeaponBtnEditView("ui/gameuiskin#hud_aircraft_fighter.svg")
    })

  back = weaponryButtonsGroupCtor([
      "ID_WTM_RETURN_TO_SHIP",
      "ID_WTM_RETURN_TO_SHIP_2",
      "ID_WTM_RETURN_TO_SHIP_3",
      "ID_WTM_RETURN_TO_SHIP_4"
    ],
    mkSimpleButton,
    {
      defTransform = mkLBPos([hdpx(433), hdpx(-113)])
      editView = mkWeaponBtnEditView("ui/gameuiskin#hud_ship_selection.svg")
    })

  hitCamera = {
    ctor = @() hitCamera
    defTransform = mkRTPos([0, 0])
    editView = hitCameraCommonEditView
    hideForDelayed = false
  }

  radar = {
    ctor = @() aircraftRadar
    defTransform = mkLTPos([hdpx(105), 0])
    editView = aircraftRadarEditView
    hideForDelayed = false
  }

  myPlace = {
    ctor = @() myPlaceUi
    defTransform = isWidescreen ? mkCTPos([hdpx(290), 0]) : mkRTPos([-hdpx(90), hdpx(260)])
    editView = mkMyPlace(1)
    hideForDelayed = false
  }

  myScores = {
    ctor = @() myScoresUi
    defTransform = isWidescreen ? mkCTPos([hdpx(380), 0]) : mkRTPos([0, hdpx(260)])
    editView = mkMyScores(22100)
    hideForDelayed = false
  }

  doll = {
    ctor = @() doll
    defTransform = mkLBPos([hdpx(580), hdpx(30)])
    editView = dollEditView
    hideForDelayed = false
  }

  voiceCmdStick = {
    ctor = @() voiceMsgStickBlock
    defTransform = mkRBPos([0, hdpx(-27)])
    editView = voiceMsgStickView
    isVisibleInEditor = allow_voice_messages_compatibility
    isVisibleInBattle = Computed(@() allow_voice_messages_compatibility.get() && isInMpSession.get())
    priority = Z_ORDER.STICK
  }

  movement = {
    ctor = @() aircraftMovement
    defTransform = mkRBPos([hdpx(-140), 0])
    editView = aircraftMovementEditView
    priority = Z_ORDER.STICK
  }

  indicators = {
    ctor = @() aircraftIndicators
    defTransform = mkRBPos([0, hdpx(-290)])
    editView = aircraftIndicatorsEditView
    hideForDelayed = false
  }

  freeCameraButton = {
    ctor = mkFreeCameraButton
    defTransform = mkLTPos([hdpx(0), hdpx(450)])
    editView = mkSquareBtnEditView("ui/gameuiskin#hud_free_camera.svg")
    priority = Z_ORDER.BUTTON
  }
})
