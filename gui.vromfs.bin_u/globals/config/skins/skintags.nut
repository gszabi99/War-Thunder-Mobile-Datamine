let { loc } = require("dagor.localize")

let NO_TAG = ""
let WINTER = "winter"
let DESERT = "desert"
let FOREST = "forest"

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