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
