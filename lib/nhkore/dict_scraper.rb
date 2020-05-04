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


require 'nhkore/dict'
require 'nhkore/error'
require 'nhkore/scraper'
require 'nhkore/util'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class DictScraper < Scraper
    attr_accessor :missingno
    
    def initialize(url,missingno: nil,parse_url: true,**kargs)
      url = self.class.parse_url(url) if parse_url
      
      super(url,**kargs)
      
      @missingno = missingno
    end
    
    def self.parse_url(url,basename: nil)
      url = Util.strip_web_str(url.to_s())
      
      raise ParseError,"cannot parse dictionary URL from URL[#{url}]" if url.empty?()
      
      i = url.rindex(%r{[/\\]}) # Can be a URL or a file
      i = i.nil?() ? 0 : (i + 1) # If no match found, no path
      
      basename = File.basename(url[i..-1],'.*') if basename.nil?()
      path = url[0...i]
      
      return "#{path}#{basename}.out.dic"
    end
    
    def scrape()
      require 'json'
      
      json = JSON.load(@str_or_io)
      
      return Dict.new() if json.nil?()
      
      hash = json['reikai']
      
      return Dict.new() if hash.nil?()
      
      hash = hash['entries']
      
      return Dict.new() if hash.nil?()
      return Dict.scrape(hash,missingno: @missingno,url: @url)
    end
  end
end
