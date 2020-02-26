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


require 'digest'
require 'nokogiri'
require 'open-uri'
require 'nhkore/article'
require 'nhkore/cleaner'
require 'nhkore/error'
require 'nhkore/splitter'
require 'nhkore/util'
require 'nhkore/word'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class ArticleScraper
    attr_accessor :cleaner
    attr_accessor :splitter
    attr_accessor :str_or_io
    attr_accessor :url
    attr_accessor :year
    
    def initialize(url,cleaner: EmptyCleaner.new(),file: false,splitter: BestSplitter.new(),str_or_io: nil,year: nil)
      super()
      
      @cleaner = cleaner
      @splitter = splitter
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
    
    def scrape_content(doc,article)
      div = doc.css('div#js-article-body')
      div = doc.css('div.article-main__body') if div.length < 1
      div = doc.css('div.article-body') if div.length < 1
      
      if div.length > 0
        text = Util.unspace_web_str(div.text.to_s())
        
        if !text.empty?()
          hexdigest = Digest::SHA256.hexdigest(text)
          
          had_word = scrape_words(div,article)[:had_word]
          
          # FIXME: had_word isn't working
          return hexdigest #if had_word
        end
      end
      
      raise ScrapeError,"could not scrape content at url[#{@url}]"
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
      
      raise ScrapeError,"could not scrape date time at url[#{@url}]"
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
      
      raise ScrapeError,"could not scrape futsuurl at url[#{@url}]"
    end
    
    def scrape_link(tag)
      link = tag.css('a')
      
      return nil if link.length < 1
      
      link = Util.unspace_web_str(link[0]['href'].to_s())
      
      return nil if link.empty?()
      return link
    end
    
    def scrape_nhk_news_web_easy()
      article = Article.new()
      doc = Nokogiri::HTML(@str_or_io)
      
      article.futsuurl = scrape_futsuurl(doc)
      article.datetime = scrape_datetime(doc,article.futsuurl)
      article.sha256 = scrape_content(doc,article)
      article.title = scrape_title(doc,article)
      article.url = @url
      
      # TODO: remove when done testing
      puts article
      
      return article
    end
    
    def scrape_title(doc,article)
      h1 = doc.css('h1.article-main__title')
      
      if h1.length > 0
        title = scrape_words(h1,article,words_as_str: true)[:words_as_str]
        title = Util.strip_web_str(title)
        
        return title unless title.empty?()
      end
      
      raise ScrapeError,"could not scrape title at url[#{@url}]"
    end
    
    # FIXME: <ruby>atara<rt>atara</rt></ruby>shii, how to do this to be atarashii?
    def scrape_word_ruby(tag,article,result)
      # First, try text nodes
      kanji = tag.search('./text()')
      
      # Second, try non-<rt> tags, in case of the text being surrounded by <span>, <b>, etc.
      kanji = [tag.search("./*[not(name()='rt')]").text] if kanji.length < 1
      
      raise ScrapeError,"no kanji in tag[#{tag}] at url[#{@url}]" if kanji.length < 1
      raise ScrapeError,"too many kanji in tag[#{tag}] at url[#{@url}]" if kanji.length > 1
      
      kanji = kanji[0]
      kanji = kanji.text if kanji.respond_to?(:text)
      words_as_str = result[:words_as_str]
      
      if !words_as_str.nil?()
        kanji = Util.clean_japanese_str(kanji)
        words_as_str << kanji
      end
      
      kanji = Util.unspace_web_str(kanji)
      kanji = @cleaner.clean(kanji)
      
      raise ScrapeError,"empty kanji in tag[#{tag}] at url[#{@url}]" if kanji.empty?()
      
      kana = tag.css('rt')
      
      raise ScrapeError,"no kana in tag[#{tag}] at url[#{@url}]" if kana.length < 1
      raise ScrapeError,"too many kana in tag[#{tag}] at url[#{@url}]" if kana.length > 1
      
      # Do not add kana to words_as_str
      kana = Util.unspace_web_str(kana[0].text)
      kana = @cleaner.clean(kana)
      
      raise ScrapeError,"empty kana in tag[#{tag}] at url[#{@url}]" if kana.empty?()
      
      result[:had_word] = true
      word = Word.new(kana: kana,kanji: kanji)
      
      article.add_word(word)
    end
    
    def scrape_word_text(tag,article,result)
      text = tag.text
      words_as_str = result[:words_as_str]
      
      if !words_as_str.nil?()
        text = Util.clean_japanese_str(text)
        words_as_str << text
      end
      
      text = @splitter.split(text)
      
      text.each() do |t|
        next if t.nil?()
        
        t = Util.unspace_web_str(t)
        t = @cleaner.clean(t)
        
        next if t.empty?()
        
        result[:had_word] = true
        word = Word.new(kana: t) # Assume kana
        
        article.add_word(word)
      end
    end
    
    def scrape_words(tag,article,words_as_str: false)
      result = {
        had_word: false,
        words_as_str: words_as_str ? ''.dup() : nil
      }
      
      tag.children.each() do |child|
        name = Util.unspace_web_str(child.name) if child.respond_to?(:name)
        
        if child.text?()
          scrape_word_text(child,article,result)
        elsif name.casecmp?('ruby')
          scrape_word_ruby(child,article,result)
        elsif name.casecmp?('rt')
          raise ScrapeError,"invalid rt tag[#{child}] without a ruby tag at url[#{@url}]"
        else
          child_result = scrape_words(child,article,words_as_str: words_as_str)
          
          had_word = true if child_result[:had_word]
          words_as_str << child_result[:words_as_str] unless result[:words_as_str].nil?()
        end
      end
      
      return result
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
      
      # As a last resort, use our user-defined fallback
      raise ScrapeError,"could not scrape year at url[#{@url}]" if Util.empty_web_str?(@year)
      
      return @year
    end
  end
end
