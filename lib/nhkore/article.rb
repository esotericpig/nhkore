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


require 'time'

require 'nhkore/util'
require 'nhkore/word'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class Article
    attr_accessor :datetime
    attr_accessor :futsuurl
    attr_accessor :sha256
    attr_accessor :title
    attr_accessor :url
    attr_reader :words
    
    def initialize()
      super()
      
      @datetime = nil
      @futsuurl = nil
      @sha256 = nil
      @title = nil
      @url = nil
      @words = {}
    end
    
    # Why does this not look up the kanji/kana only and then update the other
    # kana/kanji part appropriately?
    # - There are some words like +行って+. Without the kana, it's difficult to
    #   determine what kana it should be. Should it be +いって+ or +おこなって+?
    # - Similarly, if we just have +いって+, should this be +行って+ or +言って+?
    # - Therefore, if we only have the kanji or only have the kana, we don't
    #   try to populate the other value.
    def add_word(word,use_freq: false)
      curr_word = words[word.key]
      
      if curr_word.nil?()
        words[word.key] = word
        curr_word = word
      else
        curr_word.freq += (use_freq ? word.freq : 1)
        
        curr_word.defn = word.defn if word.defn.to_s().length > curr_word.defn.to_s().length
        curr_word.eng = word.eng if word.eng.to_s().length > curr_word.eng.to_s().length
      end
      
      return curr_word
    end
    
    def encode_with(coder)
      # Order matters.
      
      coder[:datetime] = @datetime.nil?() ? @datetime : @datetime.iso8601()
      coder[:title] = @title
      coder[:url] = @url
      coder[:futsuurl] = @futsuurl
      coder[:sha256] = @sha256
      coder[:words] = @words
    end
    
    def self.load_data(key,hash)
      datetime = hash[:datetime]
      words = hash[:words]
      
      article = Article.new()
      
      article.datetime = Util.empty_web_str?(datetime) ? nil : Time.iso8601(datetime)
      article.futsuurl = hash[:futsuurl]
      article.sha256 = hash[:sha256]
      article.title = hash[:title]
      article.url = hash[:url]
      
      if !words.nil?()
        words.each() do |k,h|
          k = k.to_s() # Change from a symbol
          article.words[k] = Word.load_data(k,h)
        end
      end
      
      return article
    end
    
    def to_s(mini: false)
      s = ''.dup()
      
      s << "'#{@url}':"
      s << "\n  datetime: '#{@datetime}'"
      s << "\n  title:    '#{@title}'"
      s << "\n  url:      '#{@url}'"
      s << "\n  futsuurl: '#{@futsuurl}'"
      s << "\n  sha256:   '#{@sha256}'"
      
      if !mini
        s << "\n  words:"
        @words.each() do |key,word|
          s << "\n    #{word}"
        end
      end
      
      return s
    end
  end
end
