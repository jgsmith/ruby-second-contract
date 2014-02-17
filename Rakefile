$: << './lib'

require 'rspec/core/rake_task'
#require 'rake/testtask'
require 'second-contract/activerecord/rake'

RSpec::Core::RakeTask.new(:test) do |t|
  t.pattern = 'test/{compilers,factories,machines,models,parsers}/**/*_tests.rb'
  t.rspec_opts = '--format progress --require test_helper'
  t.ruby_opts = "-I./test"
end

SecondContract::ActiveRecordTasks.database_file = 'config/database.yml'

#test_files = Dir.glob('test/{compilers,factories,machines,models,parsers}/**/*_tests.rb')

file "lib/second-contract/parser/grammar.rb" => [ "parsers/grammar.y" ] do |t|
  sh "racc -v -t -o #{t.name} #{t.prerequisites.join(' ')}"
end

file "lib/second-contract/parser/mudmode.rb" => [ "parsers/mudmode.y" ] do |t|
  sh "racc -o #{t.name} #{t.prerequisites.join(' ')}"
end

#Rake::TestTask.new do |t|
#  t.libs << 'test'
#  t.libs << 'lib'
#
#  t.test_files = test_files.sort
#
#  t.warning = true
#  t.verbose = true
#end

task :build => [ "lib/second-contract/parser/grammar.rb", "lib/second-contract/parser/mudmode.rb" ] do
end

task :default => [ :build, :'db:migrate', :test ] do
end

task :run do
  sh "driver"
end

task :lines do
  lines, codelines, total_lines, total_codelines = 0, 0, 0, 0

  FileList["lib/**/*.rb"].each do |file_name|
    next if file_name =~ /vendor/
    File.open(file_name, 'r') do |f|
      while line = f.gets
        lines += 1
        next if line =~ /^\s*$/
        next if line =~ /^\s*#/
        codelines += 1
      end
    end
    puts "L: #{sprintf("%4d", lines)}, LOC #{sprintf("%4d", codelines)} | #{file_name}"

    total_lines     += lines
    total_codelines += codelines

    lines, codelines = 0, 0
  end

  puts "Total: Lines #{total_lines}, LOC #{total_codelines}"
end
