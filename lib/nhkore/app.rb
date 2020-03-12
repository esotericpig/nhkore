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
require 'nhkore/util'
require 'nhkore/version'

require 'nhkore/cli/bing_cmd'
require 'nhkore/cli/fx_cmd'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  module CLI
  end
  
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class App
    include CLI::BingCmd
    include CLI::FXCmd
    
    NAME = 'nhkore'
    
    CLASSIC_SPINNER = TTY::Spinner.new('[:spinner] :title:detail...',format: :classic)
    DEFAULT_SPINNER = TTY::Spinner.new('[:spinner] :title:detail...',
      frames: ['〜〜〜','日〜〜','日本〜','日本語'],
      interval: 5)
    NO_SPINNER = {} # Still outputs status & stores tokens
    NO_SPINNER_MSG = "%{title}%{detail}..."
    
    DEFAULT_SLEEP_TIME = 0.1 # So that sites don't ban us (i.e., think we are human)
    
    attr_accessor :sleep_time
    attr_accessor :spinner
    
    def initialize(args=ARGV)
      super()
      
      @args = args
      @cmd = nil
      @cmd_args = nil
      @cmd_opts = nil
      @high = HighLine.new()
      @sleep_time = DEFAULT_SLEEP_TIME
      @spinner = DEFAULT_SPINNER
      
      build_app_cmd()
      
      build_bing_cmd()
      build_fx_cmd()
      
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
        
        flag :c,:'classic-fx',<<-EOD do |value,cmd|
          use classic spinner/progress special effects (in case of no Unicode support) when running long tasks
        EOD
          app.spinner = CLASSIC_SPINNER
        end
        flag :n,:'dry-run',<<-EOD
          do a dry run without making changes; do not write to files, create directories, etc.
        EOD
        flag :f,:force,"force overwriting files, creating directories, etc. (don't prompt); dangerous!"
        flag :h,:help,'show this help' do |value,cmd|
          puts cmd.help
          exit
        end
        flag :X,:'no-fx','disable spinner/progress special effects when running long tasks' do |value,cmd|
          app.spinner = NO_SPINNER
        end
        option :z,:sleep,<<-EOD,argument: :required,default: DEFAULT_SLEEP_TIME do |value,cmd|
          seconds to sleep per scrape (i.e., per page/article) so don't get banned (i.e., fake being human)
        EOD
          app.sleep_time = value.to_f()
          app.sleep_time = 0.0 if app.sleep_time < 0.0
        end
        # Big V, not small.
        flag :V,:version,'show the version and exit' do |value,cmd|
          puts "#{NAME} v#{VERSION}"
          exit
        end
        
        run do |opts,args,cmd|
          puts cmd.help
        end
      end
    end
    
    def build_in_file(opt_key)
      # Protect against fat-fingering.
      in_file = Util.strip_web_str(@cmd_opts[opt_key].to_s())
      
      if in_file.empty?()
        in_file = nil # nil is very important for Scraper.init()!
      else
        in_file = File.expand_path(in_file) # '~' will expand to home, etc.
      end
      
      return (@cmd_opts[opt_key] = in_file)
    end
    
    def build_out_file(opt_key,default_dir,default_filename)
      # Protect against fat-fingering.
      default_dir = Util.strip_web_str(default_dir)
      default_filename = Util.strip_web_str(default_filename)
      out_file = Util.strip_web_str(@cmd_opts[opt_key].to_s())
      
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
      
      return (@cmd_opts[opt_key] = out_file)
    end
    
    def check_in_file(opt_key,empty_ok: true)
      in_file = @cmd_opts[opt_key]
      
      return empty_ok if in_file.nil?()
      
      if !File.exist?(in_file)
        raise CLIError,"input file[#{in_file}] does not exist"
      end
      
      return true
    end
    
    def check_out_file(opt_key)
      out_file = @cmd_opts[opt_key]
      
      if @cmd_opts[:dry_run]
        puts 'No changes written (dry run).'
        puts "> #{out_file}"
        puts
        
        return true
      end
      
      force = @cmd_opts[:force]
      out_dir = File.dirname(out_file)
      
      if !force && File.exist?(out_file)
        puts 'Warning: output file already exists!'
        puts "> '#{out_file}'"
        
        return false unless @high.agree('Overwrite this file (yes/no)? ')
        puts
      end
      
      if !Dir.exist?(out_dir)
        if !force
          puts 'Output directory does not exist.'
          puts "> '#{out_dir}'"
          
          return false unless @high.agree('Create this directory (yes/no)? ')
          puts
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
    
    def sleep_scraper()
      sleep(@sleep_time)
    end
    
    def start_spin(title,detail: '')
      if @spinner.is_a?(Hash)
        @spinner[:detail] = detail
        @spinner[:title] = title
        
        puts (NO_SPINNER_MSG % @spinner)
      else
        @spinner.update(title: title,detail: detail)
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
    
    def update_spin_detail(detail)
      if @spinner.is_a?(Hash)
        @spinner[:detail] = detail
        
        puts (NO_SPINNER_MSG % @spinner)
      else
        @spinner.tokens[:detail] = detail
      end
    end
  end
end
