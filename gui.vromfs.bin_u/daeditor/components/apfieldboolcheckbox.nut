from "%darg/ui_imports.nut" import *
from "%sqstd/ecs.nut" import *

let {ControlBg, ReadOnly, Interactive, Hover} = require("style.nut").colors
let {setValToObj, getValFromObj, isCompReadOnly} = require("attrUtil.nut")
let entity_editor = require("entity_editor")

let getVal = @(eid, comp_name, path) path==null ? _dbg_get_comp_val_inspect(eid, comp_name) : getValFromObj(eid, comp_name, path)
function fieldBoolCheckbox(params = {}) {
  let {eid, comp_name, path, rawComponentName=null} = params
  local curRO = isCompReadOnly(eid, rawComponentName)
  local curVal = getVal(eid, rawComponentName, path)
  curVal = Watched(curVal)

  let group = ElemGroup()
  let stateFlags = Watched(0)
  let hoverFlag = Computed(@() stateFlags.get() & S_HOVER)

  function updateTextFromEcs() {
    let val = getVal(eid, rawComponentName, path)
    curVal.update(val)
  }
  function onClick() {
    if (curRO)
      return
    let val = !getVal(eid, rawComponentName, path)
    if (path!=null)
      setValToObj(eid, rawComponentName, path, val)
    else
      obsolete_dbg_set_comp_val(eid, comp_name, val)
    entity_editor.save_component(eid, rawComponentName)
    params?.onChange?()

    curVal.update(val)
    gui_scene.clearTimer(updateTextFromEcs)
    gui_scene.setTimeout(0.1, updateTextFromEcs) 
    return
  }


  return function () {
    local mark = null
    if (curVal.get()) {
      mark = {
        rendObj = ROBJ_SOLID
        color = curRO ? ReadOnly : (hoverFlag.get() != 0) ? Hover : Interactive
        group
        size = [pw(50), ph(50)]
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
      }
    }

    return {
      key = comp_name
      size = [flex(), fontH(100)]
      halign = ALIGN_LEFT
      valign = ALIGN_CENTER

      watch = [curVal, hoverFlag]

      children = {
        size = [fontH(80), fontH(80)]
        rendObj = ROBJ_SOLID
        color = ControlBg

        behavior = Behaviors.Button
        group

        children = mark

        onElemState = @(sf) stateFlags.update(sf)

        onClick
      }
    }
  }
}

return fieldBoolCheckbox
