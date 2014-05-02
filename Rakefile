require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'

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

  cmd_str = "beaker --options-file .beaker-pe.cfg "
  args.extras.each do |v|
    cmd_str += "#{v} "
  end

  Dir.chdir("./acceptance")
  system(cmd_str)
  Dir.chdir("../")
end

PuppetLint.configuration.ignore_paths = ["spec/**/*.pp", "pkg/**/*.pp","tests/**/*.pp"]
