let { getCurCircuitOverride } = require("%appGlobals/curCircuitOverride.nut")

return {
  LINK_TO_GAIJIN_ACCOUNT_URL = getCurCircuitOverride("linkToAccountURL","auto_local auto_login https://wtmobile.com/connect")
  ACTIVATE_PROMO_CODE_URL = getCurCircuitOverride("activateCodeURL","auto_local auto_login https://store.gaijin.net/activate.php")
}