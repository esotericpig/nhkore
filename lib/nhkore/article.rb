# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020 Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++

require 'time'

require 'nhkore/util'
require 'nhkore/word'

module NHKore
  class Article
    attr_reader :datetime
    attr_reader :futsuurl
    attr_accessor :sha256
    attr_accessor :title
    attr_reader :url
    attr_reader :words

    def initialize
      super

      @datetime = nil
      @futsuurl = nil
      @sha256 = nil
      @title = nil
      @url = nil
      @words = {}
    end

    # Why does this not look up the kanji/kana only and then update the other
    # kana/kanji part appropriately?
    # - There are some words like +行って+. Without the kana, it's difficult to
    #   determine what kana it should be. Should it be +いって+ or +おこなって+?
    # - Similarly, if we just have +いって+, should this be +行って+ or +言って+?
    # - Therefore, if we only have the kanji or only have the kana, we don't
    #   try to populate the other value.
    def add_word(word,use_freq: false)
      curr_word = words[word.key]

      if curr_word.nil?
        words[word.key] = word
        curr_word = word
      else
        curr_word.freq += (use_freq ? word.freq : 1)

        curr_word.defn = word.defn if word.defn.to_s.length > curr_word.defn.to_s.length
        curr_word.eng = word.eng if word.eng.to_s.length > curr_word.eng.to_s.length
      end

      return curr_word
    end

    def encode_with(coder)
      # Order matters.

      coder[:datetime] = @datetime.nil? ? @datetime : @datetime.iso8601
      coder[:title] = @title
      coder[:url] = @url.nil? ? nil : @url.to_s
      coder[:futsuurl] = @futsuurl.nil? ? nil : @futsuurl.to_s
      coder[:sha256] = @sha256
      coder[:words] = @words
    end

    def self.load_data(_key,hash)
      words = hash[:words]

      article = Article.new

      article.datetime = hash[:datetime]
      article.futsuurl = hash[:futsuurl]
      article.sha256 = hash[:sha256]
      article.title = hash[:title]
      article.url = hash[:url]

      words&.each do |k,h|
        k = k.to_s # Change from a symbol
        article.words[k] = Word.load_data(k,h)
      end

      return article
    end

    def datetime=(value)
      @datetime = if value.is_a?(Time)
                    value
                  else
                    Util.empty_web_str?(value) ? nil : Time.iso8601(value)
                  end
    end

    def futsuurl=(value)
      # Don't store URI, store String or nil.
      @futsuurl = value&.to_s
    end

    def url=(value)
      # Don't store URI, store String or nil.
      @url = value&.to_s
    end

    def to_s(mini: false)
      s = ''.dup

      s << "'#{@url}':"
      s << "\n  datetime: '#{@datetime}'"
      s << "\n  title:    '#{@title}'"
      s << "\n  url:      '#{@url}'"
      s << "\n  futsuurl: '#{@futsuurl}'"
      s << "\n  sha256:   '#{@sha256}'"

      if !mini
        s << "\n  words:"
        @words.each do |_key,word|
          s << "\n    #{word}"
        end
      end

      return s
    end
  end
end
