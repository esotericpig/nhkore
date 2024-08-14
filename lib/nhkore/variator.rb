# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020-2021 Jonathan Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++


module NHKore
  class Variator
    def begin_variate(str)
      return str
    end

    def variate(str)
      str = begin_variate(str)
      str = end_variate(str)

      return str
    end
  end

  class BasicVariator < Variator
    def end_variate(str)
      return [] # No variations; don't return nil
    end
  end

  ###
  # Guesses a word's dictionary/plain form (辞書形).
  #
  # It doesn't work very well,but better than nothing...
  ###
  class DictFormVariator < Variator
    attr_accessor :deinflector

    def initialize(*)
      require 'set' # Must require manually because JapaneseDeinflector is old
      require 'japanese_deinflector'

      super

      @deinflector = JapaneseDeinflector.new
    end

    def end_variate(str)
      guess = @deinflector.deinflect(str)

      return [] if guess.length < 1
      return [] if (guess = guess[0])[:weight] < 0.5

      return [guess[:word]]
    end
  end

  class BestVariator < DictFormVariator
  end
end
