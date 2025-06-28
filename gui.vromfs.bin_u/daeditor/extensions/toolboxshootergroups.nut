from "%darg/ui_imports.nut" import *
import "%sqstd/ecs.nut" as ecs

let { EventEntityActivate=@(...) null } = require_optional("dasevents")
let findGroupQuery = ecs.SqQuery("findGroupQuery", {comps_ro = [["groupName", ecs.TYPE_STRING]]})

function enableGroup(group_name, on) {
  function sendEvent(eid, comp) {
    if (comp.groupName == group_name)
      ecs.g_entity_mgr.sendEvent(eid, EventEntityActivate({activate=on}))
  }
  findGroupQuery.perform(sendEvent)
}

let groupsList = Watched([])

let findGroupListQuery = ecs.SqQuery("findGroupListQuery", {
  comps_ro = [
    ["groupName", ecs.TYPE_STRING],
    ["active", ecs.TYPE_BOOL, true],
    ["battle_area", ecs.TYPE_TAG, null],
    ["respbase", ecs.TYPE_TAG, null],
    ["capzone", ecs.TYPE_TAG, null]
  ]
})

function updateGroupsList() {
  groupsList.get().clear()
  let groupsMap = {}
  findGroupListQuery(function(_eid, comp) {
    if (comp.groupName == "")
      return
    if (groupsMap?[comp.groupName] == null) {
      groupsMap[comp.groupName] <- groupsList.get().len()
      groupsList.get().append({
        groupName = comp.groupName
        active = 0
        count = 0
        battleAreas = 0
        respawns = 0
        capZones = 0
      })
    }
    let idx = groupsMap[comp.groupName]
    if (comp.active)
      groupsList.get()[idx].active += 1
    if (comp.battle_area != null)
      groupsList.get()[idx].battleAreas += 1
    if (comp.respbase != null)
      groupsList.get()[idx].respawns += 1
    if (comp.capzone != null)
      groupsList.get()[idx].capZones += 1
    groupsList.get()[idx].count += 1
  })
  groupsList.get().sort(@(a,b) a.groupName <=> b.groupName)
  groupsList.trigger()
}

let onSym  = "+"
let offSym = "-"

function mkGroupListItemName(item) {
  if (item.active > 0 && item.active != item.count)
    return $"{onSym} {item.groupName} ({item.active}/{item.count})"
  return $"{item.active > 0 ? onSym : offSym} {item.groupName}"
}

function mkGroupListItemTooltip(item) {
  let other = item.count - item.battleAreas - item.respawns - item.capZones
  return $"{item.count} objects: {item.battleAreas} battle areas, {item.respawns} respawns, {item.capZones} capture zones, {other} other"
}

function toggleGroupListItem(item) {
  enableGroup(item.groupName, item.active <= 0);
  gui_scene.resetTimeout(0.1, updateGroupsList)
}


return {
  groupsList
  updateGroupsList
  mkGroupListItemName
  mkGroupListItemTooltip
  toggleGroupListItem
}
