# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020 Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++

require 'nhkore/util'
require 'nhkore/word'

module NHKore
  class Cleaner
    def begin_clean(str)
      return str
    end

    def clean(str)
      str = begin_clean(str)
      str = end_clean(str)

      return str
    end

    def self.clean_any(obj,cleaners)
      return nil if obj.nil?

      cleaners = Array(cleaners)

      return obj if cleaners.empty?

      if obj.is_a?(Word)
        obj = Word.new(
          kana: clean_any(obj.kana,cleaners),
          kanji: clean_any(obj.kanji,cleaners),
          word: obj
        )
      else # String
        cleaners.each do |cleaner|
          obj = cleaner.clean(obj)
        end
      end

      return obj
    end
  end

  class BasicCleaner < Cleaner
    def end_clean(str)
      # This is very simple, as Splitter will split on punctuation,
      #   and Polisher will remove the leftover punctuation, digits, etc.
      # If this is stricter, then errors will be raised in ArticleScraper's
      #   scrape_dicwin_word() & scrape_ruby_word().

      str = Util.unspace_web_str(str) # Who needs space in Japanese?

      return str
    end
  end

  class BestCleaner < BasicCleaner
  end
end
