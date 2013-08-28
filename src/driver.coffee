wd = require 'wd'
async = require 'async'



propagate = (onErr, onSucc) -> (err, rest...) -> if err then onErr(err) else onSucc(rest...)



init = (log, verbose, browser, url, totalTestTimeout, setup, callback) ->
  log("Initiating with caps: #{JSON.stringify(setup)}") if verbose
  browser.init setup, propagate callback, (id) ->
    log("Loading web page") if verbose
    browser.get url, propagate callback, ->
      browser.setAsyncScriptTimeout totalTestTimeout, propagate callback, ->
        callback(null, { jobid: id })



exports.finalLog = (err, res) ->
  console.log("Test errored", err) if err?
  console.log()
  (res?.results || []).forEach (x) -> exports.logResult(x)
  !err? && res.allPassed



exports.logResult = (input) ->
  browserName = input.setup.browserName
  results = input.results || []
  err = input.err

  if err?
    console.log("Ran 0 tests in #{browserName}. Could not start it at all.")
    return

  failed = results.filter (x) -> x.state == 'failed'
  runTests = results.filter (x) -> x.state?
  skippedTests = results.filter (x) -> !x.state?

  console.log "Ran #{runTests.length} tests (skipped #{skippedTests.length} of #{results.length}) in #{browserName}. #{failed.length} failed."
  width = Math.ceil(Math.log(failed.length+1) / Math.log(10))
  padder = [1..3].map((x) -> ' ').join('')

  failed.forEach (res, i) ->
    num = (padder + (i + 1)).slice(-width)
    console.log("#{num}: #{res.state} - #{res.title}")
    (res.msg || '').split('\n').forEach (part) ->
      console.log("  #{part}")



runInstance = ({ setup, onDone, totalTestTimeout, url, verbose, wdArgs }, callback) ->
  log = (args...) ->
    if setup.name && setup.platform
      prefix = "#{setup.name} (#{setup.browserName}, #{setup.platform})"
    else
      prefix = setup.browserName
    console.log("#{prefix}: #{args.join(' ')}")
    console.log(args[1]) if args[1]

  browserName = setup.browserName
  browser = wd.remote.apply(wd, wdArgs || [])
  init log, verbose, browser, url, totalTestTimeout, setup, (err, initResult) ->
    jobid = initResult?.jobid
    if err?
      log("Starting failed")
      return callback(err)
    log("Running test script") if verbose

    script = '''
      var cb = arguments[arguments.length-1];

      var combineResult = function(suite, prefix) {
        var arrayOfArrays = suite.suites.map(function(suite) {
          return combineResult(suite, (prefix || '').trim() + ' ' + suite.title);
        });
        var flattened = Array.prototype.concat.apply([], arrayOfArrays);
        var tests = suite.tests.map(function(test) {
          return {
            msg: (test.err || {}).message,
            title: (prefix + ' ' + test.title).trim(),
            state: test.state
          }
        });
        return tests.concat(flattened);
      };

      var tryLater = function(attempts) {
        setTimeout(function() {
          if (window.saucedUp) {
            var runner = mocha.run(function() {
              cb(combineResult(runner.suite));
            });
          } else if (attempts == 0) {
            alert("out of attempts");
          } else {
            tryLater(attempts-1);
          }
        }, 100);
      };

      tryLater(900);
    '''

    browser.safeExecuteAsync script, (execErr, results) ->

      if execErr?
        log("execution err", execErr) if verbose
        passed = null
        results = null
      else
        log("Test completed, shutting down") if verbose
        passed = results.every (x) -> x.state != 'failed'

      onDone { passed, jobid }, (doneErr) ->
        log("onDone failed, ignoring...", doneErr) if doneErr? && verbose
        browser.quit (quitErr) ->
          log("browser.quit failed, ignoring...", quitErr) if quitErr? && verbose
          callback(execErr, {
            passed
            results
          })



exports.run = ({ verbose, onDone, setups, url, totalTestTimeout, wdArgs, parallelism }, callback) ->

  parallelism ?= 1000
  onDone ?= (args, callback) -> callback()
  setups = setups.map (setup) -> if typeof setup == 'string' then { browserName: setup } else setup

  async.mapLimit setups, parallelism, (setup, callback) ->
    setImmediate ->
      runInstance { setup, onDone, totalTestTimeout, wdArgs, verbose, url }, (err, data) ->
        callback(null, {
          setup: setup
          err: err
          passed: data?.passed
          results: data?.results
        })
  , (err, res) ->
    callback(null, {
      results: res
      allPassed: res.every (x) -> x.passed == true
    })
