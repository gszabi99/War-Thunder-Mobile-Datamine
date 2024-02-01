from "%scripts/dagui_library.nut" import *

let g_listener_priority = freeze({
  DEFAULT = 0
  DEFAULT_HANDLER = 1
  UNIT_CREW_CACHE_UPDATE = 2
  USER_PRESENCE_UPDATE = 2
  CONFIG_VALIDATION = 2
  LOGIN_PROCESS = 3
  MEMOIZE_VALIDATION = 4
})

return {g_listener_priority}