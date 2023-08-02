from "%sqstd/ecs.nut" import *
from "state.nut" import selectedEntity, selectedEntities, selectedEntitiesSetKeyVal, selectedEntitiesDeleteKey, selectedCompName
from "%darg/ui_imports.nut" import *


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
