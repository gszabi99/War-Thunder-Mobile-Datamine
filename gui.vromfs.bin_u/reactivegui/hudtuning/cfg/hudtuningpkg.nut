from "%globalsDarg/darg_library.nut" import *
let { ALIGN_RB, ALIGN_LB, ALIGN_RT, ALIGN_LT, ALIGN_CT, ALIGN_CB } = require("%rGui/hudTuning/hudTuningConsts.nut")
let { actionBarItems, emptyActionItem } = require("%rGui/hud/actionBar/actionBarState.nut")
let weaponsButtonsConfig = require("%rGui/hud/weaponsButtonsConfig.nut")
let { visibleWeaponsDynamic } = require("%rGui/hud/currentWeaponsStates.nut")
let weaponsButtonsView = require("%rGui/hud/weaponsButtonsView.nut")
let { mkNumberedWeaponEditView } = require("%rGui/hudTuning/weaponBtnEditView.nut")
let { mkActionItemEditView } = require("%rGui/hud/buttons/actionButtonComps.nut")
let { hudMode, HM_COMMON } = require("%rGui/hudState.nut")

enum Z_ORDER {
  DEFAULT
  BUTTON
  BUTTON_PRIMARY
  SLIDER
  STICK
  SUPERIOR
}

let withActionButtonScaleCtor = @(aType, actionCtor, cfg) {
  function ctor(scale) {
    let action = Computed(@() actionBarItems.get()?[aType]
      ?? (cfg?.shouldShowDisabled ? emptyActionItem : null))
    return @() {
      watch = action
      children = action.get() == null ? null : actionCtor(action.get(), scale)
    }
  }
  priority = Z_ORDER.BUTTON
}.__update(cfg)

function withActionBarButtonCtor(config, unitType, cfg) {
  let { actionType, mkButtonFunction, getImage } = config
  let ctor = weaponsButtonsView[mkButtonFunction]
  return withActionButtonScaleCtor(actionType, @(v, scale) ctor(config, v, scale), {
    editView = mkActionItemEditView(getImage(unitType))
    priority = Z_ORDER.BUTTON
  }.__update(cfg))
}

function withAnyActionBarButtonCtor(configsList, unitType, cfg) {
  let aTypesList = configsList.map(@(c) c.actionType)
  return {
    function ctor(scale) {
      let aType = Computed(@() aTypesList.findvalue(@(t) t in actionBarItems.get()) ?? aTypesList[0])
      let action = Computed(@() actionBarItems.get()?[aType.get()])
      let configW = Computed(@() configsList.findvalue(@(c) c.actionType == aType.get()))
      return @() {
        watch = [action, configW]
        children = action.get() == null ? null
          : weaponsButtonsView[configW.get().mkButtonFunction](configW.get(), action.get(), scale)
      }
    }
    editView = mkActionItemEditView(configsList[0].getImage(unitType))
    priority = Z_ORDER.BUTTON
  }.__update(cfg)
}

let weaponryButtonDynamicCtor = @(idx, cfg) {
  function ctor(scale) {
    let currentWeapon = Computed(@() visibleWeaponsDynamic.get()?[idx])
    let actionItem = Computed(@() currentWeapon.get()?.actionItem)
    let buttonConfig = Computed(@() currentWeapon.get()?.buttonConfig)
    let isVisibleInHudMode = Computed(@()(currentWeapon.get()?.hudMode ?? HM_COMMON) & hudMode.get())
    return @() {
      watch = [currentWeapon, actionItem, buttonConfig, isVisibleInHudMode]
      children = !currentWeapon.get() || !isVisibleInHudMode.get() ? null
        : weaponsButtonsView?[
            buttonConfig.get()?.mkButtonFunction ?? weaponsButtonsConfig?[currentWeapon.get()?.id]?.mkButtonFunction
          ] (buttonConfig.get() ?? weaponsButtonsConfig?[currentWeapon.get()?.id], actionItem.get(), scale)
    }
  }
}.__update({
  editView = mkNumberedWeaponEditView("ui/gameuiskin#hud_ship_calibre_main_3_left.svg", idx + 1)
  priority = Z_ORDER.BUTTON
}, cfg)

let mkRBPos = @(pos) {
  pos
  align = ALIGN_RB
}

let mkLBPos = @(pos) {
  pos
  align = ALIGN_LB
}

let mkRTPos = @(pos) {
  pos
  align = ALIGN_RT
}

let mkLTPos = @(pos) {
  pos
  align = ALIGN_LT
}

let mkCTPos = @(pos) {
  pos
  align = ALIGN_CT
}

let mkCBPos = @(pos) {
  pos
  align = ALIGN_CB
}

return {
  Z_ORDER

  withActionButtonScaleCtor
  withActionBarButtonCtor
  withAnyActionBarButtonCtor
  weaponryButtonDynamicCtor

  mkRBPos
  mkLBPos
  mkRTPos
  mkLTPos
  mkCTPos
  mkCBPos
}
