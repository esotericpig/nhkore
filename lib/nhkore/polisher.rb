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


require 'japanese_deinflector'


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
  end
  
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class BasicPolisher < Polisher
    def end_polish(str)
      return str
    end
  end
  
  ###
  # Guesses a word's dictionary/plain form (辞書形).
  # It doesn't work very well...
  # 
  # @since  0.2.0
  ###
  class DictFormPolisher < Polisher
    attr_accessor :deinflector
    
    def initialize(*)
      super
      
      @deinflector = JapaneseDeinflector.new()
    end
    
    def end_polish(str)
      guess = @deinflector.deinflect(str)
      
      return str if guess.length < 1
      return str if (guess = guess[0])[:weight] < 0.5
      
      return guess[:word]
    end
  end
  
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class BestPolisher < BasicPolisher
  end
end
