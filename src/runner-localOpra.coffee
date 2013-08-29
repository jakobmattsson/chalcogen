opra = require 'opra'
runr = require 'runr'

propagate = (onErr, onSucc) -> (err, rest...) -> if err then onErr(err) else onSucc(rest...)

exports.run = (wdMocha, { verbose, browsers, path, timeout, seleniumPath, opraSettings }, callback) ->
  runr.up 'selenium', { seleniumPath }, propagate callback, ->
    opra.server opraSettings, propagate callback, ->
      wdMocha.run {
        setups: browsers
        url: "http://localhost:#{opraSettings.port}#{path}"
        totalTestTimeout: timeout
        verbose: verbose
      }, callback
