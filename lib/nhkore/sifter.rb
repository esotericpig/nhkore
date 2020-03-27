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

require 'nhkore/fileable'
require 'nhkore/util'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class Sifter
    include Fileable
    
    DEFAULT_DIR = Util::CORE_DIR
    
    DEFAULT_FUTSUU_FILENAME = 'sift_nhk_news_web_regular'
    DEFAULT_YASASHII_FILENAME = 'sift_nhk_news_web_easy'
    
    def self.build_file(filename)
      return File.join(DEFAULT_DIR,filename)
    end
    
    DEFAULT_FUTSUU_FILE = build_file(DEFAULT_FUTSUU_FILENAME)
    DEFAULT_YASASHII_FILE = build_file(DEFAULT_YASASHII_FILENAME)
    
    attr_accessor :articles
    attr_accessor :caption
    attr_accessor :filters
    attr_accessor :ignores
    attr_accessor :output
    
    def initialize(news)
      @articles = news.articles.values.dup()
      @caption = nil
      @filters = {}
      @ignores = {}
      @output = nil
    end
    
    def filter?(article)
      return false if @filters.empty?()
      
      datetime_filter = @filters[:datetime]
      title_filter = @filters[:title]
      url_filter = @filters[:url]
      
      if !datetime_filter.nil?()
        datetime = article.datetime
        
        return true if datetime.nil?() ||
          datetime < datetime_filter[:from] || datetime > datetime_filter[:to]
      end
      
      if !title_filter.nil?()
        title = article.title.to_s()
        title = Util.unspace_web_str(title) if title_filter[:unspace]
        title = title.downcase() if title_filter[:uncase]
        
        return true unless title.include?(title_filter[:filter])
      end
      
      if !url_filter.nil?()
        url = article.url.to_s()
        url = Util.unspace_web_str(url) if url_filter[:unspace]
        url = url.downcase() if url_filter[:uncase]
        
        return true unless url.include?(url_filter[:filter])
      end
      
      return false
    end
    
    def filter_by_datetime(datetime_filter=nil,from_filter: nil,to_filter: nil)
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
      
      @filters[:datetime] = {from: from_filter,to: to_filter}
      
      return self
    end
    
    def filter_by_title(title_filter,uncase: true,unspace: true)
      title_filter = Util.unspace_web_str(title_filter) if unspace
      title_filter = title_filter.downcase() if uncase
      
      @filters[:title] = {filter: title_filter,uncase: uncase,unspace: unspace}
      
      return self
    end
    
    def filter_by_url(url_filter,uncase: true,unspace: true)
      url_filter = Util.unspace_web_str(url_filter) if unspace
      url_filter = url_filter.downcase() if uncase
      
      @filters[:url] = {filter: url_filter,uncase: uncase,unspace: unspace}
      
      return self
    end
    
    def ignore(key)
      @ignores[key] = true
      
      return self
    end
    
    # This does not output {caption}.
    def put_csv!()
      words = sift()
      
      @output = CSV.generate(headers: :first_row,write_headers: true) do |csv|
        row = ['Frequency','Word','Kana','English']
        row << 'Definition' unless @ignores[:defn]
        csv << row
        
        words.each() do |word|
          row = [word.freq,word.word,word.kana,word.eng]
          row << word.defn unless @ignores[:defn]
          csv << row
        end
      end
      
      return @output
    end
    
    def put_html!()
      words = sift()
      
      @output = ''.dup()
      
      @output << <<~EOH
        <!DOCTYPE html>
        <html lang="ja">
        <head>
          <meta charset="utf-8">
          <title>NHKore</title>
          <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Noto+Serif+JP&amp;display=fallback">
          <style>
            body {
              background-color: #FCFBF9;
              color: #333333;
              font-family: 'Noto Serif JP',Verdana,sans-serif;
            }
            h1 {
              color: #737373;
            }
            table {
              border-collapse: collapse;
              width: 100%;
            }
            td,th {
              border: 1px solid #333333;
              padding: 8px;
              text-align: left;
            }
            th {
              background-color: #082A8E;
              color: #FCFBF9;
            }
            tr:nth-child(even) {
              background-color: #A5C7ED;
            }
            tr:hover {
              background-color: #FFDDCA;
            }
          </style>
        </head>
        <body>
          <h1>NHKore</h1>
          <h2>#{@caption}</h2>
          
          <table>
      EOH
      #" # Fix for editor
      
      @output << '    <tr><th>Frequency</th><th>Word</th><th>Kana</th><th>English</th>'
      @output << '<th>Definition</th>' unless @ignores[:defn]
      @output << "</tr>\n"
      
      words.each() do |word|
        @output << '    <tr>'
        @output << "<td>#{Util.escape_html(word.freq.to_s())}</td>"
        @output << "<td>#{Util.escape_html(word.word.to_s())}</td>"
        @output << "<td>#{Util.escape_html(word.kana.to_s())}</td>"
        @output << "<td>#{Util.escape_html(word.eng.to_s())}</td>"
        @output << "<td>#{Util.escape_html(word.defn.to_s())}</td>" unless @ignores[:defn]
        @output << "</tr>\n"
      end
      
      @output << <<~EOH
          </table>
        </body>
        </html>
      EOH
      #/ # Fix for editor
      
      return @output
    end
    
    def put_yaml!()
      words = sift()
      
      # Just blank out ignores.
      if !@ignores.empty?()
        words.each() do |word|
          word.defn = nil if @ignores[:defn]
        end
      end
      
      yaml = {
        caption: @caption,
        words: words
      }
      
      # Put each Word on one line (flow/inline style).
      @output = Util.dump_yaml(yaml,flow_level: 4)
      
      return @output
    end
    
    def sift()
      words = {}
      
      @articles.each() do |article|
        next if filter?(article)
        
        article.words.values().each() do |word|
          sift_word = words[word.key]
          
          if sift_word.nil?()
            words[word.key] = word
          else
            sift_word.freq += word.freq
          end
        end
      end
      
      words = words.values().sort() do |word1,word2|
        # Descending order.
        word2.freq <=> word1.freq
      end
      
      return words
    end
    
    def to_s()
      return @output.to_s()
    end
  end
end
