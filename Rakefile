# encoding: UTF-8
# frozen_string_literal: true


require 'bundler/gem_tasks'

require 'rake/clean'
require 'rake/testtask'
require 'raketeer/irb'
require 'raketeer/nokogiri_installs'
require 'yard'
require 'yard_ghurt'

require 'nhkore/util'
require 'nhkore/version'


PKG_DIR = 'pkg'

CLEAN.exclude('{.git,core,stock}/**/*')
CLOBBER.include('doc/',File.join(PKG_DIR,''))


task default: [:test]

desc 'Generate documentation (YARDoc)'
task doc: %i[yard yard_gfm_fix] do |task|
end

desc "Package '#{File.join(NHKore::Util::CORE_DIR,'')}' data as a Zip file into '#{File.join(PKG_DIR,'')}'"
task :pkg_core do |task|
  mkdir_p PKG_DIR

  pattern = File.join(NHKore::Util::CORE_DIR,'*.{csv,html,json,yml}')
  zip_file = File.join(PKG_DIR,'nhkore-core.zip')

  sh 'zip','-9rv',zip_file,*Dir.glob(pattern).sort
end

Rake::TestTask.new do |task|
  task.libs = ['lib','test']
  task.pattern = File.join('test','**','*_test.rb')
  task.description += ": '#{task.pattern}'"
  task.verbose = false
  task.warning = true
end

# If you need to run a part after the 1st part,
# just type 'n' to not overwrite the file and then 'y' for continue.
desc "Update '#{File.join(NHKore::Util::CORE_DIR,'')}' files for release"
task :update_core do |task|
  require 'highline'

  continue_msg = "\nContinue (y/n)? "

  cmd = ['ruby','-w','./lib/nhkore.rb','-t','300','-m','10']
  hl = HighLine.new

  next unless sh(*cmd,'se','-l','10','ez','bing')
  next unless hl.agree(continue_msg)
  puts

  next unless sh(*cmd,'news','-s','1000','ez')
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

# @since 0.3.6
desc 'Update showcase file for release'
task :update_showcase do |task|
  require 'highline'

  showcase_file = File.join('.','nhkore-ez.html')

  hl = HighLine.new

  next unless sh('ruby','-w','./lib/nhkore.rb',
    'sift','ez','--no-eng',
    '--out',showcase_file,
  )

  next unless hl.agree("\nMove the file (y/n)? ")
  puts
  next unless sh('mv','-iv',showcase_file,
    File.join('..','esotericpig.github.io','showcase',''),
  )
end

YARD::Rake::YardocTask.new do |task|
  task.options += ['--template-path',File.join('yard','templates')]
  task.options += ['--title',"NHKore v#{NHKore::VERSION} Doc"]
end

# Execute "rake yard_gfm_fix" for production.
# Execute "rake yard_gfm_fix[true]" for testing locally.
YardGhurt::GFMFixTask.new do |task|
  task.arg_names = [:dev]
  task.dry_run = false
  task.fix_code_langs = true
  task.md_files = ['index.html']

  task.before = proc do |t,args|
    # Delete this file as it's never used (index.html is an exact copy).
    YardGhurt::Util.rm_exist(File.join(t.doc_dir,'file.README.html'))

    # Root dir of my GitHub Page for CSS/JS.
    ghp_root = YardGhurt::Util.to_bool(args.dev) ? '../../esotericpig.github.io' : '../../..'

    t.css_styles << %Q(<link rel="stylesheet" type="text/css" href="#{ghp_root}/css/prism.css" />)
    t.js_scripts << %Q(<script src="#{ghp_root}/js/prism.js"></script>)
  end
end

# Probably not useful for others.
YardGhurt::GHPSyncTask.new do |task|
  task.ghp_dir = '../esotericpig.github.io/docs/nhkore/yardoc'
end
