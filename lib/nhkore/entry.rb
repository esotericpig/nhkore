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


require 'nhkore/defn'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class Entry
    attr_reader :defns
    attr_accessor :id
    
    def initialize()
      super()
      
      @defns = []
      @id = nil
    end
    
    def self.scrape(id,array,url: nil)
      entry = Entry.new()
      
      entry.id = id
      
      array.each() do |hash|
        defn = Defn.scrape(hash,url: url)
        entry.defns << defn unless defn.nil?()
      end
      
      return nil if entry.defns.empty?()
      return entry
    end
    
    def to_s()
      s = ''.dup()
      
      return s if @defns.empty?()
      
      # TODO: if can have 2 hyoukis, change this according to NHK format
      
      # Hyouki must be at top.
      @defns.each() do |defn|
        if !defn.hyoukis.empty?()
          s << "#{defn.hyoukis[0]}\n"
          break
        end
      end
      
      i = 1
      
      @defns.each() do |defn|
        s << "#{i}) #{defn}\n"
        i += 1
      end
      
      return s
    end
  end
end
