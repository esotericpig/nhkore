# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020 Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++

require 'cri'
require 'highline'
require 'rainbow'
require 'set'
require 'tty-spinner'

require 'nhkore/error'
require 'nhkore/util'
require 'nhkore/version'

require 'nhkore/cli/fx_cmd'
require 'nhkore/cli/get_cmd'
require 'nhkore/cli/news_cmd'
require 'nhkore/cli/search_cmd'
require 'nhkore/cli/sift_cmd'

module NHKore
  ###
  # For disabling/enabling color output.
  ###
  module CriColorExt
    @color = true

    def color=(color)
      @color = color
    end

    def color?(_io)
      return @color
    end
  end

  class App
    include CLI::FXCmd
    include CLI::GetCmd
    include CLI::NewsCmd
    include CLI::SearchCmd
    include CLI::SiftCmd

    NAME = 'nhkore'

    DEFAULT_SLEEP_TIME = 0.1 # So that sites don't ban us (i.e., think we are human)

    COLOR_OPTS = %i[c color].freeze
    NO_COLOR_OPTS = %i[C no-color].freeze

    SPINNER_MSG = '[:spinner] :title:detail...'
    CLASSIC_SPINNER = TTY::Spinner.new(SPINNER_MSG,format: :classic)
    DEFAULT_SPINNER = TTY::Spinner.new(SPINNER_MSG,
                                       interval: 5,frames: ['〜〜〜','日〜〜','日本〜','日本語'])
    NO_SPINNER_MSG = '%{title}%{detail}...'

    attr_reader :cmd
    attr_reader :cmd_args
    attr_reader :cmd_opts
    attr_accessor :progress_bar
    attr_accessor :scraper_kargs
    attr_accessor :sleep_time
    attr_accessor :spinner

    def initialize(args = ARGV)
      super()

      @args = args
      @cmd = nil
      @cmd_args = nil
      @cmd_opts = nil
      @high = HighLine.new
      @rainbow = Rainbow.new
      @progress_bar = :default # [:default, :classic, :no]
      @scraper_kargs = {}
      @sleep_time = DEFAULT_SLEEP_TIME
      @spinner = DEFAULT_SPINNER

      autodetect_color

      build_app_cmd

      build_fx_cmd
      build_get_cmd
      build_news_cmd
      build_search_cmd
      build_sift_cmd
      build_version_cmd

      @app_cmd.add_command Cri::Command.new_basic_help
    end

    def autodetect_color
      Cri::Platform.singleton_class.prepend(CriColorExt)

      color = nil # Must be nil, not true/false

      if !@args.empty?
        # Kind of hacky, but necessary for Rainbow.

        color_opts = opts_to_set(COLOR_OPTS)
        no_color_opts = opts_to_set(NO_COLOR_OPTS)

        @args.each do |arg|
          if color_opts.include?(arg)
            color = true
            break
          end

          if no_color_opts.include?(arg)
            color = false
            break
          end

          break if arg == '--'
        end
      end

      if color.nil?
        # - https://no-color.org/
        color = ($stdout.tty? && ENV['TERM'] != 'dumb' && !ENV.key?('NO_COLOR'))
      end

      enable_color(color)
    end

    def build_app_cmd
      app = self

      @app_cmd = Cri::Command.define do
        name    NAME
        usage   "#{NAME} [OPTIONS] [COMMAND]..."
        summary 'NHK News Web (Easy) scraper for Japanese language learners.'

        description <<-DESC
          Scrapes NHK News Web (Easy) to create a list of each word and its
          frequency (how many times it was used) for Japanese language learners.

          This is similar to a core word/vocabulary list.
        DESC

        flag :s,:'classic-fx',<<-DESC do |_value,_cmd|
          use classic spinner/progress special effects (in case of no Unicode support) when running long tasks
        DESC
          app.progress_bar = :classic
          app.spinner = CLASSIC_SPINNER
        end
        flag COLOR_OPTS[0],COLOR_OPTS[1],"force color output (for commands like '| less -R')" do |_value,_cmd|
          app.enable_color(true)
        end
        flag :n,:'dry-run',<<-DESC
          do a dry run without making changes; do not write to files, create directories, etc.
        DESC
        # Big F because dangerous.
        flag :F,:force,"force overwriting files, creating directories, etc. (don't prompt); dangerous!"
        flag :h,:help,'show this help' do |_value,cmd|
          puts cmd.help
          exit
        end
        option :m,:'max-retry',<<-DESC,argument: :required,default: 3 do |value,_cmd|
          maximum number of times to retry URLs (-1 or integer >= 0)
        DESC
          value = value.to_i
          value = nil if value < 0

          app.scraper_kargs[:max_retries] = value
        end
        flag NO_COLOR_OPTS[0],NO_COLOR_OPTS[1],'disable color output' do |_value,_cmd|
          app.enable_color(false)
        end
        flag :X,:'no-fx','disable spinner/progress special effects when running long tasks' do |_value,_cmd|
          app.progress_bar = :no
          app.spinner = {} # Still outputs status & stores tokens
        end
        option :o,:'open-timeout',<<-DESC,argument: :required do |value,_cmd|
          seconds for URL open timeouts (-1 or decimal >= 0)
        DESC
          value = value.to_f
          value = nil if value < 0.0

          app.scraper_kargs[:open_timeout] = value
        end
        option :r,:'read-timeout',<<-DESC,argument: :required do |value,_cmd|
          seconds for URL read timeouts (-1 or decimal >= 0)
        DESC
          value = value.to_f
          value = nil if value < 0.0

          app.scraper_kargs[:read_timeout] = value
        end
        option :z,:sleep,<<-DESC,argument: :required,default: DEFAULT_SLEEP_TIME do |value,_cmd|
          seconds to sleep per scrape (i.e., per page/article) so don't get banned (i.e., fake being human)
        DESC
          app.sleep_time = value.to_f
          app.sleep_time = 0.0 if app.sleep_time < 0.0
        end
        option :t,:timeout,<<-DESC,argument: :required do |value,_cmd|
          seconds for all URL timeouts: [open, read] (-1 or decimal >= 0)
        DESC
          value = value.to_f
          value = nil if value < 0.0

          app.scraper_kargs[:open_timeout] = value
          app.scraper_kargs[:read_timeout] = value
        end
        option :u,:'user-agent',<<-DESC,argument: :required do |value,_cmd|
          HTTP header field 'User-Agent' to use instead of a random one
        DESC
          value = app.check_empty_opt(:'user-agent',value)

          app.scraper_kargs[:header] ||= {}
          app.scraper_kargs[:header]['user-agent'] = value
        end
        flag :v,:version,'show the version and exit' do |_value,_cmd|
          app.show_version
          exit
        end

        run do |_opts,_args,cmd|
          puts cmd.help
        end
      end
    end

    def build_dir(opt_key,default_dir: '.')
      # Protect against fat-fingering.
      default_dir = Util.strip_web_str(default_dir)
      dir = Util.strip_web_str(@cmd_opts[opt_key].to_s)

      dir = default_dir if dir.empty?

      # '~' will expand to home, etc.
      dir = File.expand_path(dir) unless dir.nil?

      return (@cmd_opts[opt_key] = dir)
    end

    def build_file(opt_key,default_dir: '.',default_filename: '')
      # Protect against fat-fingering.
      default_dir = Util.strip_web_str(default_dir)
      default_filename = Util.strip_web_str(default_filename)
      file = Util.strip_web_str(@cmd_opts[opt_key].to_s)

      if file.empty?
        # Do not check `default_dir.empty?()`.
        file = if default_filename.empty?
                 nil # NOTE: nil is very important for BingScraper.init()!
               else
                 File.join(default_dir,default_filename)
               end
      # Directory?
      elsif File.directory?(file) || Util.dir_str?(file)
        file = File.join(file,default_filename)
      # File name only? (no directory)
      elsif Util.filename_str?(file)
        file = File.join(default_dir,file)
      end
      # Else, passed in both: 'directory/file'

      # '~' will expand to home, etc.
      file = File.expand_path(file) unless file.nil?

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
        require 'tty-progressbar'

        msg = "#{title} [:bar] :percent :eta"
        msg << ' :byte_rate/s' if download

        return TTY::ProgressBar.new(msg,total: total,width: width,**kargs) do |config|
          if type == :default
            config.incomplete = '.'
            config.complete   = '/'
            config.head       = 'o'
          end

          # config.frequency = 5 # For a big download, set this
          config.interval = 1 if download
        end
      end

      # :no
      return NoProgressBar.new(title,total: total,**kargs)
    end

    def build_version_cmd
      app = self

      @version_cmd = @app_cmd.define_command do
        name    'version'
        usage   'version [OPTIONS] [COMMAND]...'
        aliases :v
        summary "Show the version and exit (aliases: #{app.color_alias('v')})"

        run do |_opts,_args,_cmd|
          app.show_version
        end
      end
    end

    def check_empty_opt(key,value)
      value = Util.strip_web_str(value) unless value.nil?

      if value.nil? || value.empty?
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

      if !force && Dir.exist?(out_dir) && !Dir.empty?(out_dir)
        puts 'Warning: output directory already exists with files!'
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

    def enable_color(enabled)
      Cri::Platform.color = enabled
      @rainbow.enabled = enabled
    end

    def opts_to_set(ary)
      set = Set.new

      set.add("-#{ary[0]}") unless ary[0].nil?
      set.add("--#{ary[1]}") unless ary[1].nil?

      return set
    end

    def refresh_cmd(opts,args,cmd)
      new_opts = {}

      # Change symbols with dashes to underscores,
      #   so don't have to type @cmd_opts[:'dry-run'] all the time.
      opts.each do |key,value|
        # %s(max-retry) => :max_retry
        key = key.to_s.tr('-','_').to_sym

        new_opts[key] = value
      end

      # For now don't set the default proc, as the original code
      #   did not have this in mind.
      # Specifically, SiftCmd.build_sift_filename() is affected by
      #   this due to relying on @cmd_opts[:ext] to be nil.
      #   It's easy to change this one instance, but I'm not sure
      #   at the moment where else might be affected
      #
      # # Cri has a default proc for default values
      # #   that doesn't store the keys.
      # new_opts.default_proc = proc do |hash,key|
      #   # :max_retry => %s(max-retry)
      #   key = key.to_s.gsub('_','-').to_sym
      #
      #   opts.default_proc.call(hash,key)
      # end

      @cmd = cmd
      @cmd_args = args
      @cmd_opts = new_opts

      return self
    end

    def run
      @app_cmd.run(@args)
    end

    def show_version
      puts "#{NAME} v#{VERSION}"
    end

    def sleep_scraper
      # Do a range to better emulate being a human.
      r = rand(@sleep_time..(@sleep_time + 0.1111))
      s = r.round(3) # Within 1000ms (0.000 - 0.999).

      sleep(s)
    end

    def start_spin(title,detail: '')
      if @spinner.is_a?(Hash)
        @spinner[:detail] = detail
        @spinner[:title] = title

        puts(NO_SPINNER_MSG % @spinner)
      else
        @spinner.update(title: title,detail: detail)
        @spinner.auto_spin
      end
    end

    def stop_spin(ok: true)
      status = ok ? 'done' : 'failed'

      if @spinner.is_a?(Hash)
        puts "#{NO_SPINNER_MSG % @spinner} #{status}!"
      else
        @spinner.reset
        @spinner.stop("#{status}!")
      end
    end

    def update_spin_detail(detail)
      if @spinner.is_a?(Hash)
        @spinner[:detail] = detail

        puts(NO_SPINNER_MSG % @spinner)
      else
        @spinner.tokens[:detail] = detail
      end
    end
  end

  class NoProgressBar
    MSG = '%{title}... %{percent}%%'
    PUT_INTERVAL = 100.0 / 6.25
    MAX_PUT_INTERVAL = 100.0 + PUT_INTERVAL + 1.0

    def initialize(title,total:,**tokens)
      super()

      @tokens = {title: title,total: total}

      reset

      @tokens.merge!(tokens)
    end

    def reset
      @tokens[:advance] = 0
      @tokens[:percent] = 0
      @tokens[:progress] = 0
    end

    def advance(progress = 1)
      total = @tokens[:total]
      progress = @tokens[:progress] + progress
      progress = total if progress > total
      percent = (progress.to_f / total * 100.0).round

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

      puts self
    end

    def finish
      advance(@tokens[:total])
    end

    def start
      puts self
    end

    def to_s
      return MSG % @tokens
    end
  end
end
