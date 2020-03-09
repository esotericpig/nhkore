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


require 'time'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  module Util
    CORE_DIR = 'core'
    WEB_DIR = 'web'
    
    JST_OFFSET = '+09:00' # Japan Standard Time (JST) time zone offset from UTC
    JST_OFFSET_HOUR = 9
    JST_OFFSET_MIN = 0
    
    HIRAGANA_REGEX = /\p{Hiragana}/
    JPN_SPACE = "\u3000" # Must be double-quoted for escape chars
    KANJI_REGEX = /\p{Han}/ # Han probably stands for Hanzi?
    KATAKANA_REGEX = /\p{Katakana}/
    NORMALIZE_STR_REGEX = /[^[[:alpha:]]]+/
    STRIP_WEB_STR_REGEX = /(\A[[:space:]]+)|([[:space:]]+\z)/
    WEB_SPACES_REGEX = /[[:space:]]+/
    
    def self.jst_now()
      now = Time.now().getutc()
      
      now += JST_OFFSET_HOUR * 60 * 60
      now += JST_OFFSET_MIN * 60
      
      now = Time.new(now.year,now.month,now.day,now.hour,now.min,now.sec,JST_OFFSET)
      
      return now
    end
    
    JST_NOW = jst_now()
    JST_YEAR = JST_NOW.year
    MAX_SANE_YEAR = JST_YEAR + 1 # +1 Justin Case for time zone differences at the end of the year
    
    def self.empty_web_str?(str)
      return str.nil?() || strip_web_str(str).empty?()
    end
    
    def self.hiragana?(str)
      return HIRAGANA_REGEX =~ str
    end
    
    def self.kanji?(str)
      return KANJI_REGEX =~ str
    end
    
    def self.katakana?(str)
      return KATAKANA_REGEX =~ str
    end
    
    def self.normalize_str(str)
      return str.gsub(NORMALIZE_STR_REGEX,'')
    end
    
    def self.reduce_jpn_space(str)
      # Do not strip; use a Japanese space
      return str.gsub(WEB_SPACES_REGEX,JPN_SPACE)
    end
    
    def self.sane_year?(year)
      # NHK was founded in 1924/25.
      # - https://www.nhk.or.jp/bunken/english/about/history.html
      # - https://en.wikipedia.org/wiki/NHK
      # However, when was the website first created?
      return year >= 1924 && year <= MAX_SANE_YEAR
    end
    
    # String's normal strip() method doesn't work with special Unicode/HTML white space.
    def self.strip_web_str(str)
      # After testing with Benchmark, this is slower than one regex.
      #str = str.gsub(/\A[[:space:]]+/,'')
      #str = str.gsub(/[[:space:]]+\z/,'')
      
      str = str.gsub(STRIP_WEB_STR_REGEX,'')
      
      return str
    end
    
    def self.unspace_web_str(str)
      return str.gsub(WEB_SPACES_REGEX,'')
    end
  end
end
