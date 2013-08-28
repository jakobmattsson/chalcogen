localOpra = require './runner-localOpra'
saucelabs = require './runner-saucelabs'

exports.runLocal = localOpra.run
exports.runSaucelabs = saucelabs.run
