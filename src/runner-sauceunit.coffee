saucelabs = require 'saucelabs'
randomName = require 'random-name'
_ = require 'underscore'
request = require 'request'

exports.run = (wdMocha, { environments, username, projectName, branchName, buildUrl, url, timeout, verbose, parallelism, sauceUsername, saucePassword }, callback) ->

  if !sauceUsername || !saucePassword
    return callback(new Error("Missing username and/or password"))

  reqD =
    url: "https://saucelabs.com/rest/v1/#{sauceUsername}/js-tests"
    method: 'POST'
    auth:
      username: sauceUsername
      password: saucePassword
    json:
      name: randomName.first()
      build: randomName.first()
      tags: [username, projectName, branchName].filter (x) -> x
      platforms: environments.map (x) -> [x.platform, x.browserName, x.version]
      url: url
      framework: "mocha"

  request reqD, (err, res, body) ->
    tests = body['js tests']
    totalTests = tests.length
    console.log("#{totalTests} tests started on Sauce Labs...")

    req2 =
      url: "https://saucelabs.com/rest/v1/#{sauceUsername}/js-tests/status"
      method: 'POST'
      auth:
        username: sauceUsername
        password: saucePassword
      json: body

    pollDone = ->
      request req2, (err, res, body) ->
        tests = body['js tests']
        atLeastOneTestErrored = tests.some (test) -> test.status == 'test error'
        nonCompletedStrings = ['test queued', 'test session in progress']
        remaining = tests.filter((test) -> test.status in nonCompletedStrings).length
        console.log("#{totalTests-remaining} tests completed, #{remaining} remaining...")

        if body.completed || atLeastOneTestErrored
          callback(null, {
            allPassed: tests.every (test) -> test.result.failures == 0
            results: tests.map (test) ->
              environment: test.platform.join(', ')
              testCount: test.result.tests
              passes: test.result.passes
              failures: test.result.failures
          })
          return

        setTimeout(pollDone, 5000)

    pollDone()
