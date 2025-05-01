# encoding: UTF-8
# frozen_string_literal: true

require 'bundler/gem_tasks'

require 'rake/clean'
require 'rake/testtask'
require 'yard'

require 'nhkore/util'
require 'nhkore/version'

PKG_DIR = 'pkg'

CLEAN.exclude('{.git,core,stock}/**/*')
CLOBBER.include('doc/',"#{PKG_DIR}/")

task default: %i[test]

desc 'Generate documentation (YARDoc)'
task doc: %i[yard]

desc "Package '#{NHKore::Util::CORE_DIR}/' data as a Zip file into '#{PKG_DIR}/'"
task :pkg_core do |_task|
  mkdir_p PKG_DIR

  pattern = "#{NHKore::Util::CORE_DIR}/*.{csv,html,json,yml}"
  zip_file = File.join(PKG_DIR,'nhkore-core.zip')

  sh 'zip','-9rv',zip_file,*Dir.glob(pattern)
end

Rake::TestTask.new do |task|
  task.libs = %w[lib test]
  task.pattern = 'test/**/*_test.rb'
  task.verbose = false
  task.warning = true
end

# If you need to run a part after the 1st part,
# just type 'n' to not overwrite the file and then 'y' for continue.
desc "Update '#{NHKore::Util::CORE_DIR}/' files for release"
task :update_core do |_task|
  require 'highline'

  continue_msg = "\nContinue (y/n)? "

  cmd = ['ruby','-w','./lib/nhkore.rb','-t','300','-m','10']
  hl = HighLine.new

  next unless sh(*cmd,'se','--show-count','ez')
  puts

  next unless sh(*cmd,'se','-l','10','ez','bing')
  next unless hl.agree(continue_msg)
  puts

  next unless sh(*cmd,'news','-s','1000','ez','--lenient')
  next unless hl.agree(continue_msg)
  puts

  next unless sh(*cmd,'sift','-e','csv' ,'ez')
  puts
  next unless sh(*cmd,'sift','-e','html','ez')
  puts
  next unless sh(*cmd,'sift','-e','json','ez')
  puts
  next unless sh(*cmd,'sift','-e','yml' ,'ez')
  puts
end

desc 'Update showcase file for release'
task :update_showcase do |_task|
  require 'highline'

  showcase_file = File.join('.','nhkore-ez.html')

  hl = HighLine.new

  next unless sh('ruby','-w','./lib/nhkore.rb',
                 'sift','ez','--no-eng',
                 '--out',showcase_file)

  dest_dir = File.join('..','esotericpig.github.io','showcase','')

  next unless hl.agree("\nMove the file to '#{dest_dir}' (y/n)? ")
  puts
  next unless sh('mv','-iv',showcase_file,dest_dir)
end

YARD::Rake::YardocTask.new do |task|
  task.options += ['--title',"NHKore v#{NHKore::VERSION} Doc"]
end
