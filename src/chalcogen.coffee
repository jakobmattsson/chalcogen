local = require './runner-local'
localOpra = require './runner-localOpra'
saucelabs = require './runner-saucelabs'
browserstack = require './runner-browserstack'

exports.runOpra = localOpra.run
exports.runSaucelabs = saucelabs.run
exports.runLocal = local.run
exports.runBrowserstack = browserstack.run
