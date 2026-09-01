from "dagor.debug" import logerr

const defaultPointView = "mapMark"
const fallbackPointSize = 80
const colorActive = 0xFFFFFFFF
let noOffset = [0, 0]


let mkState = @(image, color = colorActive, opacity = 1) { image, color, opacity, scale = 1.0 }

function mkNodeView(artPrefix, artType) {
  let img = $"ui/gameuiskin#{artPrefix}_{artType}.avif"
  let active = $"ui/gameuiskin#{artPrefix}_{artType}_selected.avif"

  return {
    locked = mkState(img, colorActive, 0.5)
    unlocked = mkState(active)
    completed = mkState(img)
    finished = mkState(img)
    selected = mkState(active)
  }
}

let themes = {
  event_s37_node = {
    default = { view = "mapMark", art = "step", size = fallbackPointSize, lineStartOffset = 0.1 }
    nextPage = { view = "mapMarkFinal", art = "start", size = 110, offset = [0.1, 0], lineStartOffset = 0.25 }
    start = { view = "mapMarkStart", art = "start", size = 110, offset = [0.1, 0], lineStartOffset = 0.25 }
    reward = { view = "mapMarkReward", art = "reward", size = 150, lineStartOffset = 0.15 }
    quests = { view = "mapMarkQuests", art = "task", size = 110, lineStartOffset = 0.15 }
  }
}

const defaultThemePrefix = "event_s37_node"

let eventThemePrefix = {
  season_37_main_event = defaultThemePrefix
}

let presentations = {}
let themeNodeViews = {}

foreach (prefix, roles in themes) {
  let nodeViews = {}
  foreach (nodeType, r in roles) {
    if (r.view in presentations)
      logerr($"Duplicate map point view id '{r.view}' in theme {prefix}")
    presentations[r.view] <- mkNodeView(prefix, r.art).__update({
      size = r.size
      offset = r?.offset ?? noOffset
      lineStartOffset = r?.lineStartOffset ?? 0.0
    })
    nodeViews[nodeType] <- r.view
  }
  themeNodeViews[prefix] <- nodeViews
}

let defaultNodeViews = themeNodeViews[defaultThemePrefix]

function getEventNodeViews(eventId) {
  let prefix = eventThemePrefix?[eventId] ?? defaultThemePrefix
  return themeNodeViews?[prefix] ?? defaultNodeViews
}

return {
  mapPointsPresentations = presentations
  defaultPointView
  getMapPointsPresentation = @(view) presentations?[view] ?? presentations[defaultPointView]
  getTreeNodeView = @(eventId, nodeType)
    getEventNodeViews(eventId)?[nodeType] ?? defaultNodeViews?[nodeType] ?? defaultPointView
  getDefaultPointSize = @(view) presentations?[view]?.size ?? fallbackPointSize
  getPointOffset = @(view) presentations?[view]?.offset ?? noOffset
  getPointLineStartOffset = @(view) presentations?[view]?.lineStartOffset ?? 0.0
}
