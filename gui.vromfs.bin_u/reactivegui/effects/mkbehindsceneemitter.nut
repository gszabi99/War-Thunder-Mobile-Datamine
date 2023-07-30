from "%globalsDarg/darg_library.nut" import *
let { setTimeout, setInterval, clearTimer } = require("dagor.workcycle")
let mkSparkStarMoveOut = require("mkSparkStarMoveOut.nut")
let { addBehindScene, removeBehindScene } = require("%rGui/behindScene.nut")

let defSparkCtor = mkSparkStarMoveOut(0x00FFFFFF)
let mkBehindSceneEmitter = kwarg(function(lifeTime, count = 50, sparkCtor = defSparkCtor) {
  local uid = null
  let halfSize = [sw(50), sh(50)]
  let list = array(count).map(@(_) {})
  let function removeSceneIfParticlesFinish() {
    if (null != list.findvalue(@(c) (c?.isActive ?? false)))
      return
    clearTimer(removeSceneIfParticlesFinish)
    removeBehindScene(uid)
  }
  let function onLifeTimeFinish() {
    list.each(@(c) c.shouldFinish <- true)
    setInterval(1.0, removeSceneIfParticlesFinish)
  }

  uid = addBehindScene({
    key = {}
    size = flex()
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    onAttach = @() setTimeout(lifeTime, onLifeTimeFinish)
    function onDetach() {
      clearTimer(onLifeTimeFinish)
      clearTimer(removeSceneIfParticlesFinish)
    }
    children = list.map(@(state) sparkCtor(state, halfSize))
  })
})

return mkBehindSceneEmitter