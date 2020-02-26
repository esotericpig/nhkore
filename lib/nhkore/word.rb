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
    attr_accessor :freq
    attr_reader :kana
    attr_reader :kanji
    attr_reader :key
    
    def initialize(freq: 1,kana: nil,kanji: nil,**kargs)
      super()
      
      kana = nil if Util.empty_str?(kana)
      kanji = nil if Util.empty_str?(kanji)
      
      raise ArgumentError,'kanji and kana cannot both be empty' if kana.nil?() && kanji.nil?()
      
      @freq = freq
      @kana = kana
      @kanji = kanji
      @key = "#{kanji}=#{kana}" # nil.to_s() is ''
    end
    
    def encode_with(coder)
      # Ignore @key because it will be the key in the YAML/Hash.
      # Order matters.
      
      coder[:kanji] = @kanji
      coder[:kana] = @kana
      coder[:freq] = @freq
    end
    
    def self.load_hash(key,hash)
      key = key.to_s() # Change from a symbol
      
      word = Word.new(kana: hash[:kana],kanji: hash[:kanji])
      
      if key != word.key
        raise ArgumentError,"the key from the hash [#{key}] does not match the generated key [#{word.key}]"
      end
      
      freq = hash[:freq].to_i() # nil.to_i() is 0
      word.freq = freq if freq > 0
      
      return word
    end
    
    def to_s()
      s = ''.dup()
      
      s << "#{@key}: "
      s << "{ kanji=>#{@kanji}"
      s << ", kana=>#{@kana}"
      s << ", freq=>#{@freq}"
      s << ' }'
      
      return s
    end
  end
end
