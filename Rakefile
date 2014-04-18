require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'

#desc 'Run RSpec'
#RSpec::Core::RakeTask.new(:test) do |t|
  #t.pattern = 'spec/{unit}/**/*.rb'
#  t.rspec_opts = ['--color']
#end

desc 'Generate code coverage'
RSpec::Core::RakeTask.new(:coverage) do |t|
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec']
end

PuppetLint.configuration.ignore_paths = ["spec/**/*.pp", "pkg/**/*.pp","tests/**/*.pp"]
