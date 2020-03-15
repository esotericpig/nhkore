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


require 'nhkore/news'
require 'nhkore/search_link'
require 'nhkore/util'


module NHKore
module CLI
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  module NewsCmd
    def build_news_cmd()
      app = self
      
      @news_cmd = @app_cmd.define_command() do
        name    'news'
        usage   'news [OPTIONS] [COMMAND]...'
        aliases :n
        summary 'Scrape NHK News Web (Easy) articles'
        
        description <<-EOD
          Scrape NHK News Web (Easy) articles &
          save to folder: #{Util::CORE_DIR}
        EOD
        
        option :i,:in,<<-EOD,argument: :required do |value,cmd|
          HTML file of NHK article to read instead of URL (for offline testing and/or slow internet;
          see '--no-dict' option)
        EOD
          app.check_empty_opt(:in,value)
        end
        option :k,:like,<<-EOD,argument: :required
          text to fuzzy search links for; for example, "--like '00123'" will only scrape links containing
          text '00123' -- like '*00123*'
        EOD
        option :l,:links,<<-EOD,argument: :required do |value,cmd|
          'directory/file' of article links (from a Search Engine) to scrape (see '#{App::NAME} bing';
          defaults: #{SearchLinks::DEFAULT_BING_YASASHII_FILE}, #{SearchLinks::DEFAULT_BING_FUTSUU_FILE})
        EOD
          app.check_empty_opt(:links,value)
        end
        flag :D,:'no-dict',<<-EOD
          do not try to parse the dictionary files for the articles; useful in case of errors trying to load
          the dictionaries (or testing offline)
        EOD
        option :o,:out,<<-EOD,argument: :required do |value,cmd|
          'directory/file' to save NHK words to; if you only specify a directory or a file, it will attach
          the appropriate default directory/file name
          (defaults: #{YasashiiNews::DEFAULT_FILE}, #{FutsuuNews::DEFAULT_FILE})
        EOD
          app.check_empty_opt(:out,value)
        end
        option nil,:'show-dict',<<-EOD
          show the dictionary URL and contents for the first article and exit;
          useful for debugging dictionary errors (see '--no-dict' option)
        EOD
        option :u,:url,<<-EOD,argument: :required do |value,cmd|
          URL of NHK article to scrape, instead of article links file (see '--links' option)
        EOD
          app.check_empty_opt(:url,value)
        end
        
        run do |opts,args,cmd|
          puts cmd.help
        end
      end
      
      @news_easy_cmd = @news_cmd.define_command() do
        name    'easy'
        usage   'easy [OPTIONS] [COMMAND]...'
        aliases :e,:ez
        summary 'Scrape NHK News Web Easy (Yasashii) articles'
        
        description <<-EOD
          Search for NHK News Web Easy (Yasashii) links &
          save to file: #{YasashiiNews::DEFAULT_FILE}
        EOD
        
        run do |opts,args,cmd|
          app.refresh_cmd(opts,args,cmd)
          app.run_news_cmd(:yasashii)
        end
      end
      
      @news_regular_cmd = @news_cmd.define_command() do
        name    'regular'
        usage   'regular [OPTIONS] [COMMAND]...'
        aliases :r,:reg
        summary 'Scrape NHK News Web Regular (Futsuu) articles'
        
        description <<-EOD
          Search for NHK News Web Regular (Futsuu) links &
          save to file: #{FutsuuNews::DEFAULT_FILE}
        EOD
        
        run do |opts,args,cmd|
          app.refresh_cmd(opts,args,cmd)
          app.run_news_cmd(:futsuu)
        end
      end
    end
    
    # TODO: if dry-run, if X > 1, then just output header (no words)
    # TODO: if already have in hash, if https, replace SearchLinks & News.articles w/ https one
    def run_news_cmd(type)
      build_in_file(:in)
      
      case type
      when :futsuu
        build_in_file(:links,default_dir: Util::CORE_DIR,default_filename: SearchLinks::DEFAULT_BING_FUTSUU_FILENAME)
        build_out_file(:out,default_dir: Util::CORE_DIR,default_filename: FutsuuNews::DEFAULT_FILENAME)
      when :yasashii
        build_in_file(:links,default_dir: Util::CORE_DIR,default_filename: SearchLinks::DEFAULT_BING_YASASHII_FILENAME)
        build_out_file(:out,default_dir: Util::CORE_DIR,default_filename: YasashiiNews::DEFAULT_FILENAME)
      else
        raise ArgumentError,"invalid type[#{type}]"
      end
      
      return unless check_in_file(:in,empty_ok: true)
      return unless check_in_file(:links,empty_ok: true)
      return unless check_out_file(:out)
      
      dry_run = @cmd_opts[:dry_run]
      in_file = @cmd_opts[:in]
      links_file = @cmd_opts[:links]
      out_file = @cmd_opts[:out]
      
      # TODO: if links file is nil & --url/--in are nil, then error
      
      puts "in:    #{in_file}"
      puts "links: #{links_file}"
      puts "out:   #{out_file}"
    end
  end
end
end
