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


lib = File.expand_path(File.join('..','lib'),__FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'nhkore/version'

Gem::Specification.new() do |spec|
  spec.name        = 'nhkore'
  spec.version     = NHKore::VERSION
  spec.authors     = ['Jonathan Bradley Whited (@esotericpig)']
  spec.email       = ['bradley@esotericpig.com']
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
  
  spec.required_ruby_version = '>= 2.4'
  spec.require_paths         = ['lib']
  spec.bindir                = 'bin'
  spec.executables           = [spec.name]
  
  spec.files = [
    Dir.glob(File.join("{#{spec.require_paths.join(',')}}",'**','*.{erb,rb}')),
    Dir.glob(File.join(spec.bindir,'*')),
    Dir.glob(File.join('{samples,test,yard}','**','*.{erb,rb}')),
    %W[ Gemfile Gemfile.lock #{spec.name}.gemspec Rakefile .yardopts ],
    %w[ CHANGELOG.md LICENSE.txt README.md ],
  ].flatten()
  
  spec.add_runtime_dependency 'attr_bool'            ,'~> 0.2'  # For attr_accessor?/attr_reader?
  spec.add_runtime_dependency 'bimyou_segmenter'     ,'~> 1.2'  # For splitting Japanese sentences into words
  spec.add_runtime_dependency 'cri'                  ,'~> 2.15' # For CLI commands/options
  spec.add_runtime_dependency 'down'                 ,'~> 5.1'  # For downloading files (GetCmd)
  spec.add_runtime_dependency 'highline'             ,'~> 2.0'  # For CLI input/output
  spec.add_runtime_dependency 'http-cookie'          ,'~> 1.0'  # For parsing/setting cookies (BingScraper/Scraper)
  spec.add_runtime_dependency 'japanese_deinflector' ,'~> 0.0'  # For unconjugating Japanese words (plain/dictionary form)
  spec.add_runtime_dependency 'nokogiri'             ,'~> 1.10' # For scraping/hacking
  spec.add_runtime_dependency 'psychgus'             ,'~> 1.3'  # For styling Psych YAML
  spec.add_runtime_dependency 'public_suffix'        ,'~> 4.0'  # For parsing URL domain names
  spec.add_runtime_dependency 'rainbow'              ,'~> 3.0'  # For CLI color output
  spec.add_runtime_dependency 'rubyzip'              ,'~> 2.3'  # For extracting Zip files (GetCmd)
  spec.add_runtime_dependency 'tiny_segmenter'       ,'~> 0.0'  # For splitting Japanese sentences into words
  spec.add_runtime_dependency 'tty-progressbar'      ,'~> 0.17' # For CLI progress bars
  spec.add_runtime_dependency 'tty-spinner'          ,'~> 0.9'  # For CLI spinning progress
  
  spec.add_development_dependency 'bundler'   ,'~> 2.1'
  spec.add_development_dependency 'minitest'  ,'~> 5.14'
  spec.add_development_dependency 'rake'      ,'~> 13.0'
  spec.add_development_dependency 'raketeer'  ,'~> 0.2'  # For extra Rake tasks
  spec.add_development_dependency 'rdoc'      ,'~> 6.2'  # For YARDoc RDoc (*.rb)
  spec.add_development_dependency 'redcarpet' ,'~> 3.5'  # For YARDoc Markdown (*.md)
  spec.add_development_dependency 'yard'      ,'~> 0.9'  # For documentation
  spec.add_development_dependency 'yard_ghurt','~> 1.2'  # For extra YARDoc Rake tasks
  
  spec.post_install_message = <<-EOM
  
  NHKore v#{NHKore::VERSION}
  
  You can now use [#{spec.executables.join(', ')}] on the command line.
  
  Homepage:  #{spec.homepage}
  
  Code:      #{spec.metadata['source_code_uri']}
  Bugs:      #{spec.metadata['bug_tracker_uri']}
  
  Changelog: #{spec.metadata['changelog_uri']}
  
  EOM
  
  spec.extra_rdoc_files = %w[ CHANGELOG.md LICENSE.txt README.md ]
  
  spec.rdoc_options = [
    '--hyperlink-all','--show-hash',
    '--title',"NHKore v#{NHKore::VERSION} Doc",
    '--main','README.md',
  ]
end
