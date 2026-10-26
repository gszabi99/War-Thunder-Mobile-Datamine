from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "dagor.clipboard" import get_clipboard_text, set_clipboard_text
from "json" import object_to_json_string, parse_json
from "%sqstd/underscore.nut" import isArray, isFloat, isInteger, isTable
from "%rGui/hudTuning/cfgByUnitType.nut" import cfgByUnitType
from "%rGui/hudTuning/hudTuningConsts.nut" import tuningStateDefault
from "%rGui/hudTuning/hudTuningState.nut" import presetsSaved, savePreset, isTuningOpened, isCurPresetChanged





const EXPORT_VERSION = 1

let isNumeric = @(v) isInteger(v) || isFloat(v)
let isNumPair = @(v) isArray(v) && v.len() == 2 && isNumeric(v[0]) && isNumeric(v[1])
let isValidTransform = @(t) isTable(t)
  && isInteger(t?.align)
  && isNumPair(t?.pos)

let isSameOptType = @(v, def) isFloat(def)
  ? isNumeric(v)
  : typeof v == typeof def

let hasNoElemTuning = @(transforms, options) transforms.$len() == 0
  && options.$findindex(@(v) isTable(v) && v.$len() > 0) == null

function sanitizeElemOption(byElem, def, elemsCfg, path, dropped) {
  let res = {}
  foreach (elemId, v in byElem)
    if (elemId in elemsCfg && isSameOptType(v, def))
      res[elemId] <- isFloat(def) ? v.tofloat() : v
    else
      dropped.append($"{path}.{elemId}")
  return res
}

function sanitizeOptions(srcOptions, elemsCfg, path, dropped) {
  let { options, customOptions } = tuningStateDefault
  let res = {}
  foreach (optId, v in srcOptions) {
    let optPath = $"{path}.{optId}"
    if (optId in customOptions && isSameOptType(v, customOptions[optId]))
      res[optId] <- v
    else if (optId in options && isTable(v))
      res[optId] <- sanitizeElemOption(v, options[optId], elemsCfg, optPath, dropped)
    else
      dropped.append(optPath)
  }
  return res
}

function sanitizePreset(unitType, preset, dropped) {
  let { transforms = {}, options = {}, resolution = null, version = null } = preset
  let hasLayoutKeys = "transforms" in preset || "options" in preset
  if (!hasLayoutKeys || !isTable(transforms) || !isTable(options)) {
    dropped.append(unitType)
    return null
  }

  let droppedBefore = dropped.len()
  let elemsCfg = cfgByUnitType[unitType]
  let res = {
    transforms = {}
    options = sanitizeOptions(options, elemsCfg, $"{unitType}.options", dropped)
  }
  foreach (elemId, t in transforms)
    if (elemId in elemsCfg && isValidTransform(t))
      res.transforms[elemId] <- { align = t.align, pos = t.pos }
    else
      dropped.append($"{unitType}.transforms.{elemId}")

  if (hasNoElemTuning(res.transforms, res.options) && dropped.len() > droppedBefore) {
    dropped.append(unitType)
    return null
  }

  if (isNumPair(resolution))
    res.resolution <- resolution
  else if (resolution != null)
    dropped.append($"{unitType}.resolution")
  if (isInteger(version))
    res.version <- version
  else if (version != null)
    dropped.append($"{unitType}.version")
  return res
}

function exportPresets() {
  let presets = presetsSaved.get()
  if (presets.len() == 0) {
    console_print("No saved HUD tuning presets")
    return
  }
  let text = object_to_json_string({ hudTuningExport = EXPORT_VERSION, presets })
  set_clipboard_text(text)
  log($"HUD tuning export: {text}")
  let names = ", ".join(presets.keys().sort())
  console_print($"HUD tuning presets copied to clipboard: {names}")
  if (isCurPresetChanged.get())
    console_print("Unsaved changes in the open HUD tuning are not exported")
}

function importPresets() {
  if (isTuningOpened.get()) {
    console_print("Close HUD tuning before import")
    return
  }

  local data = null
  try {
    data = parse_json(get_clipboard_text())
  }
  catch(e) {
    console_print($"Clipboard does not contain valid JSON: {e}")
    return
  }
  let presets = (isTable(data) && data?.hudTuningExport == EXPORT_VERSION)
    ? data?.presets
    : null
  if (!isTable(presets)) {
    console_print($"Clipboard does not contain HUD tuning presets of version {EXPORT_VERSION}")
    return
  }

  let imported = []
  let dropped = []
  foreach (ut, preset in presets) {
    if (ut not in cfgByUnitType || !isTable(preset)) {
      dropped.append(ut)
      continue
    }
    let sanitized = sanitizePreset(ut, preset, dropped)
    if (sanitized == null)
      continue
    savePreset(ut, sanitized)
    imported.append(ut)
  }

  if (imported.len() == 0)
    console_print("Nothing to import")
  else {
    let names = ", ".join(imported.sort())
    console_print($"HUD tuning presets imported: {names}")
  }
  if (dropped.len() > 0) {
    let droppedStr = ", ".join(dropped.sort())
    console_print($"Skipped invalid or unknown entries: {droppedStr}")
  }
}

register_command(exportPresets, "hudTuning.export")
register_command(importPresets, "hudTuning.import")
