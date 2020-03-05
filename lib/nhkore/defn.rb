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
require 'nhkore/word'
require 'nokogiri'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class Defn
    attr_reader :hyoukis
    attr_accessor :text
    attr_reader :words
    
    def initialize()
      super()
      
      @hyoukis = []
      @text = ''.dup()
      @words = []
    end
    
    # If no data, don't raise errors; don't care if have a definition or not.
    def self.scrape(hash,url: nil)
      defn = Defn.new()
      
      hyoukis = hash['hyouki']
      
      if !hyoukis.nil?()
        hyoukis.each() do |hyouki|
          next if hyouki.nil?()
          next if (hyouki = Util.strip_web_str(hyouki)).empty?()
          
          defn.hyoukis << hyouki
        end
      end
      
      # TODO: remove after testing & finding out answer
      raise "What do 2+ Hyouki look like? #{url}" if defn.hyoukis.length > 1
      
      def_str = hash['def']
      
      if Util.empty_web_str?(def_str)
        if defn.hyoukis.empty?()
          return nil
        else
          return defn
        end
      end
      
      doc = Nokogiri::HTML(def_str)
      doc = doc.css('body') # Auto-added by Nokogiri
      
      doc.children.each() do |child|
        name = Util.unspace_web_str(child.name).downcase() if child.respond_to?(:name)
        word = nil
        
        if name == 'ruby'
          word = Word.scrape_ruby_tag(child,url: url)
        else
          word = Word.scrape_text_node(child,url: url)
        end
        
        if !word.nil?()
          defn.text << word.word
          defn.words << word unless Util.empty_web_str?(word.word)
        end
      end
      
      return nil if defn.hyoukis.empty?() && defn.words.empty?()
      
      defn.text = Util.strip_web_str(defn.text)
      
      return defn
    end
    
    def to_s()
      return @text
    end
  end
end
