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

require 'nhkore/error'
require 'nhkore/util'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.1.0
  ###
  class Word
    attr_accessor :defn
    attr_accessor :eng
    attr_accessor :freq
    attr_reader :kana
    attr_reader :kanji
    attr_reader :key
    
    def initialize(defn: nil,eng: nil,freq: 1,kana: nil,kanji: nil,unknown: nil,word: nil,**kargs)
      super()
      
      if !word.nil?()
        defn = word.defn if defn.nil?()
        eng = word.eng if eng.nil?()
        freq = word.freq if freq.nil?()
        kana = word.kana if kana.nil?()
        kanji = word.kanji if kanji.nil?()
      end
      
      raise ArgumentError,"freq[#{freq}] cannot be < 1" if freq < 1
      
      if !unknown.nil?()
        if Util.kanji?(unknown)
          raise ArgumentError,"unknown[#{unknown}] will overwrite kanji[#{kanji}]" unless Util.empty_web_str?(kanji)
          
          kanji = unknown
        else
          raise ArgumentError,"unknown[#{unknown}] will overwrite kana[#{kana}]" unless Util.empty_web_str?(kana)
          
          kana = unknown
        end
      end
      
      kana = nil if Util.empty_web_str?(kana)
      kanji = nil if Util.empty_web_str?(kanji)
      
      raise ArgumentError,'kanji and kana cannot both be empty' if kana.nil?() && kanji.nil?()
      
      @defn = defn
      @eng = eng
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
      coder[:defn] = @defn
      coder[:eng] = @eng
    end
    
    def self.load_data(key,hash)
      key = key.to_s() # Change from a symbol
      
      word = Word.new(
        defn: hash[:defn],
        eng: hash[:eng],
        kana: hash[:kana],
        kanji: hash[:kanji]
      )
      
      if key != word.key
        raise ArgumentError,"the key from the hash[#{key}] does not match the generated key[#{word.key}]"
      end
      
      freq = hash[:freq].to_i() # nil.to_i() is 0
      word.freq = freq if freq > 0
      
      return word
    end
    
    # Do not clean and/or strip spaces, as the raw text is important for
    #   Defn and ArticleScraper.
    def self.scrape_ruby_tag(tag,url: nil)
      # First, try <rb> tags.
      kanji = tag.css('rb')
      # Second, try text nodes.
      kanji = tag.search('./text()') if kanji.length < 1
      # Third, try non-<rt> tags, in case of being surrounded by <span>, <b>, etc.
      kanji = tag.search("./*[not(name()='rt')]") if kanji.length < 1
      
      raise ScrapeError,"no kanji at URL[#{url}] in tag[#{tag}]" if kanji.length < 1
      raise ScrapeError,"too many kanji at URL[#{url}] in tag[#{tag}]" if kanji.length > 1
      
      kanji = kanji[0].text
      
      raise ScrapeError,"empty kanji at URL[#{url}] in tag[#{tag}]" if kanji.empty?()
      
      kana = tag.css('rt')
      
      raise ScrapeError,"no kana at URL[#{url}] in tag[#{tag}]" if kana.length < 1
      raise ScrapeError,"too many kana at URL[#{url}] in tag[#{tag}]" if kana.length > 1
      
      kana = kana[0].text
      
      raise ScrapeError,"empty kana at URL[#{url}] in tag[#{tag}]" if kana.empty?()
      
      word = Word.new(kana: kana,kanji: kanji)
      
      return word
    end
    
    # Do not clean and/or strip spaces, as the raw text is important for
    #   Defn and ArticleScraper.
    def self.scrape_text_node(tag,url: nil)
      text = tag.text
      
      # No error; empty text is fine (not strictly kanji/kana only)
      return nil if Util.empty_web_str?(text)
      
      word = Word.new(kana: text) # Assume kana
      
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
      
      s << "'#{@key}': "
      s << "{ kanji=>'#{@kanji}'"
      s << ", kana=>'#{@kana}'"
      s << ", freq=>'#{@freq}'"
      s << ", defn=>'#{@defn.to_s().gsub("\n",'\\n')}'"
      s << ", eng=>'#{@eng}'"
      s << ' }'
      
      return s
    end
  end
end
