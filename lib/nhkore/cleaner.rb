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
  class Cleaner
    def begin_clean(str)
      return str
    end
    
    def clean(str)
      str = begin_clean(str)
      str = end_clean(str)
      
      return str
    end
  end
  
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class BestCleaner < Cleaner
    attr_accessor :form
    
    def initialize(*)
      super
      
      @form = FormCleaner.new()
    end
    
    def end_clean(str)
      str = @form.end_clean(str)
      
      return str
    end
  end
  
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class EmptyCleaner < Cleaner
    def end_clean(str)
      return str
    end
  end
  
  ###
  # Guesses a word's dictionary/plain form (辞書形).
  # It doesn't work very well...
  # 
  # @since  0.2.0
  ###
  class FormCleaner < Cleaner
    attr_accessor :deinflector
    
    def initialize(*)
      super
      
      @deinflector = JapaneseDeinflector.new()
    end
    
    def end_clean(str)
      guess = @deinflector.deinflect(str)
      
      return str if guess.length < 1
      return str if (guess = guess[0])[:weight] < 0.5
      
      return guess[:word]
    end
  end
end
