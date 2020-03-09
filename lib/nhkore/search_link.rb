#!/usr/bin/env ruby
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


require 'nhkore/util'
require 'psychgus'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class SearchLink
    attr_accessor :scraped
    attr_accessor :url
    
    def initialize(url,scraped: false)
      super()
      
      @scraped = scraped
      @url = url
    end
    
    def encode_with(coder)
      # Order matters.
      
      coder[:scraped] = @scraped
      coder[:url] = @url
    end
    
    def self.load_data(key,hash)
      search_link = SearchLink.new(
        hash[:url],
        scraped: hash[:scraped]
      )
      
      return search_link
    end
    
    def to_s()
      s = ''.dup()
      
      s << "'#{@url}': "
      s << "{ scraped? #{@scraped ? 'yes' : 'NO'} }"
      
      return s
    end
  end
  
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class SearchLinks
    DEFAULT_DIR = Util::CORE_DIR
    
    DEFAULT_BING_FUTSUU_FILENAME = 'bing_nhk_news_web_regular.yml'
    DEFAULT_BING_YASASHII_FILENAME = 'bing_nhk_news_web_easy.yml'
    
    def self.build_file(filename)
      return File.join(DEFAULT_DIR,filename)
    end
    
    DEFAULT_BING_FUTSUU_FILE = build_file(DEFAULT_BING_FUTSUU_FILENAME)
    DEFAULT_BING_YASASHII_FILE = build_file(DEFAULT_BING_YASASHII_FILENAME)
    
    attr_reader :links
    
    def initialize()
      super()
      
      @links = {}
    end
    
    def add_link(link)
      return self if @links.key?(link.url)
      
      @links[link.url] = link
      
      return self
    end
    
    def encode_with(coder)
      # Order matters.
      
      coder[:links] = @links
    end
    
    def self.load_data(data,file: nil,**kargs)
      data = Psych.safe_load(data,
        aliases: true,
        filename: file,
        #freeze: true, # Not in this current version of Psych
        permitted_classes: [Symbol],
        symbolize_names: true,
        **kargs
      )
      
      links = data[:links]
      
      search_links = SearchLinks.new()
      
      if !links.nil?()
        links.each() do |key,hash|
          key = key.to_s() # Change from a symbol
          search_links.links[key] = SearchLink.load_data(key,hash)
        end
      end
      
      return search_links
    end
    
    def self.load_file(file,mode: 'r:BOM|UTF-8',**kargs)
      data = File.read(file,mode: mode,**kargs)
      
      return load_data(data,file: file,**kargs)
    end
    
    def save_file(file,mode: 'wt',**kargs)
      File.open(file,mode: mode,**kargs) do |file|
        file.write(to_s())
      end
    end
    
    def to_s()
      return Psychgus.dump(self,
        line_width: 10000, # Try not to wrap; ichiman!
        stylers: [
          Psychgus::FlowStyler.new(4), # Put each SearchLink on one line (flow/inline style)
          Psychgus::NoSymStyler.new(cap: false), # Remove symbols, don't capitalize
          Psychgus::NoTagStyler.new() # Remove class names (tags)
        ]
      )
    end
  end
end
