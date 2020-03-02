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
require 'nhkore/polisher'
require 'nhkore/splitter'
require 'nhkore/util'
require 'nhkore/word'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class ArticleScraper
    attr_accessor :cleaners
    attr_accessor :polishers
    attr_accessor :splitter
    attr_accessor :str_or_io
    attr_accessor :url
    attr_accessor :year
    
    def initialize(url,cleaners: [BestCleaner.new()],file: false,polishers: [BestPolisher.new()],splitter: BestSplitter.new(),str_or_io: nil,year: nil)
      super()
      
      @cleaners = cleaners
      @polishers = polishers
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
    
    def add_words(words,article,text)
    end
    
    def clean(word)
      return word if word.nil?()
      
      if word.is_a?(Word)
        word = Word.new(
          eng: word.eng,
          freq: word.freq,
          kana: clean(word.kana),
          kanji: clean(word.kanji),
          mean: word.mean
        )
      else # String
        @cleaners.each() do |cleaner|
          word = cleaner.clean(word)
        end
      end
      
      return word
    end
    
    def parse_datetime(str,year)
      str = str.gsub(/[\[\][[:space:]]]+/,'')
      str = "#{year}年 #{str} #{Util::JST_OFFSET}"
      
      return Time.strptime(str,'%Y年 %m月%d日%H時%M分 %:z')
    end
    
    def polish(word)
      return word if word.nil?()
      
      if word.is_a?(Word)
        word = Word.new(
          eng: word.eng,
          freq: word.freq,
          kana: polish(word.kana),
          kanji: polish(word.kanji),
          mean: word.mean
        )
      else # String
        @polishers.each() do |polisher|
          word = polisher.polish(word)
        end
      end
      
      return word
    end
    
    def scrape_content(doc,article)
      div = doc.css('div#js-article-body')
      div = doc.css('div.article-main__body') if div.length < 1
      div = doc.css('div.article-body') if div.length < 1
      
      if div.length > 0
        text = Util.unspace_web_str(div.text.to_s())
        
        if !text.empty?()
          hexdigest = Digest::SHA256.hexdigest(text)
          result = scrape_words(div,article)
          
          return hexdigest if result.had_word?()
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
    
    def scrape_ruby_word(tag,result: ScrapeWordsResult.new())
      # First, try text nodes
      kanji = tag.search('./text()')
      # Second, try non-<rt> tags, in case of the text being surrounded by <span>, <b>, etc.
      kanji = [tag.search("./*[not(name()='rt')]").text] if kanji.length < 1
      
      raise ScrapeError,"no kanji in tag[#{tag}] at url[#{@url}]" if kanji.length < 1
      raise ScrapeError,"too many kanji in tag[#{tag}] at url[#{@url}]" if kanji.length > 1
      
      kanji = kanji[0]
      kanji = kanji.text if kanji.respond_to?(:text)
      
      result << kanji # No cleaning; raw text
      
      kanji = clean(kanji)
      
      raise ScrapeError,"empty kanji in tag[#{tag}] at url[#{@url}]" if kanji.empty?()
      
      kana = tag.css('rt')
      
      raise ScrapeError,"no kana in tag[#{tag}] at url[#{@url}]" if kana.length < 1
      raise ScrapeError,"too many kana in tag[#{tag}] at url[#{@url}]" if kana.length > 1
      
      # Do not add kana to result.output_str
      kana = clean(kana[0].text)
      
      raise ScrapeError,"empty kana in tag[#{tag}] at url[#{@url}]" if kana.empty?()
      
      word = Word.new(kana: kana,kanji: kanji)
      result.had_word = true
      
      return word
    end
    
    def scrape_text_word(tag,result: ScrapeWordsResult.new())
      text = tag.text
      
      result << text # No cleaning; raw text
      
      text = clean(text)
      
      return nil if text.empty?() # No error; empty text is fine here
      
      word = Word.new(kana: text) # Assume kana
      result.had_word = true
      
      return word
    end
    
    def scrape_title(doc,article)
      h1 = doc.css('h1.article-main__title')
      
      if h1.length > 0
        result = scrape_words(h1,article)
        title = result.output_str
        
        return title unless title.empty?()
      end
      
      raise ScrapeError,"could not scrape title at url[#{@url}]"
    end
    
    def scrape_words(tag,article,result: ScrapeWordsResult.new())
      children = tag.children.to_a().reverse() # A faster stack?
      words = []
      
      while !children.empty?()
        child = children.pop()
        
        name = Util.unspace_web_str(child.name).downcase() if child.respond_to?(:name)
        
        if child.text?()
          word = scrape_text_word(child,result: result)
          words << word if word
        elsif name == 'ruby'
          word = scrape_ruby_word(child,result: result)
          words << word if word
        elsif name == 'rt'
          raise ScrapeError,"invalid rt tag[#{child}] without a ruby tag at url[#{@url}]"
        else
          grand_children = child.children.to_a()
          
          (grand_children.length() - 1).downto(0).each() do |i|
            children.push(grand_children[i])
          end
          
          # I originally didn't use a stack-like Array and did a constant insert,
          #   but I think this is slower (moving all elements down every time).
          # However, if it's using C-like code for moving memory, then maybe it
          #   is faster?
          #children.insert(i + 1,*child.children.to_a())
        end
      end
      
      result.output_str = Util.strip_web_str(result.output_str)
      
      add_words(words,article,result.output_str) if result.had_word?()
      
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
    
    def split(str)
      return @splitter.split(str)
    end
  end
  
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class ScrapeWordsResult
    attr_accessor :had_word
    attr_accessor :output_str
    
    alias_method :had_word?,:had_word
    
    def initialize()
      super()
      
      @had_word = false
      @output_str = ''.dup()
    end
    
    def <<(str)
      @output_str << Util.reduce_jpn_space(str)
      
      return self
    end
  end
end

=begin
      # FIXME: need to capture multiple next
      if next_tag && next_tag.text?()
        extra_kana = Util.unspace_web_str(next_tag.text)
        full_word = "#{kanji}#{extra_kana}"
        split = @splitter.split(extra_kana)
        
        if split[0] != kanji
          kana = @cleaner.clean("#{kana}#{extra_kana}")
          kanji = @cleaner.clean(full_word)
        else
          extra_kana = false
        end
      end
=end

=begin
    def add_words(words,article,text)
      #return if text.length > 50
      
      # For testing...
      
      # 始=はじまる
      # 高=たかくなりそうです。
      # 円=えんかかりました。「マリオ」の
      
      #text << '日本語'
      #words << Word.new(kanji: '日本語',kana: 'にほんご')
      
      text = split(text)
      
      text_i = -1
      word_i = -1
      
      loop do
        text_i += 1
        word_i += 1
        
        break if text_i >= text.length || word_i >= words.length
        
        text_str = clean(text[text_i])
        
        # For example, if a number like 450, then will be empty, depending on the cleaners
        if text_str.empty?()
          puts "Skipping: #{text[text_i]}"
          word_i -= 1 # Words should have already been cleaned & skipped appropriately
          next
        end
        
        # TODO: store text_norm & text_str; word_norm & word_str
        # Have to normalize: 「マリオ」のエリアができる
        text_str = Util.normalize_str(text_str)
        word = words[word_i]
        word_str = Util.normalize_str(word.word)
        
        if text_str == word_str
          puts "=Adding:  #{text_str},#{word_str}"
          article.add_word(polish(word))
        # 'の' < 'のエリア'
        elsif text_str.length < word_str.length
          raise "<: #{text_str} !~ #{word_str}" unless word_str.include?(text_str)
          
          add_word = false
          
          # If a ruby tag, can't guarantee one-to-one for kanji & kana, so skip.
          # - For example: 大阪 => おおさか. If we chop off 1, it will be [大] & [おおさ],
          #                which is wrong. [大] & [おお] would be correct.
          if word.kanji?()
            puts "<Adding:  #{text_str},#{word_str}"
            article.add_word(polish(word))
          else
            add_word = true
          end
          
          len = 0
          
          loop do
            if add_word
              puts "<Adding:  #{text_str},#{word_str}"
              article.add_word(polish(Word.new(kana: text_str)))
            end
            
            len += text_str.length
            text_i += 1
            
            puts "<Working: #{text_str},#{word_str},#{len}"
            
            #break if len >= word_str.length || text_i >= text.length
            break if len == word_str.length
            raise "<wtf: #{text_str},#{word_str},#{len}" if len > word_str.length
            
            # Get next clean text_str
            loop do
              raise 'wtf' if text_i >= text.length
              
              text_str = clean(text[text_i])
              
              break unless text_str.empty?()
              
              text_i += 1
            end
            
            text_str = Util.normalize_str(text_str)
          end
          
          text_i -= 1 # Reset for main loop
        elsif text_str.length > word_str.length
          raise ">: #{text_str} !~ #{word_str}" unless text_str.include?(word_str)
          
          full_kana = ''.dup()
          full_kanji = ''.dup()
          orig_word = word
          
          len = 0
          
          loop do
            if word.kanji?()
              full_kana << word.kana unless word.kana.nil?()
              full_kanji << word.kanji
            else
              full_kana << word.kana
              full_kanji << word.kana # Like 食べます (kanji + kana)
            end
            
            len += word_str.length
            word_i += 1
            
            #break if len >= text_str.length || word_i >= words.length
            break if len == text_str.length
            raise ">wtf: #{text_str},#{word_str},#{len}" if len > text_str.length
            raise ">wtf: #{text_str},#{word_str},no words" if word_i >= words.length
            
            word = words[word_i]
            word_str = Util.normalize_str(word.word)
            
            #raise 'wtf' unless text_str.include?(word_str)
          end
          
          puts ">Adding:  #{text_str},#{word_str}"
          # TODO: if empty str, change to nil
          article.add_word(polish(Word.new(
            eng: orig_word.eng,
            freq: orig_word.freq,
            kana: full_kana,
            kanji: full_kanji,
            mean: orig_word.mean
          )))
          
          word_i -= 1 # Reset for main loop
        else
          raise "wtf is: #{text_str},#{word_str}"
        end
      end
      
      raise 'wtf is up w/ word_i < words.length' if word_i < words.length
      
      # Skip rest of dirty text
      while text_i < text.length
        text_str = clean(text[text_i])
        
        # Not dirty; raise an error after the loop
        break unless text_str.empty?()
        
        text_i += 1
      end
      
      raise 'wtf is up w/ text_i < text.length' if text_i < text.length
    end
=end
