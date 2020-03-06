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
  
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class BasicVariator < Variator
    def end_variate(str)
      return [] # No variations; don't return nil
    end
  end
  
  ###
  # Guesses a word's dictionary/plain form (辞書形).
  # 
  # It doesn't work very well,but better than nothing...
  # 
  # @since  0.2.0
  ###
  class DictFormVariator < Variator
    attr_accessor :deinflector
    
    def initialize(*)
      super
      
      @deinflector = JapaneseDeinflector.new()
    end
    
    def end_variate(str)
      guess = @deinflector.deinflect(str)
      
      return [] if guess.length < 1
      return [] if (guess = guess[0])[:weight] < 0.5
      
      return [guess[:word]]
    end
  end
  
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class BestVariator < DictFormVariator
  end
end
