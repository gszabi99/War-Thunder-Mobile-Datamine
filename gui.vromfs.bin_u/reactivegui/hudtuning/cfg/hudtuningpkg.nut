from "%globalsDarg/darg_library.nut" import *
let { ALIGN_RB, ALIGN_LB, ALIGN_RT, ALIGN_LT, ALIGN_CT, ALIGN_CB } = require("%rGui/hudTuning/hudTuningConsts.nut")
let { actionBarItems } = require("%rGui/hud/actionBar/actionBarState.nut")
let weaponsButtonsConfig = require("%rGui/hud/weaponsButtonsConfig.nut")
let { visibleWeaponsMap, visibleWeaponsDynamic } = require("%rGui/hud/currentWeaponsStates.nut")
let { mkChainedWeapons } = require("%rGui/hud/weaponryBlockImpl.nut")
let weaponsButtonsView = require("%rGui/hud/weaponsButtonsView.nut")
let { mkNumberedWeaponEditView } = require("%rGui/hudTuning/weaponBtnEditView.nut")

let withActionButtonCtor = @(aType, actionCtor, cfg) cfg.__update({
  function ctor() {
    let action = Computed(@() actionBarItems.value?[aType])
    return @() {
      watch = action
      children = action.value == null ? null : actionCtor(action.value)
    }
  }
})

let function withActionBarButtonCtor(config, unitType, cfg) {
  let { actionType, mkButtonFunction, getImage } = config
  let ctor = weaponsButtonsView[mkButtonFunction]
  return withActionButtonCtor(actionType, @(v) ctor(config, v), cfg.__update({ // warning disable: -unwanted-modification
    editView = weaponsButtonsView.mkActionItemEditView(getImage(unitType))
  }))
}

let function withAnyActionBarButtonCtor(configsList, unitType, cfg) {
  let aTypesList = configsList.map(@(c) c.actionType)
  return cfg.__update({ // warning disable: -unwanted-modification
    function ctor() {
      let aType = Computed(@() aTypesList.findvalue(@(t) t in actionBarItems.value) ?? aTypesList[0])
      let action = Computed(@() actionBarItems.value?[aType.value])
      let configW = Computed(@() configsList.findvalue(@(c) c.actionType == aType.value))
      return @() {
        watch = [action, configW]
        children = action.value == null ? null
          : weaponsButtonsView[configW.value.mkButtonFunction](configW.value, action.value)
      }
    }
    editView = weaponsButtonsView.mkActionItemEditView(configsList[0].getImage(unitType))
  })
}

let function weaponryButtonCtor(id, actionCtor, cfg) {
  if (id not in weaponsButtonsConfig) {
    logerr($"Error using weaponryButtonCtor: {id} is not in weaponsButtonsConfig")
    return cfg
  }
  return cfg.__merge({
    function ctor() {
      let isVisible = Computed(@() id in visibleWeaponsMap.value)
      let actionItem = Computed(@() visibleWeaponsMap.value?[id].actionItem)
      let buttonConfig = weaponsButtonsConfig?[id]
      return @() {
        watch = [actionItem, isVisible]
        children = !isVisible.value ? null : actionCtor(buttonConfig, actionItem.value)
      }
    }
  })}

let weaponryButtonDynamicCtor = @(idx, cfg) cfg.__update({
  function ctor() {
    let currentWeapon = Computed(@() visibleWeaponsDynamic.value?[idx])
    let actionItem = Computed(@() currentWeapon.value?.actionItem)
    let buttonConfig = Computed(@() currentWeapon.value?.buttonConfig)

    return @() {
      watch = [currentWeapon, actionItem, buttonConfig]
      children = !currentWeapon.value ? null
        : weaponsButtonsView?[buttonConfig.value?.mkButtonFunction
          ?? weaponsButtonsConfig?[currentWeapon.value?.id]?.mkButtonFunction] (
            buttonConfig.value ?? weaponsButtonsConfig?[currentWeapon.value?.id], actionItem.value)
    }
  }
},
{ editView = mkNumberedWeaponEditView("ui/gameuiskin#hud_ship_calibre_main_3_left.svg", idx + 1) })

let function weaponryButtonsGroupCtor(ids, actionCtor, cfg) {
  if (ids.findindex(@(id) id not in weaponsButtonsConfig) != null) {
    logerr("Error using weaponryButtonsGroupCtor: id is not in weaponsButtonsConfig")
    return cfg
  }
  return cfg.__merge({
    function ctor() {
      let id = Computed(@() ids.findvalue(@(i) i in visibleWeaponsMap.value))
      let actionItem = Computed(@() visibleWeaponsMap.value?[id.value].actionItem)
      let buttonConfig = Computed(@() weaponsButtonsConfig?[id.value])
      return @() {
        watch = [actionItem, buttonConfig]
        children = buttonConfig.value == null ? null : actionCtor(buttonConfig.value, actionItem.value)
      }
    }
  })}

let function weaponryButtonsChainedCtor(ids, actionCtor, cfg) {
  if (ids.findindex(@(id) id not in weaponsButtonsConfig) != null) {
    logerr("Error using weaponryButtonsChainedCtor: id is not in weaponsButtonsConfig")
    return cfg
  }
  return cfg.__merge({
    function ctor() {
      let visibleIds = Computed(@() ids.filter(@(id) id in visibleWeaponsMap.value))
      return @() {
        watch = visibleIds
        children = mkChainedWeapons(actionCtor, visibleIds.value)
      }
    }
  })}

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
  withActionButtonCtor
  withActionBarButtonCtor
  withAnyActionBarButtonCtor
  weaponryButtonCtor
  weaponryButtonDynamicCtor
  weaponryButtonsGroupCtor
  weaponryButtonsChainedCtor

  mkRBPos
  mkLBPos
  mkRTPos
  mkLTPos
  mkCTPos
  mkCBPos
}
