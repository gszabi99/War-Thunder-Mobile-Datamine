from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "controls" import setVirtualAxisValue, setAxisValue
from "dagor.math" import Point2, norm_s_ang
from "dagor.workcycle" import deferOnce
from "eventbus" import eventbus_subscribe
from "hangar" import hangar_enable_controls, hangar_focus_model
from "unitCustomization" import exit_decal_mode, get_decal_in_slot, set_current_decal_slot, get_skin_decals_blk,
  notify_decal_menu_visibility, enter_decal_mode, focus_on_current_decal, set_decal_scalerot_active, set_decal_pos,
  get_decal_rotation_scale, apply_skin_decals_blk
from "vehicleModel" import getUnitFileName
from "%sqstd/datablock.nut" import blkOptFromPath
from "%sqstd/math.nut" import PI, atan2
from "%sqstd/string.nut" import utf8ToLower
from "%sqstd/underscore.nut" import arrayByRows, isEqual
from "%appGlobals/config/decalsPresentation.nut" import getDecalCategoryLocName
from "%appGlobals/decalBlkSerializer.nut" import decalBlkToTbl, decalTblToBlk
from "%appGlobals/pServer/bqClient.nut" import sendCustomBqEvent
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/userPenalties.nut" import allPenalties
from "%rGui/unit/hangarUnit.nut" import hangarUnitDecalSlotsCount, MAX_DECAL_SLOTS_COUNT, isHangarUnitLoaded,
  hangarUnitName
from "%rGui/unit/unitSettings.nut" import mkDecalsPresets
from "%rGui/unitCustom/unitCustomState.nut" import curSelectedSectionId, SECTION_IDS
from "%rGui/unitCustom/unitDecals/decalsCache.nut" import getDecalsByCategories, decalsBlkVersion
from "%rGui/unitCustom/unitSkins/unitSkinsState.nut" import currentSkin, selectedSkin, availableSkins
from "%rGui/unitDetails/unitDetailsState.nut" import isCustomizationWndAttached


const MAX_DECALS_IN_ROW = 4
const SCALE_SPEED = 2.0
const DEFAULT_PRESET_NAME = "default"
const PENALTY_KEY = "DECALS_DISABLE"

let decalParamNames = [
  "decal{0}Line0"
  "decal{0}Line1"
  "decal{0}Line2"
  "decal{0}Line3"
  "decal{0}HaveCP"
  "decal{0}CPNormDepth"
  "decal{0}CPNormDepth1"
  "decal{0}RotScale"
  "decal{0}Mirrored"
  "decal{0}Wrap"
  "decal{0}Abs"
  "decal{0}OppositeMirrored"
  "decal{0}WidthBox"
  "decal{0}Tex"
]

let decalParamNamesToCompare = []

for (local i = 0; i < MAX_DECALS_IN_ROW; i++)
  foreach (param in decalParamNames)
    decalParamNamesToCompare.append(param.subst(i))

let customizationDecalId = Watched(null)
let decalsSlots = Watched([])
let selectedSlotId = Watched(0)
let isManipulatorInProgress = Watched(false)
let selectedSlot = Computed(@() decalsSlots.get()?[selectedSlotId.get()])
let isPreparingToEditDecal = Watched(false)
let isEditingDecal = Watched(false)
let shouldSaveDecal = Watched(false)
let unitId = Computed(@() hangarUnitName.get() ?? "")
let { decalsPresets, setDecalsPresets } = mkDecalsPresets(unitId)
let curSkinForEdit = Computed(@() selectedSkin.get() ?? currentSkin.get())
let isCurSkinAvailable = Computed(@() curSkinForEdit.get() in availableSkins.get())
let isDefaultPreset = Computed(@() curSkinForEdit.get() not in decalsPresets.get() && curSkinForEdit.get() == "")
let defDecalsPresets = Computed(function() {
  if (!isCustomizationWndAttached.get() || unitId.get() == "" || curSelectedSectionId.get() != SECTION_IDS.DECALS)
    return {}
  let unitBlk = blkOptFromPath(getUnitFileName(unitId.get()))
  let { defaultDecals = {}, upgradedDecals = {} } = unitBlk

  let res = {}

  foreach(skinName, decalBlk in defaultDecals)
    res[skinName == DEFAULT_PRESET_NAME ? "" : skinName] <- decalBlkToTbl(decalBlk)
  foreach(skinName, decalBlk in upgradedDecals)
    res[skinName == DEFAULT_PRESET_NAME ? "" : skinName] <- decalBlkToTbl(decalBlk)

  return res
})
let isNotEqualPresets = Computed(function() {
  let dec = decalsPresets.get()?[curSkinForEdit.get()]
  if (dec == null)
    return false
  let defDec = defDecalsPresets.get()?[curSkinForEdit.get()]
  return null != decalParamNamesToCompare.findvalue(@(k) !isEqual(defDec?[k], dec?[k]))
})
let curDecalPosition = Watched(Point2(-1, -1))
let curDecalScaleRot = Watched(Point2(PI * 0.5, 1.))

eventbus_subscribe("on_decal_job_complete", @(_) isEditingDecal.set(customizationDecalId.get() != null))

let selectedDecalId = mkWatched(persist, "selectedDecalId", null)

let decalsCfg = Computed(@() serverConfigs.get()?.decalsCfg ?? {})
let userDecals = Computed(@() servProfile.get()?.decals ?? {})
let decalsPenalty = Computed(@() allPenalties.get()?[PENALTY_KEY] ?? 0)

let needToShowHiddenDecalsDebug = mkWatched(persist, "needToShowHiddenDecalsDebug", false)

let availableDecals = Computed(function() {
  let res = {}
  foreach(decal in decalsCfg.get())
    if (decal.name in userDecals.get())
      res[decal.name] <- true
  return res
})

let decalsCategorySort = @(a, b) a.locNameLower <=> b.locNameLower

let decalsCollection = Computed(function() {
  if (!isCustomizationWndAttached.get())
    return []
  let ver = decalsBlkVersion 
  let res = {}
  let locNameOther = getDecalCategoryLocName("other")
  let locNameOtherLower = utf8ToLower(locNameOther)

  foreach (category, decals in getDecalsByCategories()) {
    let filtered = decals.filter(@(d) d in decalsCfg.get()
      && (needToShowHiddenDecalsDebug.get()
        || !(decalsCfg.get()[d]?.isHidden ?? false)
        || d in availableDecals.get()))
    if (filtered.len() == 0)
      continue
    let fDecals = arrayByRows(filtered, MAX_DECALS_IN_ROW)
    let cat = category.split("/")
    if (cat[0] not in res) {
      let locName = getDecalCategoryLocName(cat[0])
      res[cat[0]] <- { category = cat[0], decals = [], subCategories = [], locName, locNameLower = utf8ToLower(locName) }
    }
    if (cat.len() == 1)
      res[cat[0]].decals.extend(fDecals)
    else {
      let locName = getDecalCategoryLocName(cat[1])
      res[cat[0]].subCategories.append({ category = cat[1], decals = fDecals, locName, locNameLower = utf8ToLower(locName) })
    }
  }

  res.each(function(c) {
    if (c.subCategories.len() > 0 && c.decals.len() > 0)
      c.subCategories.append({ category = "other", decals = c.decals, locName = locNameOther, locNameLower = locNameOtherLower })
    c?.subCategories.sort(decalsCategorySort)
  })

  return res.values()
    .sort(decalsCategorySort)
})

customizationDecalId.subscribe(@(v) v != null ? isPreparingToEditDecal.set(true) : null)
isEditingDecal.subscribe(@(v) v ? isPreparingToEditDecal.set(false) : null)

isEditingDecal.subscribe(@(v) v ? shouldSaveDecal.set(false) : null)
isManipulatorInProgress.subscribe(@(v) v ? shouldSaveDecal.set(true) : null)

let getEmptySlotIdx = @() decalsSlots.get().findindex(@(v) v.isEmpty && v.id + 1 <= hangarUnitDecalSlotsCount.get())
let isAvailableSlot = @(id) id + 1 <= hangarUnitDecalSlotsCount.get()

function updateSlots() {
  if (unitId.get() == "" || !isCustomizationWndAttached.get() || !isHangarUnitLoaded.get())
    return
  let slotsCount = hangarUnitDecalSlotsCount.get()
  let skin = isDefaultPreset.get() ? DEFAULT_PRESET_NAME : curSkinForEdit.get()

  let slots = array(MAX_DECAL_SLOTS_COUNT).map(function(_, slotIdx) {
    let decalId = get_decal_in_slot(unitId.get(), skin, slotIdx, false)
    let isDisabled = slotIdx + 1 > slotsCount
    return {
      decalId
      id = slotIdx
      isEmpty = decalId.len() == 0
      isDisabled
      isBlocked = !isCurSkinAvailable.get()
    }
  })

  decalsSlots.set(slots)
}

foreach (watch in [isCustomizationWndAttached, unitId, curSkinForEdit, isDefaultPreset, isHangarUnitLoaded,
    hangarUnitName, hangarUnitDecalSlotsCount, isCurSkinAvailable])
  watch.subscribe(@(_) deferOnce(updateSlots))

function applySkinDecalsBlk(isRemove) {
  let skin = curSkinForEdit.get()
  let skinDecalsBlk = get_skin_decals_blk(unitId.get(), skin)
  if (skinDecalsBlk == null)
    return

  local defaultSkinPresetTbl = {}
  if (isDefaultPreset.get()) {
    let defaultSkinDecalsBlk = get_skin_decals_blk(unitId.get(), DEFAULT_PRESET_NAME)
    if (defaultSkinDecalsBlk != null)
      defaultSkinPresetTbl = decalBlkToTbl(defaultSkinDecalsBlk)
  }

  let skinDecalsBlkTbl = decalBlkToTbl(skinDecalsBlk)
  let filteredSkinDecalsBlkTbl = skinDecalsBlkTbl.filter(@(_, param) param.startswith($"decal{selectedSlotId.get()}"))
  let savedBlkTbl = (decalsPresets.get()?[skin] ?? {}).__merge(filteredSkinDecalsBlkTbl)

  let preset = {}.__merge(defaultSkinPresetTbl, !isRemove
    ? (decalsPresets.get()?[skin] ?? {}).len() == 0
      ? skinDecalsBlkTbl
      : savedBlkTbl
    : defaultSkinPresetTbl.len() == 0
      ? skinDecalsBlkTbl
      : filteredSkinDecalsBlkTbl)

  setDecalsPresets(decalsPresets.get().__merge({ [skin] = preset }))
}

function resetDecalsPreset() {
  if (!isNotEqualPresets.get())
    return

  local decalsPresetsExt = clone decalsPresets.get()
  decalsPresetsExt.$rawdelete(curSkinForEdit.get())
  apply_skin_decals_blk(unitId.get(), curSkinForEdit.get(), decalTblToBlk(defDecalsPresets.get()?[curSkinForEdit.get()] ?? {}))
  setDecalsPresets(decalsPresetsExt)
}

function enableDecalManipulator() {
  hangar_focus_model(true)
  notify_decal_menu_visibility(true)
}

function removeDecalFromSelectedSlot() {
  set_current_decal_slot(selectedSlotId.get())
  enter_decal_mode("")
  exit_decal_mode(true, true)
  updateSlots()
  applySkinDecalsBlk(true)
  hangar_focus_model(false)
  hangar_enable_controls(false)
}

function enterDecalMode(slotIdx) {
  hangar_enable_controls(true)
  selectedSlotId.set(slotIdx)
  customizationDecalId.set(selectedDecalId.get())
  set_current_decal_slot(slotIdx)
  enter_decal_mode(selectedDecalId.get())
  enableDecalManipulator()
}

function exitDecalMode(save = false) {
  if (!customizationDecalId.get())
    return
  let { success } = exit_decal_mode(save, save)
  if (!success)
    return
  if (save) {
    updateSlots()
    sendCustomBqEvent("decals_1", { action = "set", decalName = customizationDecalId.get() })
  }
  customizationDecalId.set(null)
  set_current_decal_slot(-1)

  applySkinDecalsBlk(!save)
  hangar_focus_model(false)
  notify_decal_menu_visibility(false)
  selectedDecalId.set(null)
}

function rotateDecalMode(status) {
  isManipulatorInProgress.set(status)
  if (status) {
    curDecalScaleRot.set(get_decal_rotation_scale())
    setAxisValue("decal_scale", curDecalScaleRot.get().y)
  }
  set_decal_scalerot_active(status)
}

let moveDecalMode = @(status) isManipulatorInProgress.set(status)

function scaleDecalMode(status) {
  isManipulatorInProgress.set(status)
  if (status) {
    curDecalScaleRot.set(get_decal_rotation_scale())
    setVirtualAxisValue("decal_rotate", curDecalScaleRot.get().x / PI / 2)
  }
  set_decal_scalerot_active(status)
}

function rotateDecal(delta, offset) {
  if (!isManipulatorInProgress.get())
    return
  let centerPos = Point2(curDecalPosition.get().x - offset.x, curDecalPosition.get().y + offset.y)
  let value = delta + Point2(centerPos.x / sw(100), centerPos.y / sw(100))
  setVirtualAxisValue("decal_rotate", (norm_s_ang(curDecalScaleRot.get().x + atan2(value.y, value.x) - PI * 0.75)) / PI / 2)
}

function moveDecal(delta, offset) {
  if (!isManipulatorInProgress.get())
    return
  set_decal_pos(offset - delta.x * sw(100), offset - delta.y * sw(100))
}

function scaleDecal(delta) {
  if (!isManipulatorInProgress.get())
    return
  let value = delta + Point2(curDecalPosition.get().x / sw(100), curDecalPosition.get().y / sw(100))
  let controlDir = Point2(1., -1.)
  setAxisValue("decal_scale", curDecalScaleRot.get().y + value * controlDir * SCALE_SPEED)
}

function editSelectedSlot() {
  let slot = selectedSlot.get()
  if (!slot)
    return

  hangar_enable_controls(true)
  set_current_decal_slot(slot.id)
  focus_on_current_decal()
  customizationDecalId.set(slot.decalId)
  enter_decal_mode(slot.decalId)
  enableDecalManipulator()
}

isCustomizationWndAttached.subscribe(function(v) {
  if (!v)
    return
  selectedSlotId.set(0)
  selectedDecalId.set(null)
  isPreparingToEditDecal.set(false)
})

register_command(@() unitId.get() == "" ? null : setDecalsPresets({}), "ui.reset_cur_unit_decals")
register_command(@() needToShowHiddenDecalsDebug.set(!needToShowHiddenDecalsDebug.get()), "ui.showHiddenDecals")

return {
  decalsCfg
  selectedDecalId
  decalsCollection
  availableDecals
  MAX_DECALS_IN_ROW
  decalsSlots
  selectedSlotId
  selectedSlot
  curDecalPosition
  decalsPenalty
  userDecals
  curSkinForEdit
  isCurSkinAvailable

  removeDecalFromSelectedSlot
  resetDecalsPreset
  isNotEqualPresets
  customizationDecalId
  editSelectedSlot
  exitDecalMode
  isPreparingToEditDecal
  isEditingDecal
  shouldSaveDecal
  enterDecalMode
  getEmptySlotIdx
  isAvailableSlot
  isManipulatorInProgress
  rotateDecalMode
  moveDecalMode
  scaleDecalMode
  rotateDecal
  moveDecal
  scaleDecal
}
