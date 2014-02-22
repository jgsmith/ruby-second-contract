$: << File.expand_path('../lib', __FILE__)

require 'rspec'
require 'yaml'

require 'second-contract'
require 'factory_girl'

SecondContract.config([], 'test')
SecondContract::Game.instance.compile_all

##
# makes sure the database has the necessary setup to place
# _direct_ in a relationship with _target_ as specified by
# _preposition_
#
def place(direct, preposition, target, detail = 'default')
  ItemRelationship.create!(
    source: direct,
    target: target,
    detail: detail,
    preposition: preposition
  )
end