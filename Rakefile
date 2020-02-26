# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020 Jonathan Bradley Whited (@esotericpig)
# 
# NHKore is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# NHKore is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public License
# along with NHKore.  If not, see <https://www.gnu.org/licenses/>.
#++


require 'bundler/gem_tasks'

require 'nhkore/util'
require 'nhkore/version'
require 'rake/clean'
require 'rake/testtask'
require 'raketeer/irb'
require 'raketeer/nokogiri_installs'
require 'raketeer/run'
require 'yard'
require 'yard_ghurt'


PKG_DIR = 'pkg'

CLEAN.exclude('.git/','stock/')
CLOBBER.include('doc/',File.join(PKG_DIR,''))


task default: [:test]

desc 'Generate documentation (YARDoc)'
task :doc => [:yard,:yard_gfm_fix] do |task|
end

desc "Package '#{File.join(NHKore::Util::CORE_DIR,'')}' data as a Zip file into '#{File.join(PKG_DIR,'')}'"
task :pkg_core do |task|
  pattern = File.join(NHKore::Util::CORE_DIR,'**','*.{csv,yml}')
  zip_name = "nhkore-core-#{NHKore::VERSION}.zip"
  zip_file = File.join(PKG_DIR,zip_name)
  
  mkdir_p PKG_DIR
  
  Dir.glob(pattern).sort().each() do |file|
    # Rake::PackageTask does the same thing
    sh 'zip','-8','-r',zip_file,file
  end
end

Rake::TestTask.new() do |task|
  task.libs = ['lib','test']
  task.pattern = File.join('test','**','*_test.rb')
  task.description += ": '#{task.pattern}'"
  task.verbose = true
  task.warning = true
end

YARD::Rake::YardocTask.new() do |task|
  task.files = [File.join('lib','**','*.rb')]
  
  task.options += ['--files','CHANGELOG.md,LICENSE.txt']
  task.options += ['--readme','README.md']
  
  task.options << '--protected' # Show protected methods
  task.options += ['--template-path',File.join('yard','templates')]
  task.options += ['--title',"NHKore v#{NHKore::VERSION} Doc"]
end

# Execute "yard_gfm_fix" for production.
# Execute "yard_gfm_fix[true]" for testing locally.
YardGhurt::GFMFixTask.new() do |task|
  task.arg_names = [:dev]
  task.dry_run = false
  task.fix_code_langs = true
  task.md_files = ['index.html']
  
  task.before = Proc.new() do |task,args|
    # Delete this file as it's never used (index.html is an exact copy)
    YardGhurt::Util.rm_exist(File.join(task.doc_dir,'file.README.html'))
    
    # Root dir of my GitHub Page for CSS/JS
    GHP_ROOT = YardGhurt::Util.to_bool(args.dev) ? '../../esotericpig.github.io' : '../../..'
    
    task.css_styles << %Q(<link rel="stylesheet" type="text/css" href="#{GHP_ROOT}/css/prism.css" />)
    task.js_scripts << %Q(<script src="#{GHP_ROOT}/js/prism.js"></script>)
  end
end

# Execute "rake yard_ghp_sync" for a dry run.
# Execute "rake yard_ghp_sync[true]" for actually deploying.
YardGhurt::GHPSyncTask.new() do |task|
  task.description = %q(Rsync "doc/" to my GitHub Page's repo; not useful for others)
  
  task.ghp_dir = '../esotericpig.github.io/docs/nhkore/yardoc'
  task.sync_args << '--delete-after'
end
