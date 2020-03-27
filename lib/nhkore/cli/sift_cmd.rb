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


require 'date'
require 'time'

require 'nhkore/news'
require 'nhkore/sifter'
require 'nhkore/util'


module NHKore
module CLI
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  module SiftCmd
    DEFAULT_SIFT_EXT = :csv
    DEFAULT_SIFT_FUTSUU_FILE = "#{Sifter::DEFAULT_FUTSUU_FILE}{search.criteria}{file.ext}"
    DEFAULT_SIFT_YASASHII_FILE = "#{Sifter::DEFAULT_YASASHII_FILE}{search.criteria}{file.ext}"
    SIFT_EXTS = [:csv,:htm,:html,:yaml,:yml]
    
    # Order matters.
    SIFT_DATETIME_FMTS = [
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
      '%Y'
    ]
    SIFT_YEARER = -> (year) do
      if year < 100
        # 2021 -> 2000.
        millennium = Util::JST_YEAR / 100 * 100
        
        # If year <= (2021 -> 21), assume this century.
        if year <= (Util::JST_YEAR % 100)
          millennium + year
        else
          # Assume previous century (2000 -> 1900).
          (millennium - 100) + year
        end
      else
        year
      end
    end
    
    attr_accessor :sift_datetime_text
    attr_accessor :sift_search_criteria
    
    def build_sift_cmd()
      app = self
      
      @sift_datetime_text = nil
      @sift_search_criteria = nil
      
      @sift_cmd = @app_cmd.define_command() do
        name    'sift'
        usage   'sift [OPTIONS] [COMMAND]...'
        aliases :s
        summary "Sift NHK News Web (Easy) articles data for the frequency of words (aliases: #{app.color_alias('s')})"
        
        description <<-EOD
          Sift NHK News Web (Easy) articles data for the frequency of words &
          save to folder: #{Sifter::DEFAULT_DIR}
        EOD
        
        option :d,:datetime,<<-EOD,argument: :required,transform: -> (value) do
          date time to filter on; examples:
          '2020-7-1 13:10...2020-7-31 11:11';
          '2020-12' (2020, December 1st-31st);
          '7-4...7-9' (July 4th-9th of Current Year);
          '7-9' (July 9th of Current Year);
          '9' (9th of Current Year & Month)
        EOD
          app.sift_datetime_text = value # Save the original value for the file name
          value = app.parse_sift_datetime(value)
          value
        end
        option :e,:ext,<<-EOD,argument: :required,default: DEFAULT_SIFT_EXT,transform: -> (value) do
          type of file (extension) to save; valid options: [#{SIFT_EXTS.join(', ')}];
          not needed if you specify a file extension with the '--out' option: '--out sift.html'
        EOD
          value = Util.unspace_web_str(value).downcase().to_sym()
          
          raise CLIError,"invalid ext[#{value}] for option[#{ext}]" unless SIFT_EXTS.include?(value)
          
          value
        end
        option :i,:in,<<-EOD,argument: :required,transform: -> (value) do
          file of NHK News Web (Easy) articles data to sift (see '#{App::NAME} news';
          defaults: #{YasashiiNews::DEFAULT_FILE}, #{FutsuuNews::DEFAULT_FILE})
        EOD
          app.check_empty_opt(:in,value)
        end
        flag :D,:'no-defn','do not output the definitions for words (which can be quite long)'
        option :o,:out,<<-EOD,argument: :required,transform: -> (value) do
          'directory/file' to save sifted data to; if you only specify a directory or a file, it will attach
          the appropriate default directory/file name
          (defaults: #{DEFAULT_SIFT_YASASHII_FILE}, #{DEFAULT_SIFT_FUTSUU_FILE})
        EOD
          app.check_empty_opt(:out,value)
        end
        option :t,:title,'title to filter on, where search text only needs to be somewhere in the title',
          argument: :required
        option :u,:url,'URL to filter on, where search text only needs to be somewhere in the URL',
          argument: :required
        
        run do |opts,args,cmd|
          puts cmd.help
        end
      end
      
      @sift_easy_cmd = @sift_cmd.define_command() do
        name    'easy'
        usage   'easy [OPTIONS] [COMMAND]...'
        aliases :e,:ez
        summary "Sift NHK News Web Easy (Yasashii) articles data (aliases: #{app.color_alias('e ez')})"
        
        description <<-EOD
          Sift NHK News Web Easy (Yasashii) articles data for the frequency of words &
          save to file: #{DEFAULT_SIFT_YASASHII_FILE}
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
        summary "Sift NHK News Web Regular (Futsuu) articles data (aliases: #{app.color_alias('r reg')})"
        
        description <<-EOD
          Sift NHK News Web Regular (Futsuu) articles data for the frequency of words &
          save to file: #{DEFAULT_SIFT_FUTSUU_FILE}
        EOD
        
        run do |opts,args,cmd|
          app.refresh_cmd(opts,args,cmd)
          app.run_sift_cmd(:futsuu)
        end
      end
    end
    
    def build_sift_filename(filename)
      @sift_search_criteria = []
      
      @sift_search_criteria << Util.strip_web_str(@sift_datetime_text.to_s())
      @sift_search_criteria << Util.strip_web_str(@cmd_opts[:title].to_s())
      @sift_search_criteria << Util.strip_web_str(@cmd_opts[:url].to_s())
      @sift_search_criteria.filter!() {|sc| !sc.empty?()}
      
      clean_regex = /[^[[:alnum:]]\-_\.]+/
      clean_search_criteria = ''.dup()
      
      @sift_search_criteria.each() do |sc|
        clean_search_criteria << sc.gsub(clean_regex,'')
      end
      
      @sift_search_criteria = @sift_search_criteria.empty?() ? nil : @sift_search_criteria.join(', ')
      
      # Limit the file name length.
      #   If length is smaller, [..] still works appropriately.
      clean_search_criteria = clean_search_criteria[0..32]
      
      clean_search_criteria.prepend('_') unless clean_search_criteria.empty?()
      
      file_ext = @cmd_opts[:ext]
      
      if file_ext.nil?()
        # Try to get from '--out' if it exists.
        if !@cmd_opts[:out].nil?()
          file_ext = Util.unspace_web_str(File.extname(@cmd_opts[:out])).downcase()
          file_ext = file_ext.sub(/\A\./,'') # Remove '.'; can't be nil for to_sym()
          file_ext = file_ext.to_sym()
          
          file_ext = nil unless SIFT_EXTS.include?(file_ext)
        end
        
        file_ext = DEFAULT_SIFT_EXT if file_ext.nil?()
        @cmd_opts[:ext] = file_ext
      end
      
      filename = "#{filename}#{clean_search_criteria}.#{file_ext}"
      
      return filename
    end
    
    # TODO: This should probably be moved into its own class, into Util, or into Sifter?
    def parse_sift_datetime(value)
      value = Util.reduce_space(value).strip() # Don't use unspace_web_str(), want spaces for formats
      value = value.split('...',2)
      
      check_empty_opt(:datetime,nil) if value.empty?() # For ''
      
      # Make a "to" and a "from" date time range.
      value << value[0].dup() if value.length == 1
      
      to_day = nil
      to_hour = 23
      to_minute = 59
      to_month = 12
      to_year = Util::MAX_SANE_YEAR
      
      value.each_with_index() do |v,i|
        v = check_empty_opt(:datetime,v) # For '...', '12-25...', or '...12-25'
        
        has_day = false
        has_hour = false
        has_minute = false
        has_month = false
        has_year = false
        
        SIFT_DATETIME_FMTS.each_with_index() do |fmt,i|
          begin
            # If don't do this, "%d" values will be parsed using "%d %H".
            #   It seems as though strptime() ignores space.
            raise ArgumentError if !v.include?(' ') && fmt.include?(' ')
            
            # If don't do this, "%y" values will be parsed using "%d".
            raise ArgumentError if fmt == '%d' && v.length > 2
            
            v = Time.strptime(v,fmt,&SIFT_YEARER)
            
            has_day = fmt.include?('%d')
            has_hour = fmt.include?('%H')
            has_minute = fmt.include?('%M')
            has_month = fmt.include?('%m')
            has_year = fmt.include?('%Y')
            
            break # No problem; this format worked
          rescue ArgumentError
            # Out of formats.
            raise if i >= (SIFT_DATETIME_FMTS.length - 1)
          end
        end
        
        # "From" date time.
        if i == 0
          # Set these so that "2012-7-4...7-9" will use the appropriate year
          #   of "2012" for "7-9".
          to_day = v.day if has_day
          to_hour = v.hour if has_hour
          to_minute = v.min if has_minute
          to_month = v.month if has_month
          to_year = v.year if has_year
          
          v = Time.new(
            has_year ? v.year : Util::MIN_SANE_YEAR,
            has_month ? v.month : 1,
            has_day ? v.day : 1,
            has_hour ? v.hour : 0,
            has_minute ? v.min : 0
          )
        # "To" date time.
        else
          to_hour = v.hour if has_hour
          to_minute = v.min if has_minute
          to_month = v.month if has_month
          to_year = v.year if has_year
          
          if has_day
            to_day = v.day
          # Nothing passed from the "from" date time?
          elsif to_day.nil?()
            # Last day of month.
            to_day = Date.new(to_year,to_month,-1).day
          end
          
          v = Time.new(to_year,to_month,to_day,to_hour,to_minute)
        end
        
        value[i] = v
      end
      
      return value
    end
    
    def run_sift_cmd(type)
      news_name = nil
      
      case type
      when :futsuu
        build_in_file(:in,default_dir: News::DEFAULT_DIR,default_filename: FutsuuNews::DEFAULT_FILENAME)
        build_out_file(:out,default_dir: Sifter::DEFAULT_DIR,
          default_filename: build_sift_filename(Sifter::DEFAULT_FUTSUU_FILENAME))
        
        news_name = 'Regular'
      when :yasashii
        build_in_file(:in,default_dir: News::DEFAULT_DIR,default_filename: YasashiiNews::DEFAULT_FILENAME)
        build_out_file(:out,default_dir: Sifter::DEFAULT_DIR,
          default_filename: build_sift_filename(Sifter::DEFAULT_YASASHII_FILENAME))
        
        news_name = 'Easy'
      else
        raise ArgumentError,"invalid type[#{type}]"
      end
      
      return unless check_in_file(:in,empty_ok: false)
      return unless check_out_file(:out)
      
      datetime_filter = @cmd_opts[:datetime]
      dry_run = @cmd_opts[:dry_run]
      file_ext = @cmd_opts[:ext]
      in_file = @cmd_opts[:in]
      no_defn = @cmd_opts[:no_defn]
      out_file = @cmd_opts[:out]
      title_filter = @cmd_opts[:title]
      url_filter = @cmd_opts[:url]
      
      start_spin("Sifting NHK News Web #{news_name} data")
      
      news = (type == :yasashii) ? YasashiiNews.load_file(in_file) : FutsuuNews.load_file(in_file)
      
      sifter = Sifter.new(news)
      
      sifter.filter_by_datetime(datetime_filter) unless datetime_filter.nil?()
      sifter.filter_by_title(title_filter) unless title_filter.nil?()
      sifter.filter_by_url(url_filter) unless url_filter.nil?()
      sifter.ignore(:defn) if no_defn
      
      sifter.caption = "NHK News Web #{news_name}".dup()
      
      if !@sift_search_criteria.nil?()
        if [:htm,:html].any?(file_ext)
          sifter.caption << " &mdash; #{Util.escape_html(@sift_search_criteria.to_s())}"
        else
          sifter.caption << " -- #{@sift_search_criteria}"
        end
      end
      
      case file_ext
      when :csv
        sifter.put_csv!()
      when :htm,:html
        sifter.put_html!()
      when :yaml,:yml
        sifter.put_yaml!()
      else
        raise ArgumentError,"invalid file ext[#{file_ext}]"
      end
      
      stop_spin()
      puts
      
      if dry_run
        puts sifter.to_s()
      else
        puts 'Saved sifted data to file:'
        puts "> #{out_file}"
        
        sifter.save_file(out_file)
      end
    end
  end
end
end
