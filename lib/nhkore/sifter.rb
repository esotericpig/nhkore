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


require 'csv'

require 'nhkore/util'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class Sifter
    DEFAULT_DIR = Util::CORE_DIR
    
    DEFAULT_FUTSUU_FILENAME = 'nhk_news_web_regular.csv'
    DEFAULT_YASASHII_FILENAME = 'nhk_news_web_easy.csv'
    
    def self.build_file(filename)
      return File.join(DEFAULT_DIR,filename)
    end
    
    DEFAULT_FUTSUU_FILE = build_file(DEFAULT_FUTSUU_FILENAME)
    DEFAULT_YASASHII_FILE = build_file(DEFAULT_YASASHII_FILENAME)
    
    attr_accessor :articles
    
    def initialize(news)
      @articles = news.articles.values.dup()
    end
    
    def filter_by_datetime!(datetime_filter=nil,from_filter: nil,to_filter: nil)
      if !datetime_filter.nil?()
        # If out-of-bounds, just nil.
        from_filter = datetime_filter[0]
        to_filter = datetime_filter[1]
      end
      
      from_filter = to_filter if from_filter.nil?()
      to_filter = from_filter if to_filter.nil?()
      
      from_filter = Util.jst_time(from_filter) unless from_filter.nil?()
      to_filter = Util.jst_time(to_filter) unless to_filter.nil?()
      
      datetime_filter = [from_filter,to_filter]
      
      return self if datetime_filter.flatten().compact().empty?()
      
      @articles.filter!() do |article|
        datetime = article.datetime
        
        !datetime.nil?() && datetime >= from_filter && datetime <= to_filter
      end
      
      return self
    end
    
    def filter_by_title!(title_filter,uncase: true,unspace: true)
      title_filter = Util.unspace_web_str(title_filter) if unspace
      title_filter = title_filter.downcase() if uncase
      
      @articles.filter!() do |article|
        title = article.title.to_s()
        
        title = Util.unspace_web_str(title) if unspace
        title = title.downcase() if uncase
        
        title.include?(title_filter)
      end
      
      return self
    end
    
    def filter_by_url!(url_filter,uncase: true,unspace: true)
      url_filter = Util.unspace_web_str(url_filter) if unspace
      url_filter = url_filter.downcase() if uncase
      
      @articles.filter!() do |article|
        url = article.url.to_s()
        
        url = Util.unspace_web_str(url) if unspace
        url = url.downcase() if uncase
        
        url.include?(url_filter)
      end
      
      return self
    end
    
    def save_file(file,mode: 'wt',**kargs)
      File.open(file,mode: mode,**kargs) do |fout|
        fout.write(to_s(**kargs))
      end
    end
    
    def sift()
      words = {}
      
      @articles.each() do |article|
        article.words.values().each() do |word|
          curr_word = words[word.key]
          
          if curr_word.nil?()
            words[word.key] = word
          else
            curr_word.freq += word.freq
          end
        end
      end
      
      words = words.values().sort() do |word1,word2|
        # Descending order.
        word2.freq <=> word1.freq
      end
      
      return words
    end
    
    def to_s(defn: true,**kargs)
      words = sift()
      
      csv = CSV.generate(headers: :first_row,write_headers: true) do |csv|
        row = ['Frequency','Word','Kana','English']
        row << 'Definition' if defn
        csv << row
        
        words.each() do |word|
          row = [word.freq,word.word,word.kana,word.eng]
          row << word.defn if defn
          csv << row
        end
      end
      
      return csv
    end
  end
end
