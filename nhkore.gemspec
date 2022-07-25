# encoding: UTF-8
# frozen_string_literal: true


require_relative 'lib/nhkore/version'

Gem::Specification.new do |spec|
  spec.name        = 'nhkore'
  spec.version     = NHKore::VERSION
  spec.authors     = ['Jonathan Bradley Whited']
  spec.email       = ['code@esotericpig.com']
  spec.licenses    = ['LGPL-3.0-or-later']
  spec.homepage    = 'https://github.com/esotericpig/nhkore'
  spec.summary     = 'NHK News Web (Easy) word frequency (core) scraper for Japanese language learners.'
  spec.description =
    'Scrapes NHK News Web (Easy) for the word frequency (core list) for Japanese language learners.' \
    ' Includes a CLI app and a scraper library.'

  spec.metadata = {
    'homepage_uri'      => 'https://github.com/esotericpig/nhkore',
    'source_code_uri'   => 'https://github.com/esotericpig/nhkore',
    'bug_tracker_uri'   => 'https://github.com/esotericpig/nhkore/issues',
    'changelog_uri'     => 'https://github.com/esotericpig/nhkore/blob/master/CHANGELOG.md',
    #'documentation_uri' => '',
    #'wiki_uri'          => '',
    #'mailing_list_uri'  => '',
  }

  spec.required_ruby_version = '>= 2.5'
  spec.requirements = [
    'Nokogiri: https://www.nokogiri.org/tutorials/installing_nokogiri.html',
  ]

  spec.require_paths = ['lib']
  spec.bindir        = 'bin'
  spec.executables   = [spec.name]

  spec.extra_rdoc_files = %w[ CHANGELOG.md LICENSE.txt README.md ]
  spec.rdoc_options = [
    '--hyperlink-all','--show-hash',
    '--title',"NHKore v#{NHKore::VERSION} Doc",
    '--main','README.md',
  ]

  spec.files = [
    Dir.glob(File.join("{#{spec.require_paths.join(',')}}",'**','*.{erb,rb}')),
    Dir.glob(File.join(spec.bindir,'*')),
    Dir.glob(File.join('{samples,test,yard}','**','*.{erb,rb}')),
    %W[ Gemfile Gemfile.lock #{spec.name}.gemspec Rakefile .yardopts ],
    spec.extra_rdoc_files,
  ].flatten

  run_dep = spec.method(:add_runtime_dependency)
  run_dep[ 'attr_bool'           ,'~> 0.2'  ] # attr_accessor?/attr_reader?.
  run_dep[ 'bimyou_segmenter'    ,'~> 1.2'  ] # Splitting Japanese sentences into words.
  run_dep[ 'cri'                 ,'~> 2.15' ] # CLI commands/options.
  run_dep[ 'down'                ,'~> 5.3'  ] # Downloading files (GetCmd).
  run_dep[ 'highline'            ,'~> 2.0'  ] # CLI input/output.
  run_dep[ 'http-cookie'         ,'~> 1.0'  ] # Parsing/Setting cookies [(Bing)Scraper].
  run_dep[ 'japanese_deinflector','~> 0.0'  ] # Unconjugating Japanese words (dictionary form).
  run_dep[ 'nokogiri'            ,'~> 1.13' ] # Scraping/Hacking.
  run_dep[ 'psychgus'            ,'~> 1.3'  ] # Styling Psych YAML.
  run_dep[ 'public_suffix'       ,'~> 4.0'  ] # Parsing URL domain names.
  run_dep[ 'rainbow'             ,'~> 3.1'  ] # CLI color output.
  run_dep[ 'rss'                 ,'~> 0.2'  ] # Scraping [(Bing)Scraper].
  run_dep[ 'rubyzip'             ,'~> 2.3'  ] # Extracting Zip files (GetCmd).
  run_dep[ 'tiny_segmenter'      ,'~> 0.0'  ] # Splitting Japanese sentences into words.
  run_dep[ 'tty-progressbar'     ,'~> 0.18' ] # CLI progress bars.
  run_dep[ 'tty-spinner'         ,'~> 0.9'  ] # CLI spinning progress.

  dev_dep = spec.method(:add_development_dependency)
  dev_dep[ 'bundler'   ,'~> 2.3'  ]
  dev_dep[ 'minitest'  ,'~> 5.16' ]
  dev_dep[ 'rake'      ,'~> 13.0' ]
  dev_dep[ 'raketeer'  ,'~> 0.2'  ] # Extra Rake tasks.
  dev_dep[ 'rdoc'      ,'~> 6.4'  ] # YARDoc RDoc (*.rb).
  dev_dep[ 'redcarpet' ,'~> 3.5'  ] # YARDoc Markdown (*.md).
  dev_dep[ 'yard'      ,'~> 0.9'  ] # Doc.
  dev_dep[ 'yard_ghurt','~> 1.2'  ] # Extra YARDoc Rake tasks.

  spec.post_install_message = <<~MSG
    +=============================================================================+
    | NHKore v#{NHKore::VERSION}
    |
    | You can now use [#{spec.executables.join(', ')}] on the command line.
    |
    | Homepage:  #{spec.homepage}
    | Code:      #{spec.metadata['source_code_uri']}
    | Bugs:      #{spec.metadata['bug_tracker_uri']}
    | Changelog: #{spec.metadata['changelog_uri']}
    +=============================================================================+
  MSG

  # Uncomment to see max line length:
  #puts spec.post_install_message.split("\n").map(&:length).max
end
