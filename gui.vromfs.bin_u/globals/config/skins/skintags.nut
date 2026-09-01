from "dagor.localize" import loc


const NO_TAG = ""
const WINTER = "winter"
const DESERT = "desert"
const FOREST = "forest"

let tagsLocId = {
  [NO_TAG] = "skins/noTag"
}

return {
  NO_TAG
  FOREST
  WINTER
  DESERT
  AIR= "air"
  NAVAL = "naval"

  tankTagsOrder = [WINTER, DESERT, FOREST, NO_TAG]

  getTagName = @(tag) loc(tagsLocId?[tag] ?? $"camoType/{tag}")
}