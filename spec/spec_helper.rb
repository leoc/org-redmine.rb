require 'rubygems'
require 'bundler'
require 'highline/import'
require 'commander'
require 'redmine_api'

Bundler.require

$LOAD_PATH << '../lib'

require 'org'
require 'core_ext'
require 'org-redmine'

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end
