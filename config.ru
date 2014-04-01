require 'rubygems'
require 'bundler'
Bundler.require
require 'sprockets'
require './environment'
require './app'

map '/assets' do
  foundation_path = Bundler.load.specs.select{|g| g.name=="zurb-foundation"}.first.full_gem_path

  environment = Sprockets::Environment.new
  environment.cache = Sprockets::Cache::FileStore.new("/tmp")

  environment.append_path 'assets/js'
  environment.append_path 'assets/scss'
  environment.append_path 'assets/img'
  environment.append_path "#{foundation_path}/js"
  environment.append_path "#{foundation_path}/scss"
  run environment
end

set :raise_errors, true
run App
