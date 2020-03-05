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


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.1.0
  ###
  class Word
    attr_accessor :definition
    attr_accessor :english
    attr_accessor :frequency
    attr_reader :kana
    attr_reader :kanji
    attr_reader :key
    
    def initialize(definition: nil,english: nil,frequency: 1,kana: nil,kanji: nil,**kargs)
      super()
      
      kana = nil if Util.empty_web_str?(kana)
      kanji = nil if Util.empty_web_str?(kanji)
      
      raise ArgumentError,'kanji and kana cannot both be empty' if kana.nil?() && kanji.nil?()
      
      @definition = definition
      @english = english
      @frequency = frequency
      @kana = kana
      @kanji = kanji
      @key = "#{kanji}=#{kana}" # nil.to_s() is ''
    end
    
    def encode_with(coder)
      # Ignore @key because it will be the key in the YAML/Hash.
      # Order matters.
      
      coder[:kanji] = @kanji
      coder[:kana] = @kana
      coder[:frequency] = @frequency
      coder[:definition] = @definition
      coder[:english] = @english
    end
    
    def self.load_hash(key,hash)
      key = key.to_s() # Change from a symbol
      
      word = Word.new(
        definition: hash[:definition],
        english: hash[:english],
        kana: hash[:kana],
        kanji: hash[:kanji]
      )
      
      if key != word.key
        raise ArgumentError,"the key from the hash [#{key}] does not match the generated key [#{word.key}]"
      end
      
      frequency = hash[:frequency].to_i() # nil.to_i() is 0
      word.frequency = frequency if frequency > 0
      
      return word
    end
    
    def kanji?()
      return !Util.empty_web_str?(@kanji)
    end
    
    def word()
      return kanji?() ? @kanji : @kana
    end
    
    def to_s()
      s = ''.dup()
      
      s << "#{@key}: "
      s << "{ kanji=>#{@kanji}"
      s << ", kana=>#{@kana}"
      s << ", frequency=>#{@frequency}"
      s << ", definition=>#{@definition}"
      s << ", english=>#{@english}"
      s << ' }'
      
      return s
    end
  end
end
