#!/usr/bin/env node

var fs = require('fs');
var path = require('path');
var nconf = require('nconf');
var _ = require('underscore');
var optimist = require('optimist');
var wdMocha = require('../lib/driver');
var sauce = require('../lib/runner-saucelabs');
var localCore = require('../lib/runner-localOpra');

var argv = optimist
  .usage('Runs mocha tests using selenium')
  .describe('platform', 'Platform for running the tests')
  .describe('platforms', 'List available platforms')
  .describe('version', 'Print the current version number')
  .describe('help', 'Show this help message')
  .alias('platform', 'p')
  .alias('version', 'v')
  .alias('help', 'h')
  .argv;

if (argv.help) {
  console.log(optimist.help());
  return;
}

if (argv.version) {
  console.log(require('../package.json').version);
  return;
}

if (argv.platforms) {
  console.log()
  console.log("  local: Run test locally using an OPRA-server")
  console.log("  saucelabs: Run tests on saucelabs.com")
  console.log()
  return;
}

nconf.argv().env('__').file('config', 'config.json').file('package', 'package.json');

var pack = JSON.parse(fs.readFileSync('package.json'));
var testSpec = pack['test-spec'];


if (argv.platform == 'local') {
  localCore.run({
    verbose: true,
    browsers: _(testSpec.environments).chain().pluck('browserName').uniq().value(),
    path: testSpec.path,
    timeout: testSpec.timeout,
    opraSettings: {
      port: 8022,
      root: pack.opra.sourceDir
    }
  }, function(err, res) {
    process.exit(wdMocha.finalLog(err, res) ? 0 : 1)
  });
} else if (argv.platform == 'saucelabs') {
  sauce.run({
    environments: testSpec.environments,
    username: process.env.CI_COMMITTER_USERNAME || process.env.USERNAME || process.env.USER,
    projectName: pack.name,
    branchName: process.env.CI_BRANCH, // todo: add a method to extract this locally,
    buildUrl: process.env.CI_BUILD_URL,
    timeout: testSpec.timeout,
    url: "http://" + testSpec.remoteDomain + testSpec.path,
    verbose: true,
    parallelism: 2,
    sauceUsername: nconf.get('saucelabs:username'),
    saucePassword: nconf.get('saucelabs:password')
  }, function(err, res) {
    process.exit(wdMocha.finalLog(err, res) ? 0 : 1)
  });
} else {
  console.log('Invalid platform "' + argv.platform + '". Use --platforms to list available options.')
  process.exit(1);
}
