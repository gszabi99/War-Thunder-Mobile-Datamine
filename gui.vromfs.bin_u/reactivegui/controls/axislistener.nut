from "%globalsDarg/darg_library.nut" import *

let function axisListener(updateByAxis) {
  let watches = updateByAxis.map(@(_, axis) gui_scene.getJoystickAxis(axis))
    .filter(@(w) w != null)
  return {
    key = {}
    size = [0, 0] //need only to avoid "invalid component description" error
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