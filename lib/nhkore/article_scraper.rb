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
require 'nhkore/article'
require 'nhkore/cleaner'
require 'nhkore/dict'
require 'nhkore/dict_scraper'
require 'nhkore/error'
require 'nhkore/polisher'
require 'nhkore/scraper'
require 'nhkore/splitter'
require 'nhkore/util'
require 'nhkore/variator'
require 'nhkore/word'
require 'nokogiri'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class ArticleScraper < Scraper
    attr_reader :cleaners
    attr_accessor :dict
    attr_reader :kargs
    attr_reader :polishers
    attr_accessor :splitter
    attr_reader :variators
    attr_accessor :year
    
    def initialize(url,cleaners: [BestCleaner.new()],dict: nil,polishers: [BestPolisher.new()],splitter: BestSplitter.new(),variators: [BestVariator.new()],year: nil,**kargs)
      super(url,**kargs)
      
      @cleaners = Array(cleaners)
      @dict = dict
      @kargs = kargs
      @polishers = Array(polishers)
      @splitter = splitter
      @variators = Array(variators)
      @year = year
    end
    
    def add_words(article,words,text)
      words.each() do |word|
        # Words should have already been cleaned.
        article.add_word(polish(word))
        
        variate(word.word).each() do |v|
          v = clean(v)
          
          next if v.empty?()
          
          # Do not pass in "word: word".
          # We only want defn & eng.
          # If we pass in kanji/kana & unknown, it will raise an error.
          article.add_word(Word.new(
            defn: word.defn,
            eng: word.eng,
            unknown: polish(v)
          ))
        end
      end
      
      split(text).each() do |t|
        t = clean(t)
        
        next if t.empty?()
        
        article.add_word(Word.new(unknown: polish(t)))
        
        variate(t).each() do |v|
          v = clean(v)
          
          next if v.empty?()
          
          article.add_word(Word.new(unknown: polish(v)))
        end
      end
    end
    
    def clean(obj)
      return Cleaner.clean_any(obj,@cleaners)
    end
    
    def self.parse_datetime(str,year)
      str = str.gsub(/[\[\][[:space:]]]+/,'') # Remove: [ ] \s
      str = "#{year}年 #{str} #{Util::JST_OFFSET}"
      
      return Time.strptime(str,'%Y年 %m月%d日%H時%M分 %:z')
    end
    
    def self.parse_dicwin_id(str)
      str = str.gsub(/\D+/,'')
      
      return nil if str.empty?()
      return str
    end
    
    def polish(obj)
      return Polisher.polish_any(obj,@polishers)
    end
    
    def scrape()
      scrape_dict() if @dict.nil?()
      
      article = Article.new()
      doc = html_doc()
      
      article.futsuurl = scrape_futsuurl(doc)
      
      article.datetime = scrape_datetime(doc,article.futsuurl)
      article.sha256 = scrape_content(doc,article)
      article.title = scrape_title(doc,article)
      article.url = @url
      
      return article
    end
    
    def scrape_and_add_words(tag,article,result: ScrapeWordsResult.new())
      result = scrape_words(tag,result: result)
      result.polish!()
      
      add_words(article,result.words,result.text)
      
      return result
    end
    
    def scrape_content(doc,article)
      div = doc.css('div#js-article-body')
      div = doc.css('div.article-main__body') if div.length < 1
      div = doc.css('div.article-body') if div.length < 1
      
      if div.length > 0
        text = Util.unspace_web_str(div.text.to_s())
        
        if !text.empty?()
          hexdigest = Digest::SHA256.hexdigest(text)
          
          return hexdigest if article.nil?() # For scrape_sha256_only()
          
          result = scrape_and_add_words(div,article)
          
          return hexdigest if result.words?()
        end
      end
      
      raise ScrapeError,"could not scrape content at URL[#{@url}]"
    end
    
    def scrape_datetime(doc,futsuurl=nil)
      year = scrape_year(doc,futsuurl)
      
      # First, try with the id
      p = doc.css('p#js-article-date')
      
      if p.length > 0
        p = p[0]
        
        begin
          datetime = self.class.parse_datetime(p.text,year)
          
          return datetime
        rescue ArgumentError => e
          e # TODO: log.warn()?
        end
      end
      
      # Second, try with the class
      p = doc.css('p.article-main__date')
      
      if p.length > 0
        p = p[0]
        datetime = self.class.parse_datetime(p.text,year) # Allow the error to raise
        
        return datetime
      end
      
      raise ScrapeError,"could not scrape date time at URL[#{@url}]"
    end
    
    def scrape_dict()
      dict_scraper = DictScraper.new(@url,**@kargs)
      @dict = dict_scraper.scrape()
    end
    
    def scrape_dicwin_word(tag,id,result: ScrapeWordsResult.new())
      dicwin_result = scrape_words(tag,dicwin: true)
      
      return nil unless dicwin_result.words?()
      
      kana = ''.dup()
      kanji = ''.dup()
      
      dicwin_result.words.each() do |word|
        kana << word.kana unless word.kana.nil?()
        
        if kanji.empty?()
          kanji << word.kanji unless word.kanji.nil?()
        else
          kanji << word.word # Add trailing kana (or kanji) to kanji
        end
      end
      
      kana = clean(kana)
      kanji = clean(kanji)
      
      raise ScrapeError,"empty dicWin word at URL[#{@url}] in tag[#{tag}]" if kana.empty?() && kanji.empty?()
      
      entry = @dict[id]
      
      raise ScrapeError,"no dicWin ID[#{id}] at URL[#{@url}] in dictionary[#{@dict}]" if entry.nil?()
      
      word = Word.new(
        defn: entry.to_s(),
        kana: kana,
        kanji: kanji
      )
      
      result.add_text(dicwin_result.text) # Don't call dicwin_result.polish!()
      result.add_word(word)
      
      return word
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
      
      raise ScrapeError,"could not scrape futsuurl at URL[#{@url}]"
    end
    
    def scrape_link(tag)
      link = tag.css('a')
      
      return nil if link.length < 1
      
      link = Util.unspace_web_str(link[0]['href'].to_s())
      
      return nil if link.empty?()
      return link
    end
    
    def scrape_ruby_word(tag,result: ScrapeWordsResult.new())
      word = Word.scrape_ruby_tag(tag,url: @url)
      
      return nil if word.nil?()
      
      # No cleaning; raw text.
      # Do not add kana to the text.
      result.add_text(word.kanji)
      
      kanji = clean(word.kanji)
      
      raise ScrapeError,"empty kanji at URL[#{@url}] in tag[#{tag}]" if kanji.empty?()
      
      kana = clean(word.kana)
      
      raise ScrapeError,"empty kana at URL[#{@url}] in tag[#{tag}]" if kana.empty?()
      
      word = Word.new(
        kana: kana,
        kanji: kanji,
        word: word
      )
      
      return word
    end
    
    def scrape_sha256_only()
      doc = html_doc()
      
      sha256 = scrape_content(doc,nil)
      
      return sha256
    end
    
    def scrape_text_word(tag,result: ScrapeWordsResult.new())
      word = Word.scrape_text_node(tag,url: @url)
      
      if word.nil?()
        result.add_text(tag.text.to_s()) # Raw spaces for output
        
        return nil
      end
      
      text = word.kana # Should be kana only
      
      result.add_text(text) # No cleaning; raw text
      
      text = clean(text)
      
      return nil if text.empty?() # No error; empty text is fine here
      
      word = Word.new(
        kana: text,
        word: word
      )
      
      return word
    end
    
    def scrape_title(doc,article)
      h1 = doc.css('h1.article-main__title')
      
      if h1.length > 0
        result = scrape_and_add_words(h1,article)
        title = result.text
        
        return title unless title.empty?()
      end
      
      raise ScrapeError,"could not scrape title at URL[#{@url}]"
    end
    
    def scrape_words(tag,dicwin: false,result: ScrapeWordsResult.new())
      children = tag.children.to_a().reverse() # A faster stack?
      
      while !children.empty?()
        child = children.pop()
        name = nil
        word = nil
        
        name = Util.unspace_web_str(child.name.to_s()).downcase() if child.respond_to?(:name)
        
        if name == 'ruby'
          word = scrape_ruby_word(child,result: result)
        elsif child.text?()
          word = scrape_text_word(child,result: result)
        elsif name == 'rt'
          raise ScrapeError,"invalid rt tag[#{child}] without a ruby tag at URL[#{@url}]"
        else
          dicwin_id = nil
          
          if name == 'a'
            klass = Util.unspace_web_str(child['class'].to_s()).downcase()
            id = self.class.parse_dicwin_id(child['id'].to_s())
            
            if klass == 'dicwin' && !id.nil?()
              if dicwin
                raise ScrapeError,"invalid dicWin class[#{child}] nested inside another dicWin class at URL[#{@url}]"
              end
              
              dicwin_id = id
            end
          end
          
          if dicwin_id.nil?()
            grand_children = child.children.to_a()
            
            (grand_children.length() - 1).downto(0).each() do |i|
              children.push(grand_children[i])
            end
            
            # I originally didn't use a stack-like Array and did a constant insert,
            #   but I think this is slower (moving all elements down every time).
            # However, if it's using C-like code for moving memory, then maybe it
            #   is faster?
            #children.insert(i + 1,*child.children.to_a())
          else
            word = scrape_dicwin_word(child,dicwin_id,result: result)
          end
        end
        
        result.add_word(word) unless word.nil?()
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
      raise ScrapeError,"could not scrape year at URL[#{@url}]" if Util.empty_web_str?(@year)
      
      return @year
    end
    
    def split(str)
      return @splitter.split(str)
    end
    
    def variate(str)
      variations = []
      
      @variators.each() do |variator|
        variations.push(*variator.variate(str))
      end
      
      return variations
    end
  end
  
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class ScrapeWordsResult
    attr_reader :text
    attr_reader :words
    
    def initialize()
      super()
      
      @text = ''.dup()
      @words = []
    end
    
    def add_text(text)
      @text << Util.reduce_jpn_space(text)
      
      return self
    end
    
    def add_word(word)
      @words << word
      
      return self
    end
    
    def polish!()
      @text = Util.strip_web_str(@text)
      
      return self
    end
    
    def words?()
      return !@words.empty?()
    end
  end
end
