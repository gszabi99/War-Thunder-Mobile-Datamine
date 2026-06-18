



options no_aot = true
require danetlibs.assets_import.assets_import_init
require gameLibs.route_prober.route_prober_init

def load_libs() : bool
  var ok = true
  ok = load_assets_import("%danetlibs/assets_import") && ok
  ok = load_route_prober("%gameLibs/route_prober") && ok

  return ok

[export]
def test_all
  let ok = load_libs()
  assert(ok)

