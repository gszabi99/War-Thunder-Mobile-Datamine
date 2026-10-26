from "frp" import Watched

function mkWatched(persistFunc, persistKey, defVal = null) {
  let container = persistFunc(persistKey, @() { v = defVal })
  let watch = Watched(container.v)
  watch.subscribe(@(v) container.v = v)
  return watch
}

return mkWatched
