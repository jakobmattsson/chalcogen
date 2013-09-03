#!/usr/bin/env node

var fs = require('fs');
var path = require('path');
var nconf = require('nconf');
var _ = require('underscore');
var optimist = require('optimist');
var wdMocha = require('../lib/driver');

var argv = optimist
  .usage('Runs mocha tests using selenium\nAll options can be given as program arguments, environment vars or from one of the three files package.json, config.json or chalcogen.json')
  .describe('platform', 'Platform for running the tests')
  .describe('platforms', 'List available platforms')
  .describe('version', 'Print the current version number')
  .describe('help', 'Show this help message')

  .describe('name', 'Name of project, usually from package.json')
  .describe('chalcogen:parallelism', 'Number of tests to run in parallel')
  .describe('chalcogen:silent', 'No logging, only process return value')
  .describe('chalcogen:path', 'Path on the website to the mocha test')
  .describe('chalcogen:branch', 'Name of the current SCM branch')
  .describe('chalcogen:buildUrl', 'Url to info about the current build (for CI)')
  .describe('chalcogen:environments', 'List of environments on selenium caps format')
  .describe('chalcogen:timeout', 'Selenium timeout for the entire test')
  .describe('chalcogen:domain', 'Domain to test, in case not running locally')
  .describe('chalcogen:username', 'Name of the current user of the system')

  .describe('opra', 'Opra settings, if running the opra platform')
  .describe('saucelabs:username', 'Username for saucelabs cloud testing')
  .describe('saucelabs:password', 'Password for saucelabs cloud testing')

  .default('chalcogen:parallelism', 9001)
  .default('chalcogen:silent', false)
  .default('chalcogen:timeout', 90000)

  .boolean('chalcogen:silent')

  .alias('chalcogen:branch', 'CI_BRANCH')
  .alias('chalcogen:username', 'CI_COMMITTER_USERNAME')
  .alias('chalcogen:username', 'USERNAME')
  .alias('chalcogen:username', 'USERNAME')
  .alias('chalcogen:buildUrl', 'CI_BUILD_URL')
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
  console.log("  local: Run test using local selenium browsers")
  console.log("  opra: Run test using an OPRA-server and local selenium browsers")
  console.log("  saucelabs: Run tests on saucelabs.com")
  console.log()
  return;
}

nconf.argv().env('__').file('chalcogen-config', 'chalcogen.json').file('secret-config', 'config.json').file('package', 'package.json');

if (argv.platform == 'opra') {
  var localCore = require('../lib/runner-localOpra');
  localCore.run(wdMocha, {
    verbose: !nconf.get('chalcogen:silent'),
    browsers: _(nconf.get('chalcogen:environments')).chain().pluck('browserName').uniq().value(),
    path: nconf.get('chalcogen:path'),
    timeout: nconf.get('chalcogen:timeout'),
    opraSettings: nconf.get('opra')
  }, function(err, res) {
    process.exit(wdMocha.finalLog(err, res) ? 0 : 1)
  });
} else if (argv.platform == 'local') {
  var localCore = require('../lib/runner-local');
  localCore.run(wdMocha, {
    verbose: !nconf.get('chalcogen:silent'),
    browsers: _(nconf.get('chalcogen:environments')).chain().pluck('browserName').uniq().value(),
    url: "http://" + nconf.get('chalcogen:domain') + nconf.get('chalcogen:path'),
    timeout: nconf.get('chalcogen:timeout')
  }, function(err, res) {
    process.exit(wdMocha.finalLog(err, res) ? 0 : 1)
  });
} else if (argv.platform == 'saucelabs') {
  var sauce = require('../lib/runner-saucelabs');
  sauce.run(wdMocha, {
    environments: nconf.get('chalcogen:environments'),
    username: nconf.get('chalcogen:username') || nconf.get('CI_COMMITTER_USERNAME') || nconf.get('USERNAME') || nconf.get('USER'),
    projectName: nconf.get('name'),
    branchName: nconf.get('chalcogen:branch') || nconf.get('CI_BRANCH'),
    buildUrl: nconf.get('chalcogen:buildUrl') || nconf.get('CI_BUILD_URL'),
    timeout: nconf.get('chalcogen:timeout'),
    url: "http://" + nconf.get('chalcogen:domain') + nconf.get('chalcogen:path'),
    verbose: !nconf.get('chalcogen:silent'),
    parallelism: nconf.get('chalcogen:parallelism'),
    sauceUsername: nconf.get('saucelabs:username'),
    saucePassword: nconf.get('saucelabs:password')
  }, function(err, res) {
    process.exit(wdMocha.finalLog(err, res) ? 0 : 1)
  });
} else {
  console.log('Invalid platform "' + argv.platform + '". Use --platforms to list available options.')
  process.exit(1);
}
