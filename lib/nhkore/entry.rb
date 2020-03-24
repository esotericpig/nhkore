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
require 'nhkore/util'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class Entry
    HYOUKI_SEP = '・'
    
    attr_reader :defns
    attr_accessor :id
    
    def initialize()
      super()
      
      @defns = []
      @id = nil
    end
    
    def build_defn()
      defns = []
      i = 0
      
      @defns.each() do |defn|
        defns << "#{i += 1}）#{defn}" # Japanese parenthesis
      end
      
      return defns.join("\n")
    end
    
    def build_hyouki()
      # Since Ruby v1.9, Hash preserves order.
      # Ruby v2.7 doc for Set still says no guarantee of order, so don't use.
      hyoukis = {}
      
      @defns.each() do |defn|
        defn.hyoukis.each() do |hyouki|
          hyouki = hyouki.sub(/#{Regexp.quote(HYOUKI_SEP)}\z/,'')
          
          next if hyouki.empty?()
          
          hyoukis[hyouki] = true
        end
      end
      
      return hyoukis.keys.join(HYOUKI_SEP)
    end
    
    def self.scrape(id,array,url: nil)
      entry = Entry.new()
      
      entry.id = Util.unspace_web_str(id.to_s()).downcase()
      
      return nil if entry.id.empty?()
      
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
      
      hyouki = build_hyouki()
      
      s << "#{hyouki}\n" unless Util.empty_web_str?(hyouki)
      s << build_defn()
      
      return s
    end
  end
end
