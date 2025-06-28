from "%globalsDarg/darg_library.nut" import *

function axisListener(updateByAxis) {
  let watches = updateByAxis.map(@(_, axis) gui_scene.getJoystickAxis(axis))
    .filter(@(w) w != null)
  return {
    key = {}
    size = 0 
    function onAttach() {
      foreach (a, w in watches) {
        let action = updateByAxis[a]
        w.subscribe(action)
        action(w.value)
      }
    }
    function onDetach() {
      foreach (a, w in watches) {
        let action = updateByAxis[a]
        w.unsubscribe(action)
        action(0)
      }
    }
  }
}

return axisListener