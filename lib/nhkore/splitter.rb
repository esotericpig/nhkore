# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020-2021 Jonathan Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++


require 'nhkore/util'


module NHKore
  class Splitter
    def begin_split(str)
      return str
    end

    def split(str)
      str = begin_split(str)
      str = end_split(str)

      return str
    end
  end

  class BasicSplitter < Splitter
    def end_split(str)
      return str.split(Util::NORMALIZE_STR_REGEX)
    end
  end

  class BimyouSplitter < Splitter
    def initialize(*)
      require 'bimyou_segmenter'

      super
    end

    def end_split(str)
      return BimyouSegmenter.segment(str,symbol: false,white_space: false)
    end
  end

  class TinySplitter < Splitter
    attr_accessor :tiny

    def initialize(*)
      require 'tiny_segmenter'

      super

      @tiny = TinySegmenter.new
    end

    def end_split(str)
      return @tiny.segment(str,ignore_punctuation: true)
    end
  end

  class BestSplitter < BimyouSplitter
  end
end
