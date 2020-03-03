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


require 'psychgus'
require 'nhkore/article'
require 'nhkore/util'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class NHKNewsWebEasy
    DEFAULT_FILE = 'nhk_news_web_easy.yml'
    
    attr_reader :articles
    
    def initialize()
      super()
      
      @articles = {}
    end
    
    def encode_with(coder)
      coder[:articles] = @articles
    end
    
    def self.load_data(data,file: nil,**kargs)
      data = Psych.safe_load(data,
        aliases: true,
        filename: file,
        #freeze: true, # Not in this current version of Psych
        permitted_classes: [Symbol],
        symbolize_names: true,
        **kargs
      )
      
      articles = data[:articles]
      
      nhk_news_ez = NHKNewsWebEasy.new()
      
      if !articles.nil?()
        articles.each() do |key,hash|
          key = key.to_s() # Change from a symbol
          nhk_news.articles[key] = Article.load_hash(key,hash)
        end
      end
      
      return nhk_news_ez
    end
    
    def self.load_file(file=File.join(Util::CORE_DIR,DEFAULT_FILE),mode: 'r:BOM|UTF-8',**kargs)
      data = File.read(file,mode: mode,**kargs)
      
      return load_data(data,file: file,**kargs)
    end
    
    def save_file(file=File.join(Util::CORE_DIR,DEFAULT_FILE),mode: 'wt',**kargs)
      File.open(file,mode: mode,**kargs) do |file|
        file.write(to_s())
      end
    end
    
    def to_s()
      return Psychgus.dump(self,stylers: [
        Psychgus::FlowStyler.new(8), # Put each Word on one line (flow/inline style)
        Psychgus::NoSymStyler.new(cap: false), # Remove symbols, don't capitalize
        Psychgus::NoTagStyler.new() # Remove class names (tags)
      ])
    end
  end
end
