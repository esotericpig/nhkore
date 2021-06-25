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


require 'nhkore/util'
require 'nhkore/word'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
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

  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
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

  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class BestCleaner < BasicCleaner
  end
end
