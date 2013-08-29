saucelabs = require 'saucelabs'
randomName = require 'random-name'
_ = require 'underscore'

exports.run = (wdMocha, { environments, username, projectName, branchName, buildUrl, url, timeout, verbose, parallelism, sauceUsername, saucePassword }, callback) ->

  if !sauceUsername || !saucePassword
    return callback(new Error("Missing username and/or password"))

  sauce = new saucelabs({ username: sauceUsername, password: saucePassword })
  buildName = randomName.first()

  wdMocha.run {
    setups: environments.map (x) -> _.extend({}, x, {
      name: randomName.first()
      build: buildName
      tags: [username, projectName, branchName].filter (x) -> x
      'custom-data': {
        buildUrl: buildUrl
        tester: username
        project: projectName
        branch: branchName
      }
    })
    url: url
    onDone: (args, callback) -> sauce.updateJob(args.jobid, { passed: args.passed }, callback)
    totalTestTimeout: timeout
    verbose: verbose
    parallelism: parallelism
    wdArgs: ['ondemand.saucelabs.com', 80, sauceUsername, saucePassword]
  }, callback
