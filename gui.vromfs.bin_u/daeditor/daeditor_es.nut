from "%sqstd/ecs.nut" import *
from "%darg/ui_imports.nut" import *
import "entity_editor" as entity_editor

let { selectedEntity, selectedEntities, selectedEntitiesSetKeyVal, selectedEntitiesDeleteKey,
      selectedCompName,
      markedScenes} = require("state.nut")









let defaultGetEntityExtraNameQuery = SqQuery("defaultGetEntityExtraNameQuery", {
  comps_ro = [["ri_extra__name", TYPE_STRING, null]]
})

let {
  get_entity_extra_name = @(eid) defaultGetEntityExtraNameQuery(eid, @(_eid, comp) comp.ri_extra__name)
} = require_optional("das.daeditor")


selectedEntities.subscribe(function(val) {
  if (val.len() == 1)
    selectedEntity(val.keys()[0])
  else
    selectedEntity(INVALID_ENTITY_ID)
})

selectedEntity.subscribe(function(_eid) {
  selectedCompName(null)
})

register_es("update_selected_entities", {
    onInit = @(eid, _comp) selectedEntitiesSetKeyVal(eid, true)
    onDestroy = @(eid, _comp) selectedEntitiesDeleteKey(eid)
  },
  { comps_rq = ["daeditor__selected"]}
)

function getEntityExtraName(eid) {
  let extraName = get_entity_extra_name?(eid) ?? ""

  return extraName.strip() == "" ? null : extraName
}

function getSceneLoadTypeText(v) {
  let loadTypeVal = type(v) == "int" || type(v) == "integer" ? v : v.loadType
  let loadType = (
    (loadTypeVal == 1) ? "COMMON" :
    (loadTypeVal == 2) ? "CLIENT" :
    (loadTypeVal == 3) ? "IMPORT" :
    "UNKNOWN"
  )
  return loadType
}

function getSceneId(loadType, index) {
  return (index << 2) | loadType
}

function getSceneIdOf(scene) {
  return getSceneId(scene.loadType, scene.index)
}

function getSceneIdLoadType(sceneId) {
  return (sceneId & (1 | 2))
}

function getSceneIdIndex(sceneId) {
  return (sceneId >> 2)
}

const loadTypeConst = 4
let sceneGenerated = {
  id = 0
  asText = "[GENERATED]"
  
  loadType = loadTypeConst
  index = 1
  entityCount = -2
  path = "\0"
}
sceneGenerated.id = getSceneIdOf(sceneGenerated)

let sceneSaved = {
  id = 0
  asText = "[ALL FILES]"
  
  loadType = loadTypeConst
  index = 2
  entityCount = -1
  path = "\0\0"
}
sceneSaved.id = getSceneIdOf(sceneSaved)

function getNumMarkedScenes() {
  local nSel = 0
  foreach (_sceneId, marked in markedScenes.get()) {
    if (marked)
      ++nSel
  }
  return nSel
}

function matchSceneEntity(eid, saved, generated) {
  local isSaved = entity_editor.get_instance()?.isSceneEntity(eid)
  return (saved && isSaved) || (generated && !isSaved)
}

function matchEntityByScene(eid, saved, generated) {
  local eLoadType = entity_editor.get_instance()?.getEntityRecordLoadType(eid)
  local eIndex = entity_editor.get_instance()?.getEntityRecordIndex(eid)
  local sceneId = getSceneId(eLoadType, eIndex)
  if (markedScenes.get()?[sceneId])
    return true
  return matchSceneEntity(eid, saved, generated)
}

return {
  getEntityExtraName

  getSceneLoadTypeText
  getSceneId
  getSceneIdOf
  getSceneIdLoadType
  getSceneIdIndex

  loadTypeConst
  sceneGenerated
  sceneSaved

  getNumMarkedScenes
  matchSceneEntity
  matchEntityByScene
}