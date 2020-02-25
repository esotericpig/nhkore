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


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  module Util
    JST_OFFSET = '+09:00' # Japan Standard Time (JST) time zone offset from UTC
    
    def self.str_empty?(str)
      return str.nil?() || str_unspace(str).empty?()
    end
    
    def self.str_unspace(str)
      return str.gsub(/[[:space:]]+/,'')
    end
  end
end
