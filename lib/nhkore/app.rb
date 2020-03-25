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
require 'rainbow'
require 'tty-progressbar'
require 'tty-spinner'

require 'nhkore/error'
require 'nhkore/util'
require 'nhkore/version'

require 'nhkore/cli/bing_cmd'
require 'nhkore/cli/fx_cmd'
require 'nhkore/cli/get_cmd'
require 'nhkore/cli/news_cmd'
require 'nhkore/cli/sift_cmd'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  module CLI
  end
  
  ###
  # For disabling color output.
  # 
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  module CriStringFormatterExt
    def blue(str)
      return str
    end
    
    def bold(str)
      return str
    end
    
    def green(str)
      return str
    end
    
    def red(str)
      return str
    end
    
    def yellow(str)
      return str
    end
  end
  
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class App
    include CLI::BingCmd
    include CLI::FXCmd
    include CLI::GetCmd
    include CLI::NewsCmd
    include CLI::SiftCmd
    
    NAME = 'nhkore'
    
    SPINNER_MSG = '[:spinner] :title:detail...'
    CLASSIC_SPINNER = TTY::Spinner.new(SPINNER_MSG,format: :classic)
    DEFAULT_SPINNER = TTY::Spinner.new(SPINNER_MSG,interval: 5,
      frames: ['〜〜〜','日〜〜','日本〜','日本語'])
    NO_SPINNER = {} # Still outputs status & stores tokens
    NO_SPINNER_MSG = '%{title}%{detail}...'
    
    DEFAULT_SLEEP_TIME = 0.1 # So that sites don't ban us (i.e., think we are human)
    
    attr_accessor :progress_bar
    attr_accessor :scraper_kargs
    attr_accessor :sleep_time
    attr_accessor :spinner
    
    def initialize(args=ARGV)
      super()
      
      @args = args
      @cmd = nil
      @cmd_args = nil
      @cmd_opts = nil
      @high = HighLine.new()
      @rainbow = Rainbow.new()
      @progress_bar = :default # [:default, :classic, :no]
      @scraper_kargs = {}
      @sleep_time = DEFAULT_SLEEP_TIME
      @spinner = DEFAULT_SPINNER
      
      autodetect_color()
      
      build_app_cmd()
      
      build_bing_cmd()
      build_fx_cmd()
      build_get_cmd()
      build_news_cmd()
      build_sift_cmd()
      build_version_cmd()
      
      @app_cmd.add_command Cri::Command.new_basic_help()
    end
    
    def autodetect_color()
      disable = false
      
      if !$stdout.tty?() || ENV['TERM'] == 'dumb'
        disable = true
      elsif !@args.empty?()
        # Kind of hacky, but necessary for Rainbow.
        
        no_color_args = Set['-C','--no-color']
        
        @args.each() do |arg|
          if no_color_args.include?(arg)
            disable = true
            break
          end
          
          break if arg == '--'
        end
      end
      
      if disable
        disable_color()
      else
        @rainbow.enabled = true # Force it in case Rainbow auto-disabled it
      end
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
          app.progress_bar = :classic
          app.spinner = CLASSIC_SPINNER
        end
        flag :n,:'dry-run',<<-EOD
          do a dry run without making changes; do not write to files, create directories, etc.
        EOD
        # Big F because dangerous.
        flag :F,:force,"force overwriting files, creating directories, etc. (don't prompt); dangerous!"
        flag :h,:help,'show this help' do |value,cmd|
          puts cmd.help
          exit
        end
        option :m,:'max-retry',<<-EOD,argument: :required,default: 3 do |value,cmd|
          maximum number of times to retry URLs (-1 or integer >= 0)
        EOD
          value = value.to_i()
          value = nil if value < 0
          
          app.scraper_kargs[:max_retries] = value
        end
        flag :C,:'no-color','disable color output' do |value,cmd|
          app.disable_color()
        end
        flag :X,:'no-fx','disable spinner/progress special effects when running long tasks' do |value,cmd|
          app.progress_bar = :no
          app.spinner = NO_SPINNER
        end
        option :o,:'open-timeout',<<-EOD,argument: :required do |value,cmd|
          seconds for URL open timeouts (-1 or decimal >= 0)
        EOD
          value = value.to_f()
          value = nil if value < 0.0
          
          app.scraper_kargs[:open_timeout] = value
        end
        option :r,:'read-timeout',<<-EOD,argument: :required do |value,cmd|
          seconds for URL read timeouts (-1 or decimal >= 0)
        EOD
          value = value.to_f()
          value = nil if value < 0.0
          
          app.scraper_kargs[:read_timeout] = value
        end
        option :z,:sleep,<<-EOD,argument: :required,default: DEFAULT_SLEEP_TIME do |value,cmd|
          seconds to sleep per scrape (i.e., per page/article) so don't get banned (i.e., fake being human)
        EOD
          app.sleep_time = value.to_f()
          app.sleep_time = 0.0 if app.sleep_time < 0.0
        end
        option :t,:'timeout',<<-EOD,argument: :required do |value,cmd|
          seconds for all URL timeouts: [open, read] (-1 or decimal >= 0)
        EOD
          value = value.to_f()
          value = nil if value < 0.0
          
          app.scraper_kargs[:open_timeout] = value
          app.scraper_kargs[:read_timeout] = value
        end
        # Big V, not small.
        flag :V,:version,'show the version and exit' do |value,cmd|
          app.show_version()
          exit
        end
        
        run do |opts,args,cmd|
          puts cmd.help
        end
      end
    end
    
    def build_dir(opt_key,default_dir: '.')
      # Protect against fat-fingering.
      default_dir = Util.strip_web_str(default_dir)
      dir = Util.strip_web_str(@cmd_opts[opt_key].to_s())
      
      dir = default_dir if dir.empty?()
      
      # '~' will expand to home, etc.
      dir = File.expand_path(dir) unless dir.nil?()
      
      return (@cmd_opts[opt_key] = dir)
    end
    
    def build_file(opt_key,default_dir: '.',default_filename: '')
      # Protect against fat-fingering.
      default_dir = Util.strip_web_str(default_dir)
      default_filename = Util.strip_web_str(default_filename)
      file = Util.strip_web_str(@cmd_opts[opt_key].to_s())
      
      if file.empty?()
        # Do not check default_dir.empty?().
        if default_filename.empty?()
          file = nil # nil is very important for BingScraper.init()!
        else
          file = File.join(default_dir,default_filename)
        end
      else
        # Directory?
        if File.directory?(file) || Util.dir_str?(file)
          file = File.join(file,default_filename)
        # File name only? (no directory)
        elsif Util.filename_str?(file)
          file = File.join(default_dir,file)
        end
        # Else, passed in both: 'directory/file'
      end
      
      # '~' will expand to home, etc.
      file = File.expand_path(file) unless file.nil?()
      
      return (@cmd_opts[opt_key] = file)
    end
    
    def build_in_dir(opt_key,**kargs)
      return build_dir(opt_key,**kargs)
    end
    
    def build_in_file(opt_key,**kargs)
      return build_file(opt_key,**kargs)
    end
    
    def build_out_dir(opt_key,**kargs)
      return build_dir(opt_key,**kargs)
    end
    
    def build_out_file(opt_key,**kargs)
      return build_file(opt_key,**kargs)
    end
    
    def build_progress_bar(title,download: false,total: 100,type: @progress_bar,width: 33,**kargs)
      case type
      when :default,:classic
        msg = "#{title} [:bar] :percent :eta".dup()
        msg << ' :byte_rate/s' if download
        
        return TTY::ProgressBar.new(msg,total: total,width: width,**kargs) do |config|
          if type == :default
            config.incomplete = '.'
            config.complete   = '/'
            config.head       = 'o'
          end
          
          #config.frequency = 5 # For a big download, set this
          config.interval = 1 if download
        end
      end
      
      # :no
      return NoProgressBar.new(title,total: total,**kargs)
    end
    
    def build_version_cmd()
      app = self
      
      @version_cmd = @app_cmd.define_command() do
        name    'version'
        usage   'version [OPTIONS] [COMMAND]...'
        aliases :v
        summary "Show the version and exit (aliases: #{app.color_alias('v')})"
        
        run do |opts,args,cmd|
          app.show_version()
        end
      end
    end
    
    def check_empty_opt(key,value)
      value = Util.strip_web_str(value) unless value.nil?()
      
      if value.nil?() || value.empty?()
        raise CLIError,"option[#{key}] cannot be empty[#{value}]"
      end
      
      return value
    end
    
    def check_in_file(opt_key,empty_ok: false)
      in_file = @cmd_opts[opt_key]
      
      if Util.empty_web_str?(in_file)
        if !empty_ok
          raise CLIError,"empty input path name[#{in_file}] in option[#{opt_key}]"
        end
        
        @cmd_opts[opt_key] = nil # nil is very important for BingScraper.init()!
        
        return true
      end
      
      in_file = Util.strip_web_str(in_file)
      
      if !File.exist?(in_file)
        raise CLIError,"input file[#{in_file}] does not exist for option[#{opt_key}]"
      end
      
      if File.directory?(in_file)
        raise CLIError,"input file[#{in_file}] cannot be a directory for option[#{opt_key}]"
      end
      
      return true
    end
    
    def check_out_dir(opt_key)
      out_dir = @cmd_opts[opt_key]
      
      if Util.empty_web_str?(out_dir)
        raise CLIError,"empty output directory[#{out_dir}] in option[#{opt_key}]"
      end
      
      out_dir = Util.strip_web_str(out_dir)
      
      if File.file?(out_dir)
        raise CLIError,"output directory[#{out_dir}] cannot be a file for option[#{opt_key}]"
      end
      
      if @cmd_opts[:dry_run]
        puts 'No changes written (dry run).'
        puts "> #{out_dir}"
        puts
        
        return true
      end
      
      force = @cmd_opts[:force]
      
      if !force && Dir.exist?(out_dir)
        puts 'Warning: output directory already exists!'
        puts '       : Files inside of this directory may be overwritten!'
        puts "> '#{out_dir}'"
        
        return false unless @high.agree('Is this okay (yes/no)? ')
        puts
      end
      
      if !Dir.exist?(out_dir)
        if !force
          puts 'Output directory does not exist.'
          puts "> '#{out_dir}'"
          
          return false unless @high.agree('Create this directory (yes/no)? ')
        end
        
        FileUtils.mkdir_p(out_dir,verbose: true)
        puts
      end
      
      return true
    end
    
    def check_out_file(opt_key)
      out_file = @cmd_opts[opt_key]
      
      if Util.empty_web_str?(out_file)
        raise CLIError,"empty output path name[#{out_file}] in option[#{opt_key}]"
      end
      
      out_file = Util.strip_web_str(out_file)
      
      if File.directory?(out_file)
        raise CLIError,"output file[#{out_file}] cannot be a directory for option[#{opt_key}]"
      end
      
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
        end
        
        FileUtils.mkdir_p(out_dir,verbose: true)
        puts
      end
      
      return true
    end
    
    def color(str)
      return @rainbow.wrap(str)
    end
    
    def color_alias(str)
      return color(str).green
    end
    
    def disable_color()
      Cri::StringFormatter.prepend(CriStringFormatterExt)
      @rainbow.enabled = false
    end
    
    def refresh_cmd(opts,args,cmd)
      new_opts = {}
      
      # Change symbols with dashes to underscores,
      #   so don't have to type @cmd_opts[:'dry-run'] all the time.
      opts.each() do |key,value|
        key = key.to_s()
        key = key.gsub('-','_')
        key = key.to_sym()
        
        new_opts[key] = value
      end
      
      @cmd = cmd
      @cmd_args = args
      @cmd_opts = new_opts
      
      return self
    end
    
    def run()
      @app_cmd.run(@args)
    end
    
    def show_version()
      puts "#{NAME} v#{VERSION}"
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
  
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class NoProgressBar
    MSG = '%{title}... %{percent}%%'
    PUT_INTERVAL = 100.0 / 6.25
    MAX_PUT_INTERVAL = 100.0 + PUT_INTERVAL + 1.0
    
    def initialize(title,total:,**tokens)
      super()
      
      @tokens = {title: title,total: total}
      
      reset()
      
      @tokens.merge!(tokens)
    end
    
    def reset()
      @tokens[:advance] = 0
      @tokens[:percent] = 0
      @tokens[:progress] = 0
    end
    
    def advance(progress=1)
      total = @tokens[:total]
      progress = @tokens[:progress] + progress
      progress = total if progress > total
      percent = (progress.to_f() / total.to_f() * 100.0).round()
      
      @tokens[:percent] = percent
      @tokens[:progress] = progress
      
      if percent < 99.0
        # Only output at certain intervals.
        advance = @tokens[:advance]
        i = 0.0
        
        while i <= MAX_PUT_INTERVAL
          if advance < i
            break if percent >= i # Output
            return # Don't output
          end
          
          i += PUT_INTERVAL
        end
      end
      
      @tokens[:advance] = percent
      
      puts to_s()
    end
    
    def finish()
      advance(@tokens[:total])
    end
    
    def start()
      puts to_s()
    end
    
    def to_s()
      return MSG % @tokens
    end
  end
end
