# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020-2021 Jonathan Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++

require 'attr_bool'
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

module NHKore
  class ArticleScraper < Scraper
    extend AttrBool::Ext

    attr_reader :cleaners
    attr_accessor :datetime
    attr_accessor :dict
    attr_reader :kargs
    attr_accessor :missingno
    attr_reader :polishers
    attr_accessor :splitter
    attr_accessor? :strict
    attr_reader :variators
    attr_accessor :year

    # @param dict [Dict,:scrape,nil] the {Dict} (dictionary) to use for {Word#defn} (definitions)
    #             [+:scrape+] auto-scrape it using {DictScraper}
    #             [+nil+]     don't scrape/use it
    # @param missingno [Missingno] data to use as a fallback for Ruby words without kana/kanji,
    #                  instead of raising an error
    # @param strict [true,false]
    def initialize(url,cleaners: [BestCleaner.new],datetime: nil,dict: :scrape,missingno: nil,
                   polishers: [BestPolisher.new],splitter: BestSplitter.new,strict: true,
                   variators: [BestVariator.new],year: nil,**kargs)
      super(url,**kargs)

      @cleaners = Array(cleaners)
      @datetime = datetime.nil? ? nil : Util.jst_time(datetime)
      @dict = dict
      @kargs = kargs
      @missingno = missingno
      @polishers = Array(polishers)
      @splitter = splitter
      @strict = strict
      @variators = Array(variators)
      @year = year
    end

    def add_words(article,words,text)
      words.each do |word|
        # Words should have already been cleaned.
        # If we don't check this, Word.new() could raise an error in polish().
        next if polish(word.word).empty?

        article.add_word(polish(word))

        variate(word.word).each do |v|
          v = polish(clean(v))

          next if v.empty?

          # Do not pass in "word: word". We only want defn & eng.
          # If we pass in kanji/kana & unknown, it will raise an error.
          article.add_word(Word.new(
            defn: word.defn,
            eng: word.eng,
            unknown: v
          ))
        end
      end

      split(text).each do |t|
        t = polish(clean(t))

        next if t.empty?

        article.add_word(Word.new(unknown: t))

        variate(t).each do |v|
          v = polish(clean(v))

          next if v.empty?

          article.add_word(Word.new(unknown: v))
        end
      end
    end

    def clean(obj)
      return Cleaner.clean_any(obj,@cleaners)
    end

    def fix_bad_html
      # Fixes:
      # - '<「<' without escaping '<' as '&lt;'
      #   - https://www3.nhk.or.jp/news/easy/k10012118911000/k10012118911000.html
      #   - '</p><br><「<ruby>台風<rt>たいふう</rt></ruby>'

      read

      # To add a new one, simply add '|(...)' on a newline and test Regexp.last_match().
      @str_or_io = @str_or_io.gsub(/
        (?<cane><「<)
      /x) do |match|
        if !Regexp.last_match(:cane).nil?
          match = match.sub('<','&lt;')
        end

        match
      end
    end

    def parse_datetime(str,year)
      str = str.gsub(/[\[\][[:space:]]]+/,'') # Remove: [ ] \s
      str = "#{year}年 #{str} #{Util::JST_OFFSET}"

      return Time.strptime(str,'%Y年 %m月%d日%H時%M分 %:z')
    end

    def parse_dicwin_id(str)
      str = str.to_s.strip.downcase

      if str.start_with?('id-') # 'id-0000'
        str = str.gsub(/\D+/,'')
      else # 'RSHOK-K-003806'
        # Same.
      end

      return nil if str.empty?
      return str
    end

    def polish(obj)
      return Polisher.polish_any(obj,@polishers)
    end

    def scrape
      scrape_dict
      fix_bad_html

      article = Article.new
      doc = html_doc

      article.futsuurl = scrape_futsuurl(doc)

      article.datetime = scrape_datetime(doc,article.futsuurl)
      article.sha256 = scrape_content(doc,article)
      article.title = scrape_title(doc,article)
      article.url = @url

      return article
    end

    def scrape_and_add_words(tag,article,result: ScrapeWordsResult.new)
      result = scrape_words(tag,result: result)
      result.polish!

      add_words(article,result.words,result.text)

      return result
    end

    def scrape_content(doc,article)
      tag = doc.css('div#js-article-body')
      tag = doc.css('div.article-main__body') if tag.empty?
      tag = doc.css('div.article-body') if tag.empty?

      # - https://www3.nhk.or.jp/news/easy/tsunamikeihou/index.html
      tag = doc.css('div#main') if tag.empty? && !@strict

      if !tag.empty?
        text = Util.unspace_web_str(tag.text.to_s)

        if !text.empty?
          hexdigest = Digest::SHA256.hexdigest(text)

          return hexdigest if article.nil? # For scrape_sha256_only()

          result = scrape_and_add_words(tag,article)

          return hexdigest if result.words?
        end
      end

      raise ScrapeError,"could not scrape content at URL[#{@url}]"
    end

    def scrape_datetime(doc,futsuurl = nil)
      year = scrape_year(doc,futsuurl)

      # First, try with the id.
      tag_name = 'p#js-article-date'
      tag = doc.css(tag_name)

      if !tag.empty?
        tag_text = tag[0].text

        begin
          datetime = parse_datetime(tag_text,year)

          return datetime
        rescue ArgumentError => e
          # Ignore; try again below.
          Util.warn("could not parse date time[#{tag_text}] from tag[#{tag_name}] at URL[#{@url}]: #{e}")
        end
      end

      # Second, try with the class.
      tag_name = 'p.article-main__date'
      tag = doc.css(tag_name)

      if !tag.empty?
        tag_text = tag[0].text

        begin
          datetime = parse_datetime(tag_text,year)

          return datetime
        rescue ArgumentError => e
          # Ignore; try again below.
          Util.warn("could not parse date time[#{tag_text}] from tag[#{tag_name}] at URL[#{@url}]: #{e}")
        end
      end

      # Third, try body's id.
      # - https://www3.nhk.or.jp/news/easy/article/disaster_earthquake_02.html
      # - 'news20170331_k10010922481000'
      tag = doc.css('body')

      if !tag.empty?
        tag_id = tag[0]['id'].to_s.split('_',2)

        if !tag_id.empty?
          tag_id = tag_id[0].gsub(/[^[[:digit:]]]+/,'')

          if tag_id.length == 8
            datetime = Time.strptime(tag_id,'%Y%m%d')

            return datetime
          end
        end
      end

      # As a last resort, use our user-defined fallback (if specified).
      return @datetime unless @datetime.nil?

      raise ScrapeError,"could not scrape date time at URL[#{@url}]"
    end

    def scrape_dict
      return if @dict != :scrape

      dict_url = DictScraper.parse_url(@url)
      retries = 0

      begin
        scraper = DictScraper.new(dict_url,missingno: @missingno,parse_url: false,**@kargs)
      rescue OpenURI::HTTPError => e
        if retries == 0 && e.to_s.include?('404')
          read

          scraper = ArticleScraper.new(@url,str_or_io: @str_or_io,**@kargs)

          dict_url = scraper.scrape_dict_url_only
          retries += 1

          retry
        else
          raise e.exception("could not scrape dictionary URL[#{dict_url}] at URL[#{@url}]: #{e}")
        end
      end

      @dict = scraper.scrape
    end

    def scrape_dict_url_only
      doc = html_doc

      # - https://www3.nhk.or.jp/news/easy/article/disaster_earthquake_02.html
      # - 'news20170331_k10010922481000'
      tag = doc.css('body')

      if !tag.empty?
        tag_id = tag[0]['id'].to_s.split('_',2)

        if tag_id.length == 2
          dict_url = Util.strip_web_str(tag_id[1])

          if !dict_url.empty?
            return DictScraper.parse_url(@url,basename: dict_url)
          end
        end
      end

      raise ScrapeError,"could not scrape dictionary URL at URL[#{@url}]"
    end

    def scrape_dicwin_word(tag,id,result: ScrapeWordsResult.new)
      dicwin_result = scrape_words(tag,dicwin: true)

      return nil unless dicwin_result.words?

      kana = ''.dup
      kanji = ''.dup

      dicwin_result.words.each do |word|
        kana << word.kana unless word.kana.nil?

        if kanji.empty?
          kanji << word.kanji unless word.kanji.nil?
        else
          kanji << word.word # Add trailing kana (or kanji) to kanji
        end
      end

      entry = nil
      kana = clean(kana)
      kanji = clean(kanji)

      raise ScrapeError,"empty dicWin word at URL[#{@url}] in tag[#{tag}]" if kana.empty? && kanji.empty?

      if !@dict.nil?
        entry = @dict[id]

        raise ScrapeError,"no dicWin ID[#{id}] at URL[#{@url}] in dictionary[#{@dict}]" if entry.nil?

        entry = entry.to_s
      end

      word = Word.new(
        defn: entry,
        kana: kana,
        kanji: kanji
      )

      result.add_text(dicwin_result.text) # Don't call dicwin_result.polish!()
      result.add_word(word)

      return word
    end

    def scrape_futsuurl(doc)
      # First, try with the id.
      tag = doc.css('div#js-regular-news-wrapper')

      if !tag.empty?
        link = scrape_link(tag[0])

        return link unless link.nil?
      end

      # Second, try with the class.
      tag = doc.css('div.link-to-normal')

      if !tag.empty?
        link = scrape_link(tag[0])

        return link unless link.nil?
      end

      # Some sites don't have a futsuurl and need a lenient mode.
      # - https://www3.nhk.or.jp/news/easy/article/disaster_earthquake_02.html
      warn_or_error(ScrapeError,"could not scrape futsuurl at URL[#{@url}]")

      return nil
    end

    def scrape_link(tag)
      link = tag.css('a')

      return nil if link.empty?

      link = Util.unspace_web_str(link[0]['href'].to_s)

      return nil if link.empty?
      return link
    end

    # @see https://www3.nhk.or.jp/news/easy/k10012759201000/k10012759201000.html
    def scrape_ruby_words(tag,result: ScrapeWordsResult.new)
      words = Word.scrape_ruby_tag(tag,missingno: @missingno,url: @url)
      final_words = []

      return final_words if words.nil?

      words.each do |word|
        final_words << scrape_ruby_word(word,result: result)
      end

      return final_words
    end

    def scrape_ruby_word(word,result: ScrapeWordsResult.new)
      # No cleaning; raw text.
      # Do not add kana to the text.
      result.add_text(word.kanji)

      kanji = clean(word.kanji)
      kana = clean(word.kana)

      # Even though Word.scrape_ruby_tag() also does this,
      #   check it again after cleaning above.
      if !@missingno.nil?
        # Check kana first, since this is the typical scenario.
        # - https://www3.nhk.or.jp/news/easy/k10012331311000/k10012331311000.html
        # - '窓' in '（８）窓を開けて外の空気を入れましょう'
        if kana.empty?
          kana = @missingno.kana_from_kanji(kanji)
          kana = kana.nil? ? '' : clean(kana)

          if !kana.empty?
            Util.warn("using missingno for kana[#{kana}] from kanji[#{kanji}]")
          end
        elsif kanji.empty?
          kanji = @missingno.kanji_from_kana(kana)
          kanji = kanji.nil? ? '' : clean(kanji)

          if !kanji.empty?
            Util.warn("using missingno for kanji[#{kanji}] from kana[#{kana}]")
          end
        end
      end

      raise ScrapeError,"empty kanji at URL[#{@url}] in tag[#{tag}]" if kanji.empty?
      raise ScrapeError,"empty kana at URL[#{@url}] in tag[#{tag}]" if kana.empty?

      word = Word.new(
        kana: kana,
        kanji: kanji,
        word: word
      )

      return word
    end

    def scrape_sha256_only
      doc = html_doc

      sha256 = scrape_content(doc,nil)

      return sha256
    end

    def scrape_text_word(tag,result: ScrapeWordsResult.new)
      word = Word.scrape_text_node(tag,url: @url)

      if word.nil?
        result.add_text(tag.text.to_s) # Raw spaces for output

        return nil
      end

      # Kanji only for:
      # - https://www3.nhk.or.jp/news/easy/k10012639271000/k10012639271000.html
      #   - '第３のビール'
      text = word.word # Should usually be kana only

      result.add_text(text) # No cleaning; raw text

      text = clean(text)

      return nil if text.empty? # No error; empty text is fine here

      word = Word.new(
        kana: clean(word.kana),
        kanji: clean(word.kanji),
        word: word,
      )

      return word
    end

    def scrape_title(doc,article)
      # Not grabbing `<head><title>` because it doesn't have `<ruby>` tags.

      tag = doc.css('h1.article-main__title')
      tag_name = nil

      if tag.empty?
        # - https://www3.nhk.or.jp/news/easy/em2024081312029/em2024081312029.html
        tag = doc.css('h1.article-title') # No warning.
      end

      if tag.empty?
        # - https://www3.nhk.or.jp/news/easy/article/disaster_earthquake_illust.html
        tag_name = 'h1.article-eq__title'
        tag = doc.css(tag_name)
      end
      if tag.empty? && !@strict
        # This shouldn't be used except for select sites.
        # - https://www3.nhk.or.jp/news/easy/tsunamikeihou/index.html
        tag_name = 'div#main h2'
        tag = doc.css(tag_name)
      end

      if !tag.empty?
        Util.warn("using [#{tag_name}] for title at URL[#{@url}]") unless tag_name.nil?

        result = scrape_and_add_words(tag,article)
        title = result.text

        return title unless title.empty?
      end

      raise ScrapeError,"could not scrape title at URL[#{@url}]"
    end

    def scrape_words(tag,dicwin: false,result: ScrapeWordsResult.new)
      children = tag.children.to_a.reverse # A faster stack?

      while !children.empty?
        child = children.pop
        name = nil
        words = []

        name = Util.unspace_web_str(child.name.to_s).downcase if child.respond_to?(:name)

        if name == 'ruby'
          # Returns an array.
          words = scrape_ruby_words(child,result: result)
        elsif child.text?
          words << scrape_text_word(child,result: result)
        elsif name == 'rt'
          raise ScrapeError,"invalid rt tag[#{child}] without a ruby tag at URL[#{@url}]"
        else
          dicwin_id = nil

          if name == 'a'
            id = parse_dicwin_id(child['id'].to_s)
            klass = Util.unspace_web_str(child['class'].to_s).downcase

            if klass == 'dicwin' && !id.nil?
              if dicwin
                raise ScrapeError,"invalid dicWin class[#{child}] nested inside another dicWin class at " \
                                  "URL[#{@url}]"
              end

              dicwin_id = id
            end
          end

          if dicwin_id.nil?
            # I originally didn't use a stack-like Array and did a constant insert,
            #   but I think this is slower (moving all elements down every time).
            # However, if it's using C-like code for moving memory, then maybe it
            #   is faster?
            # Old code:
            #   children.insert(i + 1,*child.children.to_a())
            grand_children = child.children.to_a

            (grand_children.length - 1).downto(0).each do |i|
              children.push(grand_children[i])
            end
          else
            words << scrape_dicwin_word(child,dicwin_id,result: result)
          end
        end

        words&.each do |word|
          # All word-scraping methods can return nil.
          result.add_word(word) unless word.nil?
        end
      end

      return result
    end

    def scrape_year(doc,futsuurl = nil)
      # First, try body's id.
      tag = doc.css('body')

      if !tag.empty?
        tag_id = tag[0]['id'].to_s.gsub(/[^[[:digit:]]]+/,'')

        if tag_id.length >= 4
          year = tag_id[0..3].to_i

          return year if Util.sane_year?(year)
        end
      end

      # Second, try futsuurl.
      if !futsuurl.nil?
        m = futsuurl.match(/([[:digit:]]{4,})/)

        if !m.nil? && (m = m[0].to_s).length >= 4
          year = m[0..3].to_i

          return year if Util.sane_year?(year)
        end
      end

      # As a last resort, use our user-defined fallbacks (if specified).
      return @year.to_i unless @year.nil?
      return @datetime.year if !@datetime.nil? && Util.sane_year?(@datetime.year)

      raise ScrapeError,"could not scrape year at URL[#{@url}]"
    end

    def split(str)
      return @splitter.split(str)
    end

    def variate(str)
      variations = []

      @variators.each do |variator|
        variations.push(*variator.variate(str))
      end

      return variations
    end

    def warn_or_error(klass,msg)
      if @strict
        raise klass,msg
      else
        Util.warn(msg)
      end
    end
  end

  class ScrapeWordsResult
    attr_reader :text
    attr_reader :words

    def initialize
      super

      @text = ''.dup
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

    def polish!
      @text = Util.strip_web_str(@text)

      return self
    end

    def words?
      return !@words.empty?
    end
  end
end
