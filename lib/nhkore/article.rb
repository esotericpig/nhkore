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
    
    def add_word(word)
      curr_word = words[word.key]
      
      if curr_word.nil?()
        words[word.key] = word
        curr_word = word
      else
        curr_word.freq += 1
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
    
    def self.load_hash(key,hash)
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
          article.words[k] = Word.load_hash(k,h)
        end
      end
      
      return article
    end
    
    def to_s()
      s = ''.dup()
      
      s << "#{@url}:"
      s << "\n  datetime: #{@datetime}"
      s << "\n  title:    #{@title}"
      s << "\n  futsuurl: #{@futsuurl}"
      s << "\n  sha256:   #{@sha256}"
      
      s << "\n  words:"
      @words.each() do |key,word|
        s << "\n    #{word}"
      end
      
      return s
    end
  end
end
