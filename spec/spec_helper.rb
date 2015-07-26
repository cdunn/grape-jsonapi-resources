$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'bundler'
Bundler.setup :default, :test

require 'rails'
require 'action_controller'
require 'active_model'
require 'jsonapi-resources'
require 'active_support/core_ext/hash/conversions'
require 'active_support/json'
require 'rspec'
require 'rack/test'
require 'grape-jsonapi-resources'

RSpec.configure do |config|
  config.include Rack::Test::Methods
end

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
