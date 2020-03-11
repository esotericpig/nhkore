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


require 'cri'
require 'highline'
require 'tty-spinner'

require 'nhkore/error'
require 'nhkore/search_link'
require 'nhkore/search_scraper'
require 'nhkore/util'
require 'nhkore/version'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class App
    NAME = 'nhkore'
    
    CLASSIC_SPINNER = TTY::Spinner.new('[:spinner] :title:extra...')
    DEFAULT_SPINNER = TTY::Spinner.new('[:spinner] :title:extra...',
      frames: ['〜〜〜','日〜〜','日本〜','日本語'],
      interval: 5)
    NO_SPINNER_MSG = "%{title}%{extra}..."
    
    attr_accessor :spinner
    
    def initialize(args=ARGV)
      super()
      
      @args = args
      @cmd = nil
      @cmd_args = nil
      @cmd_opts = nil
      @high = HighLine.new()
      @spinner = DEFAULT_SPINNER
      
      build_app_cmd()
      build_bing_cmd()
      
      @app_cmd.add_command Cri::Command.new_basic_help()
    end
    
    def build_app_cmd()
      app = self
      
      @app_cmd = Cri::Command.define() do
        name    NAME
        usage   "#{NAME} [OPTIONS] [COMMAND]..."
        summary 'NHK News Web (Easy) scraper for Japanese language learners.'
        
        description <<-EOD
          Scrapes NHK News Web (Easy) to create a list of each word and its
          frequency (how many times it was used) for Japanese language learners.
          
          This is similar to a core word/vocabulary list.
        EOD
        
        flag :c,:'classic-spin','use classic spinner effects (in case of no Unicode support) when running long tasks' do |value,cmd|
          app.spinner = CLASSIC_SPINNER
        end
        flag :f,:force,"force overwriting files, creating directories, etc. (don't prompt); dangerous!"
        flag :h,:help,'show this help' do |value,cmd|
          puts cmd.help
          exit
        end
        flag :n,:'dry-run','do a dry run without making changes; do not write to files, create directories, etc.'
        flag :p,:'no-spin','disable spinner effects when running long tasks' do |value,cmd|
          app.spinner = {} # Still outputs status & stores tokens
        end
        # Big V, not small.
        flag :V,:version,'show the version' do |value,cmd|
          puts "#{NAME} v#{VERSION}"
          exit
        end
        
        run do |opts,args,cmd|
          puts cmd.help
        end
      end
    end
    
    def build_bing_cmd()
      app = self
      
      @bing_cmd = @app_cmd.define_command() do
        name    'bing'
        usage   'bing [OPTIONS] [COMMAND]...'
        aliases :b
        summary 'Search bing.com for links to NHK News Web (Easy)'
        
        description <<-EOD
          Search bing.com for links to NHK News Web (Easy) &
          save to folder: #{Util::CORE_DIR}
        EOD
        
        option :i,:in,'file to read instead of URL',argument: :required
        option :o,:out,<<-EOD,argument: :required
          'directory/file' to save links to; if you only specify a directory or a file, it will attach the
          the appropriate default directory/file name
          (defaults: #{SearchLinks::DEFAULT_BING_YASASHII_FILE}, #{SearchLinks::DEFAULT_BING_FUTSUU_FILE})
        EOD
        
        run do |opts,args,cmd|
          puts cmd.help
        end
      end
      
      @bing_easy_cmd = @bing_cmd.define_command() do
        name    'easy'
        usage   'easy [OPTIONS] [COMMAND]...'
        aliases :e,:ez
        summary 'Search for NHK News Web Easy (Yasashii) links'
        
        description <<-EOD
          Search for NHK News Web Easy (Yasashii) links &
          save to file: #{SearchLinks::DEFAULT_BING_YASASHII_FILE}
        EOD
        
        run do |opts,args,cmd|
          app.refresh_cmd(opts,args,cmd)
          app.run_bing_cmd(:yasashii)
        end
      end
      
      @bing_regular_cmd = @bing_cmd.define_command() do
        name    'regular'
        usage   'regular [OPTIONS] [COMMAND]...'
        aliases :r,:reg
        summary 'Search for NHK News Web Regular (Futsuu) links'
        
        description <<-EOD
          Search for NHK News Web Regular (Futsuu) links &
          save to file: #{SearchLinks::DEFAULT_BING_FUTSUU_FILE}
        EOD
        
        run do |opts,args,cmd|
          app.refresh_cmd(opts,args,cmd)
          app.run_bing_cmd(:futsuu)
        end
      end
    end
    
    def build_in_file()
      # Protect against fat-fingering.
      in_file = Util.strip_web_str(@cmd_opts[:in].to_s())
      
      if in_file.empty?()
        in_file = nil # nil is very important for Scraper.init()!
      else
        in_file = File.expand_path(in_file) # '~' will expand to home, etc.
      end
      
      return (@cmd_opts[:in] = in_file)
    end
    
    def build_out_file(default_dir,default_filename)
      # Protect against fat-fingering.
      default_dir = Util.strip_web_str(default_dir)
      default_filename = Util.strip_web_str(default_filename)
      out_file = Util.strip_web_str(@cmd_opts[:out].to_s())
      
      if out_file.empty?()
        out_file = File.join(default_dir,default_filename)
      else
        if File.directory?(out_file) || Util.dir_str?(out_file)
          out_file = File.join(out_file,default_filename)
        # File name only? (no directory)
        elsif Util.filename_str?(out_file)
          out_file = File.join(default_dir,out_file)
        end
        # Else, passed in both: 'directory/file'
      end
      
      # '~' will expand to home, etc.
      out_file = File.expand_path(out_file)
      
      return (@cmd_opts[:out] = out_file)
    end
    
    def check_in_file(empty_ok: true)
      in_file = @cmd_opts[:in]
      
      return empty_ok if in_file.nil?()
      
      if !File.exist?(in_file)
        raise CLIError,"input file[#{in_file}] does not exist"
      end
      
      return true
    end
    
    def check_out_file()
      out_file = @cmd_opts[:out]
      
      if @cmd_opts[:dry_run]
        puts 'No changes written (dry run).'
        puts "> #{out_file}"
        
        return true
      end
      
      force = @cmd_opts[:force]
      out_dir = File.dirname(out_file)
      
      if !force && File.exist?(out_file)
        puts 'Warning: output file already exists!'
        puts "> '#{out_file}'"
        
        return false unless @high.agree('Overwrite this file (yes/no)? ')
      end
      
      if !Dir.exist?(out_dir)
        if !force
          puts 'Output directory does not exist.'
          puts "> '#{out_dir}'"
          
          return false unless @high.agree('Create this directory (yes/no)? ')
        end
        
        FileUtils.mkdir_p(out_dir,verbose: true)
      end
      
      return true
    end
    
    def refresh_cmd(opts,args,cmd)
      more_opts = {}
      
      # Change symbols with dashes to underscores,
      #   so don't have to type @cmd_opts[:'dry-run'] all the time.
      opts.each() do |key,value|
        key = key.to_s()
        
        if key.include?('-')
          key = key.gsub('-','_').to_sym()
          more_opts[key] = value
        end
      end
      
      @cmd = cmd
      @cmd_args = args
      @cmd_opts = opts.merge(more_opts)
      
      return self
    end
    
    def run()
      @app_cmd.run(@args)
    end
    
    def run_bing_cmd(type)
      dry_run = @cmd_opts[:dry_run]
      in_file = build_in_file()
      out_file = nil
      
      case type
      when :futsuu
        out_file = build_out_file(Util::CORE_DIR,SearchLinks::DEFAULT_BING_FUTSUU_FILENAME)
      when :yasashii
        out_file = build_out_file(Util::CORE_DIR,SearchLinks::DEFAULT_BING_YASASHII_FILENAME)
      else
        raise ArgError,"invalid type[#{type}]"
      end
      
      return unless check_in_file()
      return unless check_out_file()
      
      start_spin('Scraping bing.com')
      
      is_file = !in_file.nil?()
      links = nil
      next_page = NextPage.new()
      page_num = 1
      url = in_file # nil will use default URL, else a file
      
      # Load previous links for 'scraped?' vars.
      if File.exist?(out_file)
        links = SearchLinks.load_file(out_file)
      else
        links = SearchLinks.new()
      end
      
      # Do a range to prevent an infinite loop. Ichiman!
      (0..10000).each() do
        scraper = BingScraper.new(type,is_file: is_file,url: url)
        
        next_page = scraper.scrape(links,next_page)
        
        break if next_page.empty?()
        
        page_num += 1
        url = next_page.url
        
        update_spin_extra(" (page=#{page_num}, count=#{next_page.count})")
      end
      
      stop_spin()
      
      if dry_run
        # links.to_s() is too verbose (YAML).
        links.links.each() do |link|
          puts link
        end
      else
        links.save_file(out_file)
      end
    end
    
    def start_spin(title,extra: '')
      if @spinner.is_a?(Hash)
        @spinner[:title] = title
        @spinner[:extra] = extra
        
        puts (NO_SPINNER_MSG % @spinner)
      else
        @spinner.update(title: title,extra: extra)
        @spinner.auto_spin()
      end
    end
    
    def stop_spin()
      if @spinner.is_a?(Hash)
        puts (NO_SPINNER_MSG % @spinner) + ' done!'
      else
        @spinner.reset()
        @spinner.stop('done!')
      end
    end
    
    def update_spin_extra(extra)
      if @spinner.is_a?(Hash)
        @spinner[:extra] = extra
        
        puts (NO_SPINNER_MSG % @spinner)
      else
        @spinner.tokens[:extra] = extra
      end
    end
  end
end
