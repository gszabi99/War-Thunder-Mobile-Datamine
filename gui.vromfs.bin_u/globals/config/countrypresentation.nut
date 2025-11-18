from "%globalScripts/logs.nut" import *

let countryOrder = [
  "country_usa"
  "country_ussr"
  "country_germany"
  "country_uk"
  "country_france"
  "country_china"
  "country_italy"
  "country_japan"
  "country_sweden"
  "country_israel"
]

let orderByCountry = countryOrder.reduce(@(res, c, i) res.$rawset(c, i + 1), {})
let sortCountries = @(a, b) (orderByCountry?[a] ?? 0) <=> (orderByCountry?[b] ?? 0)

return {
  sortCountries
}
