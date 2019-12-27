require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["spec/**/*_spec.rb"]
end

task :spec => :test
namespace :test do
  task :watch do |t, args|
    require "filewatcher"

    watcher = Filewatcher.new(["spec/", "lib/"], :every => true, :spinner => true, :immediate => true)
    watcher.watch do |filename, event|
      begin
        Rake::Task[:test].execute(args)
      rescue StandardError => error
        puts "Error: #{error.message}"
      end
    end
  end
end
task :default => :test
