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


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.1.0
  ###
  class Word
    attr_accessor :freq
    attr_reader :kana
    attr_reader :word
    
    def initialize(word=nil,freq: 1,kana: nil,**kargs)
      super()
      
      @freq = freq
      @kana = kana
      @word = word.nil?() ? kana : word
      
      raise ArgumentError,'word and kana cannot both be nil; one must be specified' if @word.nil?()
    end
    
    def encode_with(coder)
      # Ignore @word because it will be the key in the YAML/Hash.
      # Order matters.
      coder[:kana] = @kana
      coder[:freq] = @freq
    end
    
    def self.load_hash(key,hash)
      word = Word.new(key,kana: hash[:kana])
      
      freq = hash[:freq].to_i() # nil is okay
      word.freq = freq if freq >= 0
      
      return word
    end
    
    def kanji?()
      return @word != @kana
    end
    
    def no_kanji?()
      return !kanji?()
    end
    
    def to_s()
      s = ''.dup()
      
      s << @word
      s << " | kana: #{@kana}"
      s << " | freq: #{@freq}"
      s << " | kanji? #{kanji?() ? 'yes' : 'no'}"
      
      return s
    end
  end
end
