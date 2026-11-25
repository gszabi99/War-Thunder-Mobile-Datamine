from "dagor.debug" import logerr

const defaultPointView = "mapMark"
const colorActive = 0xFFFFFFFF


let mkState = @(image, color = colorActive, opacity = 1) { image, color, opacity, scale = 1.0 }

let defViewParams = {
  size = 80
  offset = [0, 0]
  lineStartOffset = 0.0
  completedMarkSize = 40
}

function mkNodeView(imgBase, params) {
  let img = $"ui/gameuiskin#{imgBase}.avif"
  let selected = $"ui/gameuiskin#{imgBase}_selected.avif"
  return {
    ...defViewParams, ...params
    locked = mkState(img, colorActive, 0.5)
    unlocked = mkState(selected)
    completed = mkState(img)
    finished = mkState(img)
    selected = mkState(selected)
  }
}

const selectionScale = 1.3 


function mkNodeViewS40(imgBase, params) {
  let mkImg = @(state) $"ui/gameuiskin#{imgBase}_{state}.avif"
  let selected = $"ui/gameuiskin#{imgBase}_selected.avif"
  return {
    ...defViewParams
    lineStartOffset = -(selectionScale - 1) / 2 
    ...params
    locked = mkState(mkImg("locked"))
    unlocked = mkState(mkImg("active"))
    completed = mkState(mkImg("completed"))
    finished = mkState(mkImg("completed"))
    selected = mkState(selected)
    selectionOverlay = "ui/gameuiskin#event_s40_selection.avif"
    selectionScale
  }
}

let presentations = {
  mapMark = mkNodeView("event_s37_node_step", { lineStartOffset = 0.1, completedMarkSize = 30 })
  mapMarkFinal = mkNodeView("event_s37_node_start", { size = 110, offset = [0.1, 0], lineStartOffset = 0.25 })
  mapMarkStart = mkNodeView("event_s37_node_start", { size = 110, offset = [0.1, 0], lineStartOffset = 0.25 })
  mapMarkReward = mkNodeView("event_s37_node_reward", { size = 150, lineStartOffset = 0.15 })
  mapMarkQuests = mkNodeView("event_s37_node_task", { size = 110, lineStartOffset = 0.15 })

  mapMark_s40 = mkNodeViewS40("event_s40_node_step", { completedMarkSize = 30 })
  mapMarkFinal_s40 = mkNodeViewS40("event_s40_node_start", { size = 110 })
  mapMarkStart_s40 = mkNodeViewS40("event_s40_node_start", { size = 110 })
  mapMarkReward_s40 = mkNodeViewS40("event_s40_node_reward", { size = 110 })
  mapMarkQuests_s40 = mkNodeViewS40("event_s40_node_task", { size = 90 })
  mapMarkFinish_s40 = mkNodeViewS40("event_s40_node_finish", { size = 110 })
}


let defaultNodeViews = {
  default = "mapMark"
  nextPage = "mapMarkFinal"
  start = "mapMarkStart"
  reward = "mapMarkReward"
  quests = "mapMarkQuests"
}

let nodeViewsByEvent = {
  season_37_main_event = defaultNodeViews
  season_40_main_event = {
    default = "mapMark_s40"
    nextPage = "mapMarkFinal_s40"
    start = "mapMarkStart_s40"
    reward = "mapMarkReward_s40"
    quests = "mapMarkQuests_s40"
  }
}


foreach (eventId, views in { default = defaultNodeViews }.__merge(nodeViewsByEvent))
  foreach (nodeType, view in views)
    if (view not in presentations)
      logerr($"Unknown map point view '{view}' for node type '{nodeType}' of {eventId}")

let defPresentation = presentations[defaultPointView]
let getMapPointsPresentation = @(view) presentations?[view] ?? defPresentation

return {
  mapPointsPresentations = presentations
  defaultPointView
  getMapPointsPresentation
  getTreeNodeView = @(eventId, nodeType)
    nodeViewsByEvent?[eventId]?[nodeType] ?? defaultNodeViews?[nodeType] ?? defaultPointView
  getDefaultPointSize = @(view) getMapPointsPresentation(view).size
  getPointOffset = @(view) getMapPointsPresentation(view).offset
  getPointLineStartOffset = @(view) getMapPointsPresentation(view).lineStartOffset
}
