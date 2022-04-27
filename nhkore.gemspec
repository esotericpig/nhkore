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

  spec.requirements = [
    'Nokogiri: https://www.nokogiri.org/tutorials/installing_nokogiri.html',
  ]

  spec.required_ruby_version = '>= 2.5'
  spec.require_paths         = ['lib']
  spec.bindir                = 'bin'
  spec.executables           = [spec.name]

  spec.files = [
    Dir.glob(File.join("{#{spec.require_paths.join(',')}}",'**','*.{erb,rb}')),
    Dir.glob(File.join(spec.bindir,'*')),
    Dir.glob(File.join('{samples,test,yard}','**','*.{erb,rb}')),
    %W[ Gemfile Gemfile.lock #{spec.name}.gemspec Rakefile .yardopts ],
    %w[ CHANGELOG.md LICENSE.txt README.md ],
  ].flatten

  spec.add_runtime_dependency 'attr_bool'            ,'~> 0.2'  # For attr_accessor?/attr_reader?
  spec.add_runtime_dependency 'bimyou_segmenter'     ,'~> 1.2'  # For splitting Japanese sentences into words
  spec.add_runtime_dependency 'cri'                  ,'~> 2.15' # For CLI commands/options
  spec.add_runtime_dependency 'down'                 ,'~> 5.3'  # For downloading files (GetCmd)
  spec.add_runtime_dependency 'highline'             ,'~> 2.0'  # For CLI input/output
  spec.add_runtime_dependency 'http-cookie'          ,'~> 1.0'  # For parsing/setting cookies (BingScraper/Scraper)
  spec.add_runtime_dependency 'japanese_deinflector' ,'~> 0.0'  # For unconjugating Japanese words (plain/dictionary form)
  spec.add_runtime_dependency 'nokogiri'             ,'~> 1.13' # For scraping/hacking
  spec.add_runtime_dependency 'psychgus'             ,'~> 1.3'  # For styling Psych YAML
  spec.add_runtime_dependency 'public_suffix'        ,'~> 4.0'  # For parsing URL domain names
  spec.add_runtime_dependency 'rainbow'              ,'~> 3.1'  # For CLI color output
  spec.add_runtime_dependency 'rss'                  ,'~> 0.2'  # For scraping (BingScraper/Scraper)
  spec.add_runtime_dependency 'rubyzip'              ,'~> 2.3'  # For extracting Zip files (GetCmd)
  spec.add_runtime_dependency 'tiny_segmenter'       ,'~> 0.0'  # For splitting Japanese sentences into words
  spec.add_runtime_dependency 'tty-progressbar'      ,'~> 0.18' # For CLI progress bars
  spec.add_runtime_dependency 'tty-spinner'          ,'~> 0.9'  # For CLI spinning progress

  spec.add_development_dependency 'bundler'   ,'~> 2.3'
  spec.add_development_dependency 'minitest'  ,'~> 5.15'
  spec.add_development_dependency 'rake'      ,'~> 13.0'
  spec.add_development_dependency 'raketeer'  ,'~> 0.2'  # For extra Rake tasks
  spec.add_development_dependency 'rdoc'      ,'~> 6.4'  # For YARDoc RDoc (*.rb)
  spec.add_development_dependency 'redcarpet' ,'~> 3.5'  # For YARDoc Markdown (*.md)
  spec.add_development_dependency 'yard'      ,'~> 0.9'  # For documentation
  spec.add_development_dependency 'yard_ghurt','~> 1.2'  # For extra YARDoc Rake tasks

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
  #puts spec.post_install_message.split("\n").map(&:length).max

  spec.extra_rdoc_files = %w[ CHANGELOG.md LICENSE.txt README.md ]

  spec.rdoc_options = [
    '--hyperlink-all','--show-hash',
    '--title',"NHKore v#{NHKore::VERSION} Doc",
    '--main','README.md',
  ]
end
