from "dagor.localize" import loc
from "types" import Function


let unknownImage = "ui/gameuiskin#icon_primary_attention.svg"

let presentationCtors = { 
  getPuzzleName = @(name) @(idx) loc($"puzzle/{name}/{idx + 1}/name")
  getPuzzleDesc = @(name) @(idx) loc($"puzzle/{name}/{idx + 1}/desc")
  bg = "ui/images/collections/collection_s38_bg.avif"
  mainScreenOffset = [0, 60]
  puzzleBg = "ui/images/collections/collection_s38_bg_board.avif"
  puzzleBgSize = [1288, 953]
  puzzleBgExtensions = [
    { x = 6, width = 43 }
    { x = 1239, width = 43 }
  ]
  puzzleTexSize = [1920, 1080]
  puzzleScreenSize = [1200, 675]
  puzzleScreenOffset = [0, -120]
  paginatorOffsetY = 40
  dupesInfoPiece = [0, 4] 
  puzzles = []
}

let presentations = {
  main_s38 = {
    puzzles = [
      "ui/images/collections/puzzle_s38_01.avif"
      "ui/images/collections/puzzle_s38_02.avif"
      "ui/images/collections/puzzle_s38_03.avif"
      "ui/images/collections/puzzle_s38_04.avif"
      "ui/images/collections/puzzle_s38_05.avif"
      "ui/images/collections/puzzle_s38_06.avif"
      "ui/images/collections/puzzle_s38_07.avif"
      "ui/images/collections/puzzle_s38_08.avif"
      "ui/images/collections/puzzle_s38_09.avif"
    ]
  }
}

let cache = {}
function mkPresentation(name) {
  let res = { name }.__update(presentations?[name] ?? {})
  foreach (k, v in presentationCtors)
    if (k not in res)
      res[k] <- v instanceof Function ? v(name) : v
  return freeze(res)
}

function getCollectionPresentation(name) {
  let n = name ?? ""
  if (n not in cache)
    cache[n] <- mkPresentation(n)
  return cache[n]
}

return {
  getCollectionPresentation
  getPuzzleImage = @(collectionId, puzzleId) getCollectionPresentation(collectionId).puzzles?[puzzleId] ?? unknownImage
}