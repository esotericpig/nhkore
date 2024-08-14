# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020-2021 Jonathan Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++


require 'nhkore/word'


module NHKore
  class Polisher
    def begin_polish(str)
      return str
    end

    def polish(str)
      str = begin_polish(str)
      str = end_polish(str)

      return str
    end

    def self.polish_any(obj,polishers)
      return nil if obj.nil?

      polishers = Array(polishers)

      return obj if polishers.empty?

      if obj.is_a?(Word)
        obj = Word.new(
          kana: polish_any(obj.kana,polishers),
          kanji: polish_any(obj.kanji,polishers),
          word: obj
        )
      else # String
        polishers.each do |polisher|
          obj = polisher.polish(obj)
        end
      end

      return obj
    end
  end

  class BasicPolisher < Polisher
    def end_polish(str)
      # Keep Japanese dots in names:
      # - Yunibaasaru・Sutajio・Japan
      # Keep numbers next to kanji/kana, else the below kana won't make sense:
      # - Word { kanji: ２０日, kana: はつか }

      str = str.gsub(/[^[[:alnum:]]・]/,'')

      # Numbers/dots by themselves (without kanji/kana) should be ignored (empty).
      str = '' if str.gsub(/[[[:digit:]]・]+/,'').empty?

      return str
    end
  end

  class BestPolisher < BasicPolisher
  end
end
