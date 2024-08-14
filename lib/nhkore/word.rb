# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020-2021 Jonathan Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++


require 'nokogiri'

require 'nhkore/error'
require 'nhkore/util'


module NHKore
  class Word
    attr_accessor :defn
    attr_accessor :eng
    attr_accessor :freq
    attr_reader :kana
    attr_reader :kanji
    attr_reader :key

    def initialize(defn: nil,eng: nil,freq: 1,kana: nil,kanji: nil,unknown: nil,word: nil,**kargs)
      super()

      if !word.nil?
        defn = word.defn if defn.nil?
        eng = word.eng if eng.nil?
        freq = word.freq if freq.nil?
        kana = word.kana if kana.nil?
        kanji = word.kanji if kanji.nil?
      end

      raise ArgumentError,"freq[#{freq}] cannot be < 1" if freq < 1

      if !unknown.nil?
        # kanji?() only tests if it contains kanji, so don't use kana?().
        if Util.kanji?(unknown)
          if !Util.empty_web_str?(kanji)
            raise ArgumentError,"unknown[#{unknown}] will overwrite kanji[#{kanji}]"
          end

          kanji = unknown
        else
          if !Util.empty_web_str?(kana)
            raise ArgumentError,"unknown[#{unknown}] will overwrite kana[#{kana}]"
          end

          kana = unknown
        end
      end

      kana = nil if Util.empty_web_str?(kana)
      kanji = nil if Util.empty_web_str?(kanji)

      raise ArgumentError,'kanji and kana cannot both be empty' if kana.nil? && kanji.nil?

      @defn = defn
      @eng = eng
      @freq = freq
      @kana = kana
      @kanji = kanji
      @key = "#{kanji}=#{kana}" # nil.to_s() is ''
    end

    def encode_with(coder)
      # Ignore @key because it will be the key in the YAML/Hash.
      # Order matters.

      coder[:kanji] = @kanji
      coder[:kana] = @kana
      coder[:freq] = @freq
      coder[:defn] = @defn
      coder[:eng] = @eng
    end

    def self.load_data(key,hash)
      key = key.to_s # Change from a symbol

      word = Word.new(
        defn: hash[:defn],
        eng: hash[:eng],
        kana: hash[:kana],
        kanji: hash[:kanji]
      )

      if key != word.key
        raise ArgumentError,"the key from the hash[#{key}] does not match the generated key[#{word.key}]"
      end

      freq = hash[:freq].to_i # nil.to_i() is 0
      word.freq = freq if freq > 0

      return word
    end

    # Do not clean and/or strip spaces, as the raw text is important for
    # Defn and ArticleScraper.
    #
    # This originally only scraped 1 word, but multiple words were added
    # after seeing this link for 産業能率大学, which is valid HTML:
    #   https://www3.nhk.or.jp/news/easy/k10012759201000/k10012759201000.html
    #
    # @return [Array<Word>] the scraped {Word}(s)
    def self.scrape_ruby_tag(tag,missingno: nil,url: nil)
      # First, try <rb> tags.
      kanjis = tag.css('rb')
      # Second, try text nodes.
      kanjis = tag.search('./text()') if kanjis.length < 1
      # Third, try non-<rt> tags, in case of being surrounded by <span>, <b>, etc.
      kanjis = tag.search("./*[not(name()='rt')]") if kanjis.length < 1

      kanas = tag.css('rt')

      raise ScrapeError,"no kanji at URL[#{url}] in tag[#{tag}]" if kanjis.length < 1
      raise ScrapeError,"no kana at URL[#{url}] in tag[#{tag}]" if kanas.length < 1

      if kanjis.length != kanas.length
        raise ScrapeError,"number of kanji & kana mismatch at URL[#{url}] in tag[#{tag}]"
      end

      words = []

      (0...kanjis.length).each do |i|
        kanji = kanjis[i].text
        kana = kanas[i].text

        # Uncomment for debugging; really need a logger.
        #puts "Word[#{i}]: #{kanji} => #{kana}"

        if !missingno.nil?
          # Check kana first, since this is the typical scenario.
          # - https://www3.nhk.or.jp/news/easy/k10012331311000/k10012331311000.html
          # - '窓' in '（８）窓を開けて外の空気を入れましょう'
          if Util.empty_web_str?(kana)
            kana = missingno.kana_from_kanji(kanji)

            if !Util.empty_web_str?(kana)
              Util.warn("using missingno for kana[#{kana}] from kanji[#{kanji}]")
            end
          elsif Util.empty_web_str?(kanji)
            kanji = missingno.kanji_from_kana(kana)

            if !Util.empty_web_str?(kanji)
              Util.warn("using missingno for kanji[#{kanji}] from kana[#{kana}]")
            end
          end
        end

        raise ScrapeError,"empty kanji at URL[#{url}] in tag[#{tag}]" if Util.empty_web_str?(kanji)
        raise ScrapeError,"empty kana at URL[#{url}] in tag[#{tag}]" if Util.empty_web_str?(kana)

        words << Word.new(kanji: kanji,kana: kana)
      end

      return words
    end

    # Do not clean and/or strip spaces, as the raw text is important for
    # Defn and ArticleScraper.
    def self.scrape_text_node(tag,url: nil)
      text = tag.text

      # No error; empty text is fine (not strictly kanji/kana only).
      return nil if Util.empty_web_str?(text)

      word = Word.new(unknown: text)

      return word
    end

    def kanji?
      return !Util.empty_web_str?(@kanji)
    end

    def word
      return kanji? ? @kanji : @kana
    end

    def to_s
      s = ''.dup

      s << "'#{@key}': "
      s << "{ kanji=>'#{@kanji}'"
      s << ", kana=>'#{@kana}'"
      s << ", freq=>#{@freq}"
      s << ", defn=>'#{@defn.to_s.gsub("\n",'\\n')}'"
      s << ", eng=>'#{@eng}'"
      s << ' }'

      return s
    end
  end
end
