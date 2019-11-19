require "bundler"
require "yaml"

Bundler.require

require "./lib/optimizely/client"
require "./lib/slack_helpers"
require "./lib/optimizely_helpers"

include OptmizelyHelpers
include SlackHelpers
