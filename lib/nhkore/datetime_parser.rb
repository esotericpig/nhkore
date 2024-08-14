# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020-2021 Jonathan Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++


require 'attr_bool'
require 'date'
require 'time'

require 'nhkore/util'


module NHKore
  class DatetimeParser
    extend AttrBool::Ext

    # Order matters!
    FMTS = [
      '%Y-%m-%d %H:%M',
      '%Y-%m-%d %H',
      '%Y-%m-%d',
      '%m-%d %H:%M',
      '%Y-%m %H:%M',
      '%m-%d %H',
      '%Y-%m %H',
      '%m-%d',
      '%Y-%m',
      '%d %H:%M',
      '%y %H:%M',
      '%d %H',
      '%Y %H',
      '%H:%M',
      '%d',
      '%Y',
    ].freeze

    def self.guess_year(year)
      if year < 1000
        century = Util::JST_YEAR / 100 * 100 # 2120 -> 2100
        millennium = Util::JST_YEAR / 1000 * 1000 # 2120 -> 2000

        # If year <= 23 (2022 -> 23)...
        if year <= ((Util::JST_YEAR % 100) + 1)
          # Assume this century.
          year = century + year
        elsif year >= 100
          # If (2000 + 150) <= 2201 (if current year is 2200)...
          if (millennium + year) <= (Util::JST_YEAR + 1)
            # Assume this millennium.
            # So if the current year is 2200, and year is 150,
            # then it will be 2000 + 150 = 2150.
          else
            # Assume previous millennium (2000 -> 1000),
            # so year 999 will become 1999.
            millennium -= 1000 if millennium >= 1000
          end

          year = millennium + year
        else
          # Assume previous century (2000 -> 1900).
          century -= 100 if century >= 100
          year = century + year
        end
      end

      return year
    end

    def self.parse_range(value)
      # Do not use unspace_web_str(), want spaces for formats.
      value = Util.strip_web_str(Util.reduce_space(value))
      values = value.split('...',2)

      return nil if values.empty? # For '' or '...'

      # For '2020...' or '...2020'.
      if value.include?('...')
        # values.length is always 2 because of 2 in split() above.

        # For '2020...'.
        if Util.empty_web_str?(values[1])
          values[1] = :infinity
        # For '...2020'.
        elsif Util.empty_web_str?(values[0])
          values[0] = :infinity
        end
      end

      datetimes = [
        DatetimeParser.new, # "From" date time
        DatetimeParser.new, # "To" date time
      ]

      values.each_with_index do |v,i|
        dt = datetimes[i]

        # Minimum/Maximum date time for '2020...' or '...2020'.
        if v == :infinity
          # "From" date time.
          if i == 0
            dt.min!
          # "To" date time.
          else
            dt.max!
          end
        else
          v = Util.strip_web_str(v)

          FMTS.each_with_index do |fmt,j|
            # If don't do this, "%d" values will be parsed using "%d %H".
            # It seems as though strptime() ignores space.
            raise ArgumentError if fmt.include?(' ') && !v.include?(' ')

            # If don't do this, "%y..." values will be parsed using "%d...".
            raise ArgumentError if fmt.start_with?('%d') && v.split(' ')[0].length > 2

            dt.parse!(v,fmt)

            break # No problem; this format worked
          rescue ArgumentError
            # Out of formats.
            raise if j >= (FMTS.length - 1)
          end
        end
      end

      from = datetimes[0]
      to = datetimes[1]

      from.autofill!(:from,to)
      to.autofill!(:to,from)

      return [from.jst_time,to.jst_time]
    end

    attr_accessor :day
    attr_accessor :hour
    attr_accessor :min
    attr_accessor :month
    attr_accessor :sec
    attr_accessor :year

    attr_accessor? :has_day
    attr_accessor? :has_hour
    attr_accessor? :has_min
    attr_accessor? :has_month
    attr_accessor? :has_sec
    attr_accessor? :has_year

    attr_reader? :min_or_max

    def initialize(year=nil,month=nil,day=nil,hour=nil,min=nil,sec=nil)
      super()

      set!(year,month,day,hour,min,sec)

      self.has = false
      @min_or_max = false
    end

    def autofill!(type,other)
      case type
      when :from
        is_from = true
      when :to
        is_from = false
      else
        raise ArgumentError,"invalid type[#{type}]"
      end

      return self if @min_or_max

      has_small = false
      jst_now = Util.jst_now()

      # Must be from smallest to biggest.

      if @has_sec || other.has_sec?
        @sec = other.sec unless @has_sec
        has_small = true
      else
        if has_small
          @sec = jst_now.sec
        else
          @sec = is_from ? 0 : 59
        end
      end

      if @has_min || other.has_min?
        @min = other.min unless @has_min
        has_small = true
      else
        if has_small
          @min = jst_now.min
        else
          @min = is_from ? 0 : 59
        end
      end

      if @has_hour || other.has_hour?
        @hour = other.hour unless @has_hour
        has_small = true
      else
        if has_small
          @hour = jst_now.hour
        else
          @hour = is_from ? 0 : 23
        end
      end

      if @has_day || other.has_day?
        @day = other.day unless @has_day
        has_small = true
      else
        if has_small
          @day = jst_now.day
        else
          @day = is_from ? 1 : :last_day
        end
      end

      if @has_month || other.has_month?
        @month = other.month unless @has_month
        has_small = true
      else
        if has_small
          @month = jst_now.month
        else
          @month = is_from ? 1 : 12
        end
      end

      if @has_year || other.has_year?
        @year = other.year unless @has_year
        has_small = true # rubocop:disable Lint/UselessAssignment
      else
        if has_small
          @year = jst_now.year
        else
          @year = is_from ? Util::MIN_SANE_YEAR : jst_now.year
        end
      end

      # Must be after setting @year & @month.
      if @day == :last_day
        @day = Date.new(@year,@month,-1).day
      end

      return self
    end

    def max!
      @min_or_max = true

      # Ex: 2020-12-31 23:59:59
      return set!(Util::JST_YEAR,12,31,23,59,59)
    end

    def min!
      @min_or_max = true

      # Ex: 1924-01-01 00:00:00
      return set!(Util::MIN_SANE_YEAR,1,1,0,0,0)
    end

    def parse!(value,fmt)
      value = Time.strptime(value,fmt,&self.class.method(:guess_year))

      @has_day = fmt.include?('%d')
      @has_hour = fmt.include?('%H')
      @has_min = fmt.include?('%M')
      @has_month = fmt.include?('%m')
      @has_sec = fmt.include?('%S')
      @has_year = fmt.include?('%Y')

      @day = value.day if @has_day
      @hour = value.hour if @has_hour
      @min = value.min if @has_min
      @month = value.month if @has_month
      @sec = value.sec if @has_sec
      @year = value.year if @has_year

      return self
    end

    def set!(year=nil,month=nil,day=nil,hour=nil,min=nil,sec=nil)
      @year = year
      @month = month
      @day = day
      @hour = hour
      @min = min
      @sec = sec

      return self
    end

    def has=(value)
      @has_day = value
      @has_hour = value
      @has_min = value
      @has_month = value
      @has_sec = value
      @has_year = value
    end

    def jst_time
      return Util.jst_time(time)
    end

    def time
      return Time.new(@year,@month,@day,@hour,@min,@sec)
    end

    def to_s
      return "#{@year}-#{@month}-#{@day} #{@hour}:#{@min}:#{@sec}"
    end
  end
end
