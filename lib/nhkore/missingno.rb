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
  # @since  0.2.0
  ###
  class Missingno
    attr_reader :kanas
    attr_reader :kanjis
    
    # @param data [News,Article,Array<Word>]
    def initialize(data)
      super()
      
      @kanas = {}
      @kanjis = {}
      
      # News?
      if data.respond_to?(:articles)
        add_news(data)
      # Article?
      elsif data.respond_to?(:words)
        add_article(data)
      else
        add_words(data)
      end
    end
    
    def add_article(article)
      add_words(article.words.values())
    end
    
    def add_news(news)
      news.articles.values.each() do |article|
        add_article(article)
      end
    end
    
    def add_words(words)
      words.each() do |word|
        # We only want ones that are both filled in because
        #   Word.scrape_ruby_tag() will raise an error if either is empty.
        next if Util.empty_web_str?(word.kana) || Util.empty_web_str?(word.kanji)
        
        if !kanas.key?(word.kana)
          kanas[word.kana] = word
        end
        
        if !kanjis.key?(word.kanji)
          kanjis[word.kanji] = word
        end
      end
    end
    
    def kana_from_kanji(kanji)
      word = @kanjis[kanji]
      
      return word.nil?() ? nil : word.kana
    end
    
    def kanji_from_kana(kana)
      word = @kanas[kana]
      
      return word.nil?() ? nil : word.kanji
    end
  end
end
