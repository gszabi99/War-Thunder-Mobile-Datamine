from "%globalsDarg/darg_library.nut" import *
from "dagor.time" import get_time_msec


const MAX_WAIT_MSEC = 1000

function mkPictureWaiter(images, isLoaded) {
  let pictures = images.map(@(img) img instanceof Picture ? img : Picture(img))
  local attachTime = -1
  return {
    key = pictures
    onAttach = @() attachTime = get_time_msec()
    onDetach = @() attachTime = -1
    behavior = Behaviors.RtPropUpdate
    function update() {
      isLoaded.set((attachTime > 0 && attachTime + MAX_WAIT_MSEC <= get_time_msec())
        || null == pictures.findvalue(@(p) p.getLoadedPicSize().x == 0))
      return {}
    }

    children = pictures.map(@(p, i) {
      size = const [1, 1]
      pos = [0, i]
      rendObj = ROBJ_IMAGE
      color = 0x01010101
      image = p
    })
  }
}

function picturePreloader(images, scene) {
  let isLoaded = Watched(false)
  return @() {
    watch = isLoaded
    key = isLoaded
    size = flex()
    onDetach = @() isLoaded.set(false)
    children = isLoaded.get() ? scene : mkPictureWaiter(images, isLoaded)
  }
}

return picturePreloader