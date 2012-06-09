require '../config/env.rb'
require '../lib/pixel_imp_conversions'
require '../lib/misc_helpers'
require '../lib/randomizers'
require '../lib/reporters'
require '../lib/log_manipulators'
require '../lib/sql_commands'
require '../lib/reporters'
require '../lib/cookies'

include FetchBackConstants
include FetchBackCookies
include LogManipulators
include Randomizers
include MiscHelpers
include PixImpConv
include Reporters
include SQLCommands
include Pages

@config = FBConfig.new(:rt)