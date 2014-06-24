require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'
require 'beaker/tasks/test'

#Due to puppet-lint not ignoring tests folder or the ignore paths attribute
#we have to ignore many things
PuppetLint.configuration.ignore_paths = ["tests/*.pp","spec/**/*.pp","pkg/**/*.pp"]
PuppetLint.configuration.send("disable_80chars")
PuppetLint.configuration.send("disable_autoloader_layout")
PuppetLint.configuration.send("disable_double_quoted_strings")

task :default => [:test]

desc 'Run RSpec'
RSpec::Core::RakeTask.new(:test) do |t|
  t.pattern = 'spec/{unit}/**/*.rb'
  #t.rspec_opts = ['--color']
end

desc 'Generate code coverage'
RSpec::Core::RakeTask.new(:coverage) do |t|
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec']
end

desc "Run rake tasks"
task "beaker:test:pe" do |t, args|

  cmd_str = "beaker --options-file ./acceptance/.beaker-pe.cfg "
  args.extras.each do |v|
    cmd_str += "#{v} "
  end

  #Dir.chdir("./")
  system(cmd_str)
  #Dir.chdir("../")
end



