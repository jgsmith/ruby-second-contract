$: << './lib'

require 'rspec/core/rake_task'
require 'second-contract/activerecord/rake'

RSpec::Core::RakeTask.new(:spec)

SecondContract::ActiveRecordTasks.database_file = 'config/database.yml'

file "lib/second-contract/parser/grammar.rb" => [ "parsers/grammar.y" ] do |t|
  sh "racc -v -t -o #{t.name} #{t.prerequisites.join(' ')}"
end

file "lib/second-contract/parser/mudmode.rb" => [ "parsers/mudmode.y" ] do |t|
  sh "racc -o #{t.name} #{t.prerequisites.join(' ')}"
end

task :build => [ "lib/second-contract/parser/grammar.rb", "lib/second-contract/parser/mudmode.rb" ] do
end

task :default => [ :build, :'db:migrate', :spec ] do
end

task :run do
  sh "driver"
end