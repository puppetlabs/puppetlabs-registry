 require 'puppetlabs_spec_helper/rake_tasks'
 require 'puppet-lint/tasks/puppet-lint'
 require 'puppet_blacksmith/rake_tasks' if Bundler.rubygems.find_name('puppet-blacksmith').any?
begin
  require 'beaker/tasks/test'
rescue LoadError
 #Do nothing, rescue for Windows as beaker does not work and will not be installed
end

#Due to puppet-lint not ignoring tests folder or the ignore paths attribute
#we have to ignore many things
# #Due to bug in puppet-lint we have to clear and redo the lint tasks to achieve ignore paths
 Rake::Task[:lint].clear
 PuppetLint::RakeTask.new(:lint) do |config|
   config.pattern = 'manifests/**/*.pp'
   config.fail_on_warnings = true
   config.disable_checks = [
       '80chars',
       'class_inherits_from_params_class',
       'class_parameter_defaults',
       'documentation',
       'single_quote_string_with_variables']
   config.ignore_paths = ["tests/*.pp", "spec/**/*.pp", "pkg/**/*.pp"]
 end

task :default => [:test]

# The acceptance tests for Registry are written in standard beaker format however
# the preferred method is using beaker-rspec.  This rake task overrides the 
# default `beaker` task, which would normally use beaker-rspec, and instead
# invokes beaker directly.  This is only need while the module tests are migrated
# to the newer rspec-beaker format
task_exists = Rake.application.tasks.any? { |t| t.name == 'beaker' }
Rake::Task['beaker'].clear if task_exists
desc 'Run acceptance testing shim'
task :beaker do |t, args|
  beaker_cmd = "beaker --options-file acceptance/.beaker-pe.cfg --hosts #{ENV['BEAKER_setfile']} --tests acceptance/tests --keyfile #{ENV['BEAKER_keyfile']}"
  Kernel.system( beaker_cmd )
end

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
