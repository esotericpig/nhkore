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
require 'open-uri'
require 'nhkore/article'
require 'nhkore/error'
require 'nhkore/util'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class ArticleScraper
    attr_accessor :str_or_io
    attr_accessor :url
    attr_accessor :year
    
    def initialize(url,file: false,str_or_io: nil,year: nil)
      super()
      
      @url = url
      @year = year
      
      if str_or_io.nil?()
        if file
          # NHK's website tends to always use UTF-8
          @str_or_io = File.open(url,'rt:UTF-8')
        else
          # Use URI.open() instead of (Kernel.)open() for safety (code-injection attack).
          # Disable redirect for safety (infinite-loop attack).
          # - All options: https://ruby-doc.org/stdlib-2.7.0/libdoc/open-uri/rdoc/OpenURI/OpenRead.html
          @str_or_io = URI.open(url,redirect: false)
        end
      else
        @str_or_io = str_or_io
      end
    end
    
    def parse_datetime(str,year)
      str = str.gsub(/[\[\][[:space:]]]+/,'')
      str = "#{year}年 #{str} #{Util::JST_OFFSET}"
      
      return Time.strptime(str,'%Y年 %m月%d日%H時%M分 %:z')
    end
    
    def scrape_datetime(doc,futsuurl=nil)
      year = scrape_year(doc,futsuurl)
      
      # First, try with the id
      p = doc.css('p#js-article-date')
      
      if p.length > 0
        p = p[0]
        
        begin
          datetime = parse_datetime(p.text,year)
          
          return datetime
        rescue ArgumentError => e
          e # TODO: log.warn()?
        end
      end
      
      # Second, try with the class
      p = doc.css('p.article-main__date')
      
      if p.length > 0
        p = p[0]
        datetime = parse_datetime(p.text,year) # Allow the error to raise
        
        return datetime
      end
      
      raise ScrapeError,"could not scrape date time for url[#{@url}]"
    end
    
    def scrape_futsuurl(doc)
      # First, try with the id
      div = doc.css('div#js-regular-news-wrapper')
      
      if div.length > 0
        div = div[0]
        link = scrape_link(div)
        
        return link unless link.nil?()
      end
      
      # Second, try with the class
      div = doc.css('div.link-to-normal')
      
      if div.length > 0
        div = div[0]
        link = scrape_link(div)
        
        return link unless link.nil?()
      end
      
      raise ScrapeError,"could not scrape futsuurl for url[#{@url}]"
    end
    
    def scrape_link(tag)
      link = tag.css('a')
      
      return nil if link.length < 1
      
      link = Util.unspace_str(link[0]['href'].to_s())
      
      return nil if link.empty?()
      return link
    end
    
    def scrape_nhk_news_web_easy()
      article = Article.new()
      doc = Nokogiri::HTML(@str_or_io)
      
      article.futsuurl = scrape_futsuurl(doc)
      article.datetime = scrape_datetime(doc,article.futsuurl)
      
      # TODO: finish scraping article
      puts article
    end
    
    def scrape_year(doc,futsuurl=nil)
      # First, try body's id
      body = doc.css('body')
      
      if body.length > 0
        body = body[0]
        body_id = body['id'].to_s().gsub(/[^[[:digit:]]]+/,'')
        
        if body_id.length >= 4
          body_id = body_id[0..3].to_i()
          
          return body_id if Util.sane_year?(body_id)
        end
      end
      
      # Second, try futsuurl
      if !futsuurl.nil?()
        m = futsuurl.match(/([[:digit:]]{4,})/)
        
        if !m.nil?() && (m = m[0].to_s()).length >= 4
          m = m[0..3].to_i()
          
          return m if Util.sane_year?(m)
        end
      end
      
      # Lastly, use our user-defined fallback
      raise ScrapeError,"could not scrape year for url[#{@url}]" if Util.empty_str?(@year)
      
      return @year
    end
  end
end
