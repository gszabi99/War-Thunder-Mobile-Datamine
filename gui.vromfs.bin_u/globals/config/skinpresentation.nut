from "%globalScripts/logs.nut" import *
let skinViewPresets = require("skins/skinViewPresets.nut")
let { getUnitType } = require("%appGlobals/unitTags.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")

let unknownSkinPreset = { tag = "", image = "icon_primary_attention.svg", id = "unknown" }

let errors = []
let { byUnitType, byUnit } = require("skins/unitSkinView.nut")
  .map(@(mainList, mainListName)
    mainList.map(@(list, listName)
      list.map(function(id, skinName) {
        if (id not in skinViewPresets) {
          errors.append($"{mainListName}/{listName}/{skinName}={id}")
          return unknownSkinPreset
        }
        return skinViewPresets[id]
      })))

if (errors.len() != 0)
  logerr($"Some skins in unitSkinView.nut has preset which not exists in skinViewPresets.nut:\n{", ".join(errors)}")

return {
  getSkinPresentation = function(realUnitName, skinName) {
    let unitName = getTagsUnitName(realUnitName)
    return byUnit?[unitName][skinName]
      ?? byUnitType?[getUnitType(unitName)][skinName]
      ?? unknownSkinPreset
  }

  unitSkinView = { byUnitType, byUnit }
  unknownSkinPreset
}