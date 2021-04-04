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


require 'nhkore/word'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
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
      return nil if obj.nil?()

      polishers = Array(polishers)

      return obj if polishers.empty?()

      if obj.is_a?(Word)
        obj = Word.new(
          kana: polish_any(obj.kana,polishers),
          kanji: polish_any(obj.kanji,polishers),
          word: obj
        )
      else # String
        polishers.each() do |polisher|
          obj = polisher.polish(obj)
        end
      end

      return obj
    end
  end

  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class BasicPolisher < Polisher
    def end_polish(str)
      # Keep Japanese dots in names:
      # - Yunibaasaru・Sutajio・Japan
      # Keep numbers next to kanji/kana, else the below kana won't make sense:
      # - Word { kanji: ２０日, kana: はつか }

      str = str.gsub(/[^[[:alnum:]]・]/,'')

      # Numbers/dots by themselves (without kanji/kana) should be ignored (empty).
      str = '' if str.gsub(/[[[:digit:]]・]+/,'').empty?()

      return str
    end
  end

  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class BestPolisher < BasicPolisher
  end
end
