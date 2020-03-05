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


require 'nhkore/entry'
require 'nhkore/error'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class Dict
    attr_reader :entries
    
    def initialize()
      super()
      
      @entries = {}
    end
    
    def [](id)
      return @entries[id]
    end
    
    def []=(id,entry)
      return @entries[id] = entry
    end
    
    def self.scrape(hash,url: nil)
      dict = Dict.new()
      
      hash.each() do |id,array|
        entry = Entry.scrape(id,array,url: url)
        
        next if entry.nil?()
        raise ScrapeError,"duplicate ID[#{id}] at URL[#{url}] in hash[#{hash}]" if dict.key?(id)
        
        dict[id] = entry
      end
      
      return dict
    end
    
    def key?(id)
      return @entries.key?(id)
    end
    
    def to_s()
      s = ''.dup()
      
      @entries.each() do |id,entry|
        s << "#{id}:\n"
        s << "  #{entry.to_s().gsub("\n","\n  ").rstrip()}\n"
      end
      
      return s
    end
  end
end
