



options no_aot = true
require danetlibs.assets_import.assets_import_init

def load_libs() : bool
  var ok = true
  ok = load_assets_import("%danetlibs/assets_import") && ok

  return ok

[export]
def test_all
  let ok = load_libs()
  assert(ok)

