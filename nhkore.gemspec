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
  spec.description = <<-EOD.gsub(/\s{2,}/,' ').strip()
    Scrapes NHK News Web (Easy) for the word frequency (core list) for Japanese language learners.
    Includes a CLI app and a scraper library.
  EOD
  
  spec.metadata = {
    'bug_tracker_uri' => 'https://github.com/esotericpig/nhkore/issues',
    'changelog_uri'   => 'https://github.com/esotericpig/nhkore/blob/master/CHANGELOG.md',
    'homepage_uri'    => 'https://github.com/esotericpig/nhkore',
    'source_code_uri' => 'https://github.com/esotericpig/nhkore'
  }
  
  spec.require_paths = ['lib']
  spec.bindir        = 'bin'
  spec.executables   = [spec.name]
  
  spec.files = Dir.glob(File.join("{#{spec.require_paths.join(',')}}",'**','*.{erb,rb}')) +
               Dir.glob(File.join(spec.bindir,'*')) +
               Dir.glob(File.join('{test,yard}','**','*.{erb,rb}')) +
               %W( Gemfile #{spec.name}.gemspec Rakefile ) +
               %w( CHANGELOG.md LICENSE.txt README.md )
  
  spec.required_ruby_version = '>= 2.4'
  
  spec.requirements << 'Nokogiri: https://www.nokogiri.org/tutorials/installing_nokogiri.html'
  
  spec.add_runtime_dependency 'bimyou_segmenter'    ,'~> 1.2'  # For splitting Japanese sentences into words
  spec.add_runtime_dependency 'commander'           ,'~> 4.5'  # For CLI
  spec.add_runtime_dependency 'japanese_deinflector','~> 0.0'  # For unconjugating Japanese words (plain/dictionary form)
  spec.add_runtime_dependency 'nokogiri'            ,'~> 1.10' # For scraping/hacking
  spec.add_runtime_dependency 'psychgus'            ,'~> 1.2'  # For styling Psych YAML
  spec.add_runtime_dependency 'tiny_segmenter'      ,'~> 0.0'  # For splitting Japanese sentences into words
  
  spec.add_development_dependency 'bundler'   ,'~> 2.1'
  spec.add_development_dependency 'minitest'  ,'~> 5.14'
  spec.add_development_dependency 'rake'      ,'~> 13.0'
  spec.add_development_dependency 'raketeer'  ,'~> 0.2'  # For extra Rake tasks
  spec.add_development_dependency 'yard'      ,'~> 0.9'  # For documentation
  spec.add_development_dependency 'yard_ghurt','~> 1.1'  # For extra YARDoc Rake tasks
  
  spec.post_install_message = "You can now use [#{spec.executables.join(', ')}] on the command line."
end
