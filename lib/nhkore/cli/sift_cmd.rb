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

require 'nhkore/util'


module NHKore
module CLI
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  module SiftCmd
    # Order matters.
    SIFT_DATETIME_FMTS = [
      '%Y-%m-%d %H:%M',
      '%Y-%m-%d %H',
      '%Y-%m-%d',
      '%m-%d',
      '%Y-%m',
      '%d'
    ]
    SIFT_YEARER = -> (year) do
      if year < 100
        # If year <= (2021 -> 21), assume this century.
        if year <= (Util::JST_YEAR % 100)
          # (2021 -> 2000) + year
          (Util::JST_YEAR / 100 * 100) + year
        else
          1900 + year
        end
      else
        year
      end
    end
    
    def build_sift_cmd()
      app = self
      
      @sift_cmd = @app_cmd.define_command() do
        name    'sift'
        usage   'sift [OPTIONS] [COMMAND]...'
        aliases :s
        summary 'Sift NHK News Web (Easy) articles data for the frequency of words'
        
        description <<-EOD
          Sift NHK News Web (Easy) articles data for the frequency of words &
          save to a CSV file in folder: #{Util::CORE_DIR}
        EOD
        
        option :d,:datetime,<<-EOD,argument: :required,transform: -> (value) do
          date time to filter on; examples:
          '2020-7-1 13:10 #2...2020-7-31 11:11 #2' (#2 for 2nd article at this same date time);
          '2020-12' (2020, December 1st-31st);
          '7-4...7-9' (July 4th-9th of Current Year);
          '7-9' (July 9th of Current Year);
          '9' (9th of Current Year & Month)
        EOD
          value = app.parse_sift_datetime(value)
          value
        end
        option :i,:in,<<-EOD,argument: :required,transform: -> (value) do
          file of NHK News Web (Easy) articles data to sift (see '#{App::NAME} news';
          defaults: #{}, #{})
        EOD
          app.check_empty_opt(:in,value)
        end
        option :o,:out,<<-EOD,argument: :required,transform: -> (value) do
          'directory/file' to save sifted data to; if you only specify a directory or a file, it will attach
          the appropriate default directory/file name
          (defaults: #{}, #{})
        EOD
          app.check_empty_opt(:out,value)
        end
        option :t,:title,'title to filter on, where search text only needs to be somewhere in the title',
            argument: :required,transform: -> (value) do
          value = Util.strip_web_str(value).downcase()
          value
        end
        option :u,:url,'URL to filter on, where search text only needs to be somewhere in the URL',
            argument: :required,transform: -> (value) do
          value = Util.strip_web_str(value).downcase()
          value
        end
        
        run do |opts,args,cmd|
          puts cmd.help
        end
      end
      
      @sift_easy_cmd = @sift_cmd.define_command() do
        name    'easy'
        usage   'easy [OPTIONS] [COMMAND]...'
        aliases :e,:ez
        summary 'Sift NHK News Web Easy (Yasashii) articles data'
        
        description <<-EOD
          Sift NHK News Web Easy (Yasashii) articles data for the frequency of words &
          save to CSV file: #{}
        EOD
        
        run do |opts,args,cmd|
          app.refresh_cmd(opts,args,cmd)
          app.run_sift_cmd(:yasashii)
        end
      end
      
      @sift_regular_cmd = @sift_cmd.define_command() do
        name    'regular'
        usage   'regular [OPTIONS] [COMMAND]...'
        aliases :r,:reg
        summary 'Sift NHK News Web Regular (Futsuu) articles data'
        
        description <<-EOD
          Sift NHK News Web Regular (Futsuu) articles data for the frequency of words &
          save to CSV file: #{}
        EOD
        
        run do |opts,args,cmd|
          app.refresh_cmd(opts,args,cmd)
          app.run_sift_cmd(:futsuu)
        end
      end
    end
    
    def parse_sift_datetime(value)
      # This should probably be moved into its own class or into Util...
      
      value = Util.reduce_space(value).strip()
      value = value.split('...')
      
      check_empty_opt(:datetime,nil) if value.empty?() # '' or '...'
      
      value.map!() do |v|
        v = check_empty_opt(:datetime,v) # '12-25...' or '...12-25'
        
        num = v.match(/#\s*(\d+)/)
        num = num[1].to_i() unless num.nil?()
        
        SIFT_DATETIME_FMTS.each_with_index() do |fmt,i|
          begin
            v = Time.strptime(v,fmt,&SIFT_YEARER)
            
            break # No problem
          rescue ArgumentError
            # Out of formats.
            raise if i >= (SIFT_DATETIME_FMTS.length - 1)
          end
        end
        
        [v,num]
      end
      
      # Change a single value [[12-25,nil]] to a range [[12-25,nil],[12-25,nil]] for easier logic.
      value << value.first.dup() if value.length == 1
      
      return value
    end
    
    def run_sift_cmd(type)
      datetime_filter = @cmd_opts[:datetime]
      title_filter = @cmd_opts[:title]
      url_filter = @cmd_opts[:url]
    end
  end
end
end
