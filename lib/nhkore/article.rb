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
    attr_accessor :url
    attr_accessor :words
    
    def initialize()
      super()
      
      @datetime = nil
      @futsuurl = nil
      @sha256 = nil
      @url = nil
      @words = {}
    end
    
    def encode_with(coder)
      # Ignore @url because it will be the key in the YAML/Hash.
      # Order matters.
      
      coder[:datetime] = @datetime.nil?() ? @datetime : @datetime.iso8601()
      coder[:futsuurl] = @futsuurl
      coder[:sha256] = @sha256
      coder[:words] = @words
    end
    
    def self.load_hash(key,hash)
      datetime = hash[:datetime]
      words = hash[:words]
      
      article = Article.new()
      
      article.datetime = Util.str_empty?(datetime) ? nil : Time.iso8601(datetime)
      article.futsuurl = hash[:futsuurl]
      article.sha256 = hash[:sha256]
      article.url = key
      
      if !words.nil?()
        words.each() do |key,word_hash|
          article.words[key] = Word.load_hash(key,word_hash)
        end
      end
      
      return article
    end
    
    def to_s()
      s = ''.dup()
      
      s << "#{@url}:"
      s << "\n  datetime: #{@datetime}"
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
