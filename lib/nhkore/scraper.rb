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
    attr_accessor :str_or_io
    attr_accessor :url
    
    def initialize(url,file: false,str_or_io: nil,**kargs)
      super()
      
      @url = url
      
      if str_or_io.nil?()
        if file
          # NHK's website tends to always use UTF-8
          @str_or_io = File.open(url,'rt:UTF-8')
        else
          # Use URI.open() instead of (Kernel.)open() for safety (code-injection attack).
          # Disable redirect for safety (infinite-loop attack).
          # - All options: https://ruby-doc.org/stdlib-2.7.0/libdoc/open-uri/rdoc/OpenURI/OpenRead.html
          @str_or_io = URI.open(url,redirect: false)
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
