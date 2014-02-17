$: << File.expand_path('../lib', __FILE__)

require 'rspec'
require 'yaml'

require 'second-contract'

SecondContract.config([], 'test')