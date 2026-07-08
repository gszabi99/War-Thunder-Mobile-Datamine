from "%globalsDarg/darg_library.nut" import *
from "%sqstd/ecs.nut" import register_es, TYPE_BOOL, TYPE_INT


let challengeState = Watched({})

register_es("challenge_state_es",
  {
    [["onInit", "onChange"]] = @(_, c) challengeState.set({
      isStarted = c.challenge__is_started
      isFinished = c.challenge__is_finished
      totalTime = c.challenge__time
      totalTanks = c.challenge__tanks_amount
      timeLeft = c.challenge__is_started || c.challenge__is_finished ? c.challenge__time_left_int : c.challenge__time
      tanksLeft = c.challenge__tanks_left
    }),
    onDestroy = @(_, __) challengeState.set({})
  },
  {
    comps_track = [
      ["challenge__is_started", TYPE_BOOL],
      ["challenge__is_finished", TYPE_BOOL],
      ["challenge__tanks_left", TYPE_INT],
      ["challenge__time_left_int", TYPE_INT],
    ],
    comps_ro = [
      ["challenge__time", TYPE_INT],
      ["challenge__tanks_amount", TYPE_INT],
    ]
  })


return {
  challengeState
  isInHangarChallenge = Computed(@() challengeState.get().len() != 0)
}