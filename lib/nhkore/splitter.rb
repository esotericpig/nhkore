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


require 'nhkore/util'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
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
  
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class BasicSplitter < Splitter
    def end_split(str)
      return str.split(Util::NORMALIZE_STR_REGEX)
    end
  end
  
  ###
  # @since  0.2.0
  ###
  class BimyouSplitter < Splitter
    def initialize(*)
      require 'bimyou_segmenter'
      
      super
    end
    
    def end_split(str)
      return BimyouSegmenter.segment(str,symbol: false,white_space: false)
    end
  end
  
  ###
  # @since  0.2.0
  ###
  class TinySplitter < Splitter
    attr_accessor :tiny
    
    def initialize(*)
      require 'tiny_segmenter'
      
      super
      
      @tiny = TinySegmenter.new()
    end
    
    def end_split(str)
      return @tiny.segment(str,ignore_punctuation: true)
    end
  end
  
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class BestSplitter < BimyouSplitter
  end
end
