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


require 'nokogiri'
require 'open-uri'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class Scraper
    # Copied from googler (https://github.com/jarun/googler).
    USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36'
    
    attr_accessor :str_or_io
    attr_accessor :url
    
    # Pass in +header: {}+ to set the default HTTP header fields.
    def initialize(url,file: false,header: nil,str_or_io: nil,**kargs)
      super()
      
      if !header.nil?() && !file
        # Some sites (Search Engines) hate scrapers, so need HTTP header fields.
        # If this isn't enough, look at googler for more header fields to set:
        # - https://github.com/jarun/googler
        # If necessary, can use the Faraday, HTTParty, or RestClient gem and
        #   pass in to str_or_io.
        
        header['User-Agent'] = USER_AGENT unless header.key?('User-Agent')
        
        kargs.merge!(header) # header will overwrite duplicate kargs entries
      end
      
      @url = url
      
      if str_or_io.nil?()
        if file
          # NHK's website tends to always use UTF-8
          @str_or_io = File.open(url,'rt:UTF-8',**kargs)
        else
          # Use URI.open() instead of (Kernel.)open() for safety (code-injection attack).
          # Disable redirect for safety (infinite-loop attack).
          # - All options: https://ruby-doc.org/stdlib-2.7.0/libdoc/open-uri/rdoc/OpenURI/OpenRead.html
          @str_or_io = URI.open(url,redirect: false,**kargs)
        end
      else
        @str_or_io = str_or_io
      end
    end
    
    def html_doc()
      return Nokogiri::HTML(@str_or_io)
    end
  end
end
