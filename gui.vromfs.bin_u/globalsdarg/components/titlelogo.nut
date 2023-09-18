from "%globalsDarg/darg_library.nut" import *

let titleLogoSize = [hdpxi(256), hdpxi(213)]

let mkTitleLogo = @(ovr = {}) {
  size = titleLogoSize
  rendObj = ROBJ_IMAGE
  image = Picture($"!ui/title.avif:{titleLogoSize[0]}:{titleLogoSize[1]}:K")
  keepAspect = KEEP_ASPECT_FIT
  color = Color(255, 255, 255)
}.__merge(ovr)

return freeze({
  mkTitleLogo
  titleLogoSize
})
