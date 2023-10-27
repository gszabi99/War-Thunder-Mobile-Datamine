from "%globalsDarg/darg_library.nut" import *

let longConfig = {
  MAX_SPEED = hdpx(10000)
  ACCELERATION = hdpx(20000)
  MIN_ROLL_TIME = 1.25
  MIN_ROLL_TIME_NEXT = 0.5
  MIN_ROLL_TIME_NEXT_FIXED_REWARD = 0.5
  SLOWDOWN_TIME = 2.75
  MIN_SLOW_MOVE_SPEED = hdpx(300)
  MIN_FINAL_BORDER_SPEED = hdpx(100)
  MAX_STOP_BORDER_OFFSET_PART = 0.02
  PRECIZE_PERIODS = 2.0
  BACKUP_CLOSE_TIME = 30
  SLOWEST_COUNT_MIN = 1
  SLOWEST_COUNT_MAX = 2
  ARROW_DROP_SPEED = 30.0
  STOP_ROLL_SOUND_TIME = 1.3

  MIN_WAIT_NO_ROOL_REWARD = 0.5
  WAIT_ANIM_NO_ROOL_REWARD = 1.5

  multiOpenOvr = {
    SLOWEST_COUNT_MAX = 2
    SLOWDOWN_TIME = 2.0
    MIN_SLOW_MOVE_SPEED = hdpx(450)
    MIN_FINAL_BORDER_SPEED = hdpx(150)
  }
}

return {
  roulette_long = longConfig

  roulette_short = longConfig.__merge({
    MIN_ROLL_TIME = 0.75
    SLOWDOWN_TIME = 1.5

    multiOpenOvr = {
      SLOWDOWN_TIME = 1.5
      SLOWEST_COUNT_MAX = 1
      MIN_SLOW_MOVE_SPEED = hdpx(600)
      MIN_FINAL_BORDER_SPEED = hdpx(300)
    }
  })
}