opra = require 'opra'
runr = require 'runr'

propagate = (onErr, onSucc) -> (err, rest...) -> if err then onErr(err) else onSucc(rest...)

exports.run = (wdMocha, { verbose, browsers, url, timeout, seleniumPath }, callback) ->
  runr.up 'selenium', { seleniumPath }, propagate callback, ->
    wdMocha.run {
      setups: browsers
      url: url
      totalTestTimeout: timeout
      verbose: verbose
    }, callback
