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


###
# If you run this script, be aware that it uses the +-F+ force option
# (which overwrites files without prompting).
#
# @author Jonathan Bradley Whited (@esotericpig)
# @since  0.3.2
###

case ARGV[0]
when '-c' # count
  system('nhkore search ez --show-count')
  puts
  puts "Use the first number with the '-a' option."
  exit
when '-a' # articles
  articles = ARGV[1].to_i
  articles = 0 if articles < 0
else
  puts 'Options:'
  puts '  -c          show count to use with -a'
  puts '  -a <int>    number of articles already scraped; execute scraping'
  exit
end

articles_inc = 25
max_errors   = 5 # Exit, for example, if 404 errors repeatedly
max_loop     = 5 # Possible total = articles_inc * max_loop

thread = Thread.new do
  i = 0

  while i < max_loop
    puts "Loop #{i += 1} => #{articles} articles"

    if system("nhkore -F -t 300 -m 10 news ez -s #{articles_inc}")
      articles += articles_inc
    elsif (max_errors -= 1) <= 0
      break
    end

    puts
  end
end

# Ctrl+C
trap('INT') do
  if thread.alive?
    # Try to exit gracefully.
    max_loop = -1
    thread.join(5)

    # Die!
    thread.kill if thread.alive?
  end

  exit
end

thread.join # Run
