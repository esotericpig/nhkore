# encoding: UTF-8
# frozen_string_literal: true

require_relative 'lib/nhkore/version'

Gem::Specification.new do |spec|
  spec.name        = 'nhkore'
  spec.version     = NHKore::VERSION
  spec.authors     = ['Bradley Whited']
  spec.email       = ['code@esotericpig.com']
  spec.licenses    = ['LGPL-3.0-or-later']
  spec.homepage    = 'https://github.com/esotericpig/nhkore'
  spec.summary     = 'NHK News Web (Easy) word frequency (core) scraper for Japanese language learners.'
  spec.description = <<~DESC
    Scrapes NHK News Web (Easy) for the word frequency (core list) for Japanese language learners.
    Includes a CLI app and a scraper library.
  DESC

  spec.metadata = {
    'rubygems_mfa_required' => 'true',
    'homepage_uri'          => 'https://github.com/esotericpig/nhkore',
    'source_code_uri'       => 'https://github.com/esotericpig/nhkore',
    'bug_tracker_uri'       => 'https://github.com/esotericpig/nhkore/issues',
    'changelog_uri'         => 'https://github.com/esotericpig/nhkore/blob/master/CHANGELOG.md',
    # 'documentation_uri'     => '',
    # 'wiki_uri'              => '',
    # 'mailing_list_uri'      => '',
  }

  spec.required_ruby_version = '>= 3.1'
  spec.requirements = [
    'Nokogiri: https://www.nokogiri.org/tutorials/installing_nokogiri.html',
  ]

  spec.require_paths = ['lib']
  spec.bindir        = 'bin'
  spec.executables   = [spec.name]

  spec.extra_rdoc_files = %w[LICENSE.txt CHANGELOG.md README.md]
  spec.rdoc_options = [
    '--hyperlink-all','--show-hash',
    '--title',"NHKore v#{NHKore::VERSION} Doc",
    '--main','README.md',
  ]

  spec.files = [
    Dir.glob("{#{spec.require_paths.join(',')}}/**/*.{erb,rb}"),
    Dir.glob("#{spec.bindir}/{#{spec.executables.join(',')}}"),
    Dir.glob('{samples,spec,test,yard}/**/*.{erb,rb}'),
    %W[Gemfile Gemfile.lock #{spec.name}.gemspec Rakefile .yardopts],
    spec.extra_rdoc_files,
  ].flatten

  # Japanese.
  spec.add_dependency 'bimyou_segmenter'    ,'~> 1.2'  # Splits Japanese sentences into words.
  spec.add_dependency 'japanese_deinflector','~> 0.0'  # Un-conjugates Japanese words (dictionary form).
  spec.add_dependency 'tiny_segmenter'      ,'~> 0.0'  # Splits Japanese sentences into words.
  # Network/Scraping.
  spec.add_dependency 'down'                ,'~> 5.4'  # Downloads files (GetCmd).
  spec.add_dependency 'http-cookie'         ,'~> 1.0'  # Parses/Sets cookies [(Bing)Scraper].
  spec.add_dependency 'nokogiri'            ,'~> 1'    # Parses HTML.
  spec.add_dependency 'public_suffix'       ,'~> 6.0'  # Parses URL domain names.
  spec.add_dependency 'rss'                 ,'~> 0.3'  # Parses RSS feeds [(Bing)Scraper].
  # Data/Files.
  spec.add_dependency 'csv'                 ,'~> 3.3'  # Outputs CSV.
  spec.add_dependency 'psychgus'            ,'~> 1.3'  # Styles Psych YAML.
  spec.add_dependency 'rubyzip'             ,'~> 2.4'  # Extracts Zip files (GetCmd).
  # CLI.
  spec.add_dependency 'cri'                 ,'~> 2.15' # CLI commands/options.
  spec.add_dependency 'highline'            ,'~> 3.1'  # CLI IO.
  spec.add_dependency 'rainbow'             ,'~> 3.1'  # CLI color output.
  spec.add_dependency 'tty-progressbar'     ,'~> 0.18' # CLI progress bars.
  spec.add_dependency 'tty-spinner'         ,'~> 0.9'  # CLI spinning progress.
  # Utils.
  spec.add_dependency 'attr_bool'           ,'~> 0.2'  # attr_accessor?/attr_reader?.

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
end
