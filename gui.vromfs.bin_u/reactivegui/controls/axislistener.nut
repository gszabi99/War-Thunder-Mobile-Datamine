from "%globalsDarg/darg_library.nut" import *
from "%rGui/controls/shortcutConsts.nut" import *
let { isCombinationModActive } = require("%rGui/controls/shortcutSimpleComps.nut")


let axisModifiers = Computed(@() {
  [AXIS_MODIFIEER_LB] = isCombinationModActive.get(),
})

let axisModListeners = Watched({})

function axisListener(updateByAxis) {
  let axisWatches = updateByAxis.map(function(_, a) {
    let axis = a & JOY_AXIS_MASK
    let modifier = a & ~JOY_AXIS_MASK
    let axisWatch = gui_scene.getJoystickAxis(axis)
    let isAllowed = modifier != 0 ? Computed(@() axisModifiers.get()?[modifier] ?? true)
      : Computed(@() (axisModListeners.get()?[axis].findindex(@(_, m) axisModifiers.get()?[m] ?? false)) == null)
    let watch = Computed(@() isAllowed.get() ? axisWatch?.get() : 0)

    return { watch, modifier, axis}
  })
    .filter(@(a) a.watch.get() != null)
  return {
    key = {}
    size = 0 
    function onAttach() {
      let listeners = []
      foreach (a, aWatch in axisWatches) {
        let { watch, modifier, axis } = aWatch
        let action = updateByAxis[a]
        watch.subscribe_with_nasty_disregard_of_frp_update(action)
        action(watch.get())
        if (modifier != 0)
          listeners.append({modifier, axis})
      }

      if (listeners.len() == 0)
        return

      axisModListeners.mutate(function(v) {
        foreach(l in listeners) {
          let { axis, modifier } = l
          v[axis] <- ((clone v?[axis]) ?? {}).$rawset(modifier, true) 
        }
      })
    }
    function onDetach() {
      let listeners = []
      foreach (a, aWatch in axisWatches) {
        let { watch, modifier, axis } = aWatch
        let action = updateByAxis[a]
        watch.unsubscribe(action)
        action(0)
        if (modifier in axisModListeners.get()?[axis])
          listeners.append({modifier, axis})
      }

      if (listeners.len() == 0)
        return

      axisModListeners.mutate(function(v) {
        foreach(l in listeners) {
          let { axis, modifier } = l
          let mods = clone v[axis]
          mods.$rawdelete(modifier)
          v[axis] = mods
        }
      })
    }
  }
}

return axisListener