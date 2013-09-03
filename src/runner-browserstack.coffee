randomName = require 'random-name'
_ = require 'underscore'

exports.run = (wdMocha, { visualLogs, environments, username, projectName, branchName, buildUrl, url, timeout, verbose, parallelism, browserstackUsername, browserstackPassword }, callback) ->

  if !browserstackUsername || !browserstackPassword
    return callback(new Error("Missing username and/or password"))

  buildName = randomName.first()

  envs = environments.map (x) -> _.extend(_(x).pick([
    'platform'
    'browserName'
    'version'
    'os'
    'os_version'
    'browser'
    'browser_version'
    'device'
  ]), {
    'browserstack.debug': visualLogs
    'browserstack.user': browserstackUsername
    'browserstack.key': browserstackPassword
    project: projectName
    name: randomName.first()
    build: buildName
  })

  wdMocha.run {
    setups: envs
    url: url
    totalTestTimeout: timeout
    verbose: verbose
    parallelism: parallelism
    wdArgs: ['http://hub.browserstack.com/wd/hub']
  }, callback
