# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020-2021 Jonathan Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++

require 'date'
require 'time'

require 'nhkore/datetime_parser'
require 'nhkore/news'
require 'nhkore/sifter'
require 'nhkore/util'

module NHKore
module CLI
  module SiftCmd
    DEFAULT_SIFT_EXT = :csv
    DEFAULT_SIFT_FUTSUU_FILE = "#{Sifter::DEFAULT_FUTSUU_FILE}{search.criteria}{file.ext}".freeze
    DEFAULT_SIFT_YASASHII_FILE = "#{Sifter::DEFAULT_YASASHII_FILE}{search.criteria}{file.ext}".freeze
    SIFT_EXTS = %i[csv htm html json yaml yml].freeze

    attr_accessor :sift_datetime_text
    attr_accessor :sift_search_criteria

    def build_sift_cmd
      app = self

      @sift_datetime_text = nil
      @sift_search_criteria = nil

      @sift_cmd = @app_cmd.define_command do
        name    'sift'
        usage   'sift [OPTIONS] [COMMAND]...'
        aliases :s
        summary 'Sift NHK News Web (Easy) articles data for the frequency of words ' \
                "(aliases: #{app.color_alias('s')})"

        description(<<-DESC)
          Sift NHK News Web (Easy) articles data for the frequency of words &
          save to folder: #{Sifter::DEFAULT_DIR}
        DESC

        option :d,:datetime,<<-DESC,argument: :required,transform: lambda { |value|
          date time to filter on; examples:
          '2020-7-1 13:10...2020-7-31 11:11';
          '2020-12' (2020, December 1st-31st);
          '7-4...7-9' (July 4th-9th of Current Year);
          '7-9' (July 9th of Current Year);
          '9' (9th of Current Year & Month)
        DESC
          app.sift_datetime_text = value # Save the original value for the file name

          value = DatetimeParser.parse_range(value)

          app.check_empty_opt(:datetime,value) if value.nil?

          value
        }
        option :e,:ext,<<-DESC,argument: :required,default: DEFAULT_SIFT_EXT,transform: lambda { |value|
          type of file (extension) to save; valid options: [#{SIFT_EXTS.join(', ')}];
          not needed if you specify a file extension with the '--out' option: '--out sift.html'
        DESC
          value = Util.unspace_web_str(value).downcase.to_sym

          raise CLIError,"invalid ext[#{value}] for option[#{ext}]" unless SIFT_EXTS.include?(value)

          value
        }
        option :i,:in,<<-DESC,argument: :required,transform: lambda { |value|
          file of NHK News Web (Easy) articles data to sift (see '#{App::NAME} news';
          defaults: #{YasashiiNews::DEFAULT_FILE}, #{FutsuuNews::DEFAULT_FILE})
        DESC
          app.check_empty_opt(:in,value)
        }
        flag :D,:'no-defn','do not output the definitions for words (which can be quite long)'
        flag :E,:'no-eng','do not output the English translations for words'
        option :o,:out,<<-DESC,argument: :required,transform: lambda { |value|
          'directory/file' to save sifted data to; if you only specify a directory or a file, it will attach
          the appropriate default directory/file name
          (defaults: #{DEFAULT_SIFT_YASASHII_FILE}, #{DEFAULT_SIFT_FUTSUU_FILE})
        DESC
          app.check_empty_opt(:out,value)
        }
        flag :H,'no-sha256',<<-DESC
          if you used this option with the 'news' command, then you'll also need this option here
          to not fail on "duplicate" articles; see '#{App::NAME} news'
        DESC
        option :t,:title,'title to filter on, where search text only needs to be somewhere in the title',
               argument: :required
        option :u,:url,'URL to filter on, where search text only needs to be somewhere in the URL',
               argument: :required

        run do |_opts,_args,cmd|
          puts cmd.help
        end
      end

      @sift_easy_cmd = @sift_cmd.define_command do
        name    'easy'
        usage   'easy [OPTIONS] [COMMAND]...'
        aliases :e,:ez
        summary "Sift NHK News Web Easy (Yasashii) articles data (aliases: #{app.color_alias('e ez')})"

        description <<-DESC
          Sift NHK News Web Easy (Yasashii) articles data for the frequency of words &
          save to file: #{DEFAULT_SIFT_YASASHII_FILE}
        DESC

        run do |opts,args,cmd|
          app.refresh_cmd(opts,args,cmd)
          app.run_sift_cmd(:yasashii)
        end
      end

      @sift_regular_cmd = @sift_cmd.define_command do
        name    'regular'
        usage   'regular [OPTIONS] [COMMAND]...'
        aliases :r,:reg
        summary "Sift NHK News Web Regular (Futsuu) articles data (aliases: #{app.color_alias('r reg')})"

        description(<<-DESC)
          Sift NHK News Web Regular (Futsuu) articles data for the frequency of words &
          save to file: #{DEFAULT_SIFT_FUTSUU_FILE}
        DESC

        run do |opts,args,cmd|
          app.refresh_cmd(opts,args,cmd)
          app.run_sift_cmd(:futsuu)
        end
      end
    end

    def build_sift_filename(filename)
      @sift_search_criteria = []

      @sift_search_criteria << Util.strip_web_str(@sift_datetime_text.to_s)
      @sift_search_criteria << Util.strip_web_str(@cmd_opts[:title].to_s)
      @sift_search_criteria << Util.strip_web_str(@cmd_opts[:url].to_s)
      @sift_search_criteria.filter! { |sc| !sc.empty? }

      clean_regex = /[^[[:alnum:]]\-_.]+/
      clean_search_criteria = ''.dup

      @sift_search_criteria.each do |sc|
        clean_search_criteria << sc.gsub(clean_regex,'')
      end

      @sift_search_criteria = @sift_search_criteria.empty? ? nil : @sift_search_criteria.join(', ')

      # Limit the file name length.
      #   If length is smaller, [..] still works appropriately.
      clean_search_criteria = clean_search_criteria[0..32]

      clean_search_criteria.prepend('_') unless clean_search_criteria.empty?

      file_ext = @cmd_opts[:ext]

      if file_ext.nil?
        # Try to get from '--out' if it exists.
        if !@cmd_opts[:out].nil?
          file_ext = Util.unspace_web_str(File.extname(@cmd_opts[:out])).downcase
          file_ext = file_ext.sub(/\A\./,'') # Remove '.'; can't be nil for to_sym()
          file_ext = file_ext.to_sym

          file_ext = nil unless SIFT_EXTS.include?(file_ext)
        end

        file_ext = DEFAULT_SIFT_EXT if file_ext.nil?
        @cmd_opts[:ext] = file_ext
      end

      filename = "#{filename}#{clean_search_criteria}.#{file_ext}"

      return filename
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
      no_eng = @cmd_opts[:no_eng]
      no_sha256 = @cmd_opts[:no_sha256]
      out_file = @cmd_opts[:out]
      title_filter = @cmd_opts[:title]
      url_filter = @cmd_opts[:url]

      start_spin("Sifting NHK News Web #{news_name} data")

      news = (type == :yasashii) ?
        YasashiiNews.load_file(in_file,overwrite: no_sha256) :
        FutsuuNews.load_file(in_file,overwrite: no_sha256)

      sifter = Sifter.new(news)

      sifter.filter_by_datetime(datetime_filter) unless datetime_filter.nil?
      sifter.filter_by_title(title_filter) unless title_filter.nil?
      sifter.filter_by_url(url_filter) unless url_filter.nil?
      sifter.ignore(:defn) if no_defn
      sifter.ignore(:eng) if no_eng

      sifter.caption = "NHK News Web #{news_name}".dup

      if !@sift_search_criteria.nil?
        sifter.caption << if %i[htm html].any?(file_ext)
                            " &mdash; #{Util.escape_html(@sift_search_criteria.to_s)}"
                          else
                            " -- #{@sift_search_criteria}"
                          end
      end

      case file_ext
      when :csv
        sifter.put_csv!
      when :htm,:html
        sifter.put_html!
      when :json
        sifter.put_json!
      when :yaml,:yml
        sifter.put_yaml!
      else
        raise ArgumentError,"invalid file ext[#{file_ext}]"
      end

      stop_spin
      puts

      if dry_run
        puts sifter
      else
        start_spin('Saving sifted data to file')

        sifter.save_file(out_file)

        stop_spin
        puts "> #{out_file}"
      end
    end
  end
end
end
