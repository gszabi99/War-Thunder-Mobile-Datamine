from "%globalsDarg/darg_library.nut" import *
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { loadUnitWeaponSlots, loadUnitBulletsChoice } = require("%rGui/weaponry/loadUnitBullets.nut")

function mkBattleResultUnitWeaponry(unitName) {
  let weaponPresets = {}
  let unitWeaponSlots = loadUnitWeaponSlots(unitName)
  foreach (ws in unitWeaponSlots) {
    foreach (wpId, wp in ws.wPresets)
      if (wp?.reqModification != "")
        weaponPresets[wpId] <- wp.__merge({ banPresets = wp.banPresets
          .reduce(@(res, v, k) res.$rawset(k.tostring(), v), {})})
  }

  let ammoForWeapons = {}
  let unitBulletsChoice = loadUnitBulletsChoice(unitName)
  foreach (bc in unitBulletsChoice) {
    foreach (weaponId, weapon in bc) {
      let { fromUnitTags = {} } = weapon
      local needAdd = false
      foreach (b in fromUnitTags)
        if ((b?.reqModification ?? "") != "" || (b?.reqLevel ?? 0) != 0) {
          needAdd = true
          break
        }
      if (needAdd)
        ammoForWeapons[weaponId] <- weapon
    }
  }

  return { weaponPresets, ammoForWeapons }
}

function sendBattleResultUnitWeaponry(unitsList) {
  let p = unitsList.map(@(unitName) [ unitName, mkBattleResultUnitWeaponry(unitName) ]).totable()
  eventbus_send("BattleResultUnitWeaponry", p)
}

eventbus_subscribe("RequestBattleResultUnitWeaponry", @(p) sendBattleResultUnitWeaponry(p.units))
