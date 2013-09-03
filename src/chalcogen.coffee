local = require './runner-local'
localOpra = require './runner-localOpra'
saucelabs = require './runner-saucelabs'

exports.runOpra = localOpra.run
exports.runSaucelabs = saucelabs.run
exports.runLocal = local.run
