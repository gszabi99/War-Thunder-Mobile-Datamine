let { logerr } = require("dagor.debug")

let mkState = @(image, color = 0xFFFFFFFF)
  { image, color, scale = 1.0 }

let defaultPresentation = {
  locked = mkState("ui/gameuiskin#scroll_quest_locked.avif")
  unlocked = mkState("ui/gameuiskin#scroll_quest_active.avif")
  completed = mkState("ui/gameuiskin#scroll_quest_completed.avif")
  finished = mkState("ui/gameuiskin#scroll_quest_completed.avif")
}

let presentations = {
  mapMark = defaultPresentation
  mapMarkFinal = {
    locked = mkState("ui/gameuiskin#scroll_quest_locked_final.avif")
    unlocked = mkState("ui/gameuiskin#scroll_quest_active_final.avif")
    completed = mkState("ui/gameuiskin#scroll_quest_active_final.avif")
    finished = mkState("ui/gameuiskin#scroll_quest_completed_final.avif")
  }.map(@(v) v.$rawset("scale", 1.3))
}

let reqFields = ["locked", "unlocked", "completed", "finished"]
foreach (id, p in presentations)
  foreach (f in reqFields)
    if (f not in p)
      logerr($"Missing field {f} in mapPointsPresentation {id}")

return {
  mapPointsPresentations = presentations
  getMapPointsPresentation = @(id) presentations?[id] ?? defaultPresentation
}