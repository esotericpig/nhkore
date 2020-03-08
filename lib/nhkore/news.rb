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


require 'nhkore/article'
require 'nhkore/error'
require 'nhkore/util'
require 'psychgus'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class News
    DEFAULT_DIR = Util::CORE_DIR
    
    attr_reader :articles
    attr_reader :sha256s
    
    def initialize()
      super()
      
      @articles = {}
      @sha256s = {}
    end
    
    def add_article(key,article)
      raise ArgError,"duplicate article[#{key}] in articles" if @articles.key?(key)
      raise ArgError,"duplicate sha256[#{article.sha256}] in articles" if @sha256s.key?(article.sha256)
      
      @articles[key] = article
      @sha256s[article.sha256] = article.url
      
      return self
    end
    
    def self.default_file(filename)
      return File.join(DEFAULT_DIR,filename)
    end
    
    def encode_with(coder)
      # Order matters.
      # Don't output @sha256s.
      
      coder[:articles] = @articles
    end
    
    def self.load_data(data,article_class: Article,file: nil,news_class: News,**kargs)
      data = Psych.safe_load(data,
        aliases: true,
        filename: file,
        #freeze: true, # Not in this current version of Psych
        permitted_classes: [Symbol],
        symbolize_names: true,
        **kargs
      )
      
      articles = data[:articles]
      
      news = news_class.new()
      
      if !articles.nil?()
        articles.each() do |key,hash|
          key = key.to_s() # Change from a symbol
          news.add_article(key,article_class.load_data(key,hash))
        end
      end
      
      return news
    end
    
    def self.load_file(file,mode: 'r:BOM|UTF-8',**kargs)
      data = File.read(file,mode: mode,**kargs)
      
      return load_data(data,file: file,**kargs)
    end
    
    def save_file(file,mode: 'wt',**kargs)
      File.open(file,mode: mode,**kargs) do |file|
        file.write(to_s())
      end
    end
    
    def to_s()
      return Psychgus.dump(self,
        line_width: 10000, # Try not to wrap; ichiman!
        stylers: [
          Psychgus::FlowStyler.new(8), # Put each Word on one line (flow/inline style)
          Psychgus::NoSymStyler.new(cap: false), # Remove symbols, don't capitalize
          Psychgus::NoTagStyler.new() # Remove class names (tags)
        ]
      )
    end
  end
  
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class FutsuuNews < News
    DEFAULT_FILE = default_file('nhk_news_web_regular.yml')
    
    def self.load_data(data,**kargs)
      return News.load_data(data,article_class: Article,news_class: FutsuuNews,**kargs)
    end
    
    def self.load_file(file=DEFAULT_FILE,**kargs)
      return News.load_file(file,article_class: Article,news_class: FutsuuNews,**kargs)
    end
    
    def save_file(file=DEFAULT_FILE,**kargs)
      super(file,**kargs)
    end
  end
  
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class YasashiiNews < News
    DEFAULT_FILE = default_file('nhk_news_web_easy.yml')
    
    def self.load_data(data,**kargs)
      return News.load_data(data,article_class: Article,news_class: YasashiiNews,**kargs)
    end
    
    def self.load_file(file=DEFAULT_FILE,**kargs)
      return News.load_file(file,article_class: Article,news_class: YasashiiNews,**kargs)
    end
    
    def save_file(file=DEFAULT_FILE,**kargs)
      super(file,**kargs)
    end
  end
end