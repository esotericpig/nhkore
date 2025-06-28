# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020 Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++

require 'nhkore/util'
require 'nhkore/version'

module NHKore
module CLI
  module GetCmd
    DEFAULT_GET_CHUNK_SIZE = 4 * 1024
    DEFAULT_GET_URL_LENGTH = 11_000_000 # Just a generous estimation used as a fallback; may be outdated.
    GET_URL_FILENAME = 'nhkore-core.zip'
    GET_URL = "https://github.com/esotericpig/nhkore/releases/download/v#{NHKore::VERSION}" \
              "/#{GET_URL_FILENAME}".freeze
    GET_URL_LATEST = 'https://github.com/esotericpig/nhkore/releases/latest/download' \
                     "/#{GET_URL_FILENAME}".freeze

    def build_get_cmd
      app = self

      @get_cmd = @app_cmd.define_command do
        name    'get'
        usage   'get [OPTIONS] [COMMAND]...'
        aliases :g
        summary "Download NHKore's pre-scraped files from the latest release " \
                "(aliases: #{app.color_alias('g')})"

        description(<<-DESC)
          Download NHKore's pre-scraped files from the latest release &
          save to folder: #{Util::CORE_DIR}

          Note: the latest NHK articles may not have been scraped yet.
        DESC

        option :o,:out,'directory to save downloaded files to',
               argument: :required,default: Util::CORE_DIR,
               transform: ->(value) { app.check_empty_opt(:out,value) }
        flag nil,:'show-url','show download URL and exit (for downloading manually)' do |_value,_cmd|
          puts GET_URL
          puts GET_URL_LATEST
          exit
        end

        run do |opts,args,cmd|
          app.refresh_cmd(opts,args,cmd)
          app.run_get_cmd
        end
      end
    end

    def run_get_cmd
      require 'down/net_http'
      require 'tempfile'
      require 'zip'

      build_out_dir(:out,default_dir: Util::CORE_DIR)

      return unless check_out_dir(:out)

      chunk_size = DEFAULT_GET_CHUNK_SIZE
      down = nil
      dry_run = @cmd_opts[:dry_run]
      force = @cmd_opts[:force]
      max_retries = @scraper_kargs[:max_retries]
      max_retries = 3 if max_retries.nil?
      out_dir = @cmd_opts[:out]
      url = GET_URL

      begin
        begin
          start_spin("Opening URL: #{url} ")
          down = Down::NetHttp.open(url,rewindable: false,**@scraper_kargs)
        rescue Down::NotFound
          raise if url == GET_URL_LATEST
          url = GET_URL_LATEST

          stop_spin(ok: false)
          retry
        rescue Down::ConnectionError
          raise if (max_retries -= 1) < 0
          retry
        end

        stop_spin

        return if dry_run

        Tempfile.create(["#{App::NAME}_",'.zip'],binmode: true) do |file|
          puts
          puts "Downloading #{GET_URL_FILENAME} to temp file:"
          puts "> #{file.path}"

          len = down.size
          len = DEFAULT_GET_LENGTH if len.nil? || len < 1
          bar = build_progress_bar('> Downloading',download: true,total: len)

          bar.start

          while !down.eof?
            file.write(down.read(chunk_size))
            bar.advance(chunk_size)
          end

          down.close
          file.close
          bar.finish

          puts
          puts "Extracting #{GET_URL_FILENAME}..."

          # We manually ask the user whether to overwrite each file, so set this to
          # true so that Zip extract() will force overwrites and not raise an error.
          Zip.on_exists_proc = true

          Zip::File.open(file) do |zip_file|
            zip_file.each do |entry|
              if !entry.name_safe?
                raise ZipError,"unsafe entry name[#{entry.name}] in Zip file"
              end

              name = Util.strip_web_str(File.basename(entry.name))

              next if name.empty?

              out_file = File.join(out_dir,name)

              puts "> #{name}"

              if !force && File.exist?(out_file)
                puts
                puts 'Warning: output file already exists!'
                puts "> '#{out_file}'"

                overwrite = @high.agree('Overwrite this file (yes/no)? ')
                puts

                next unless overwrite
              end

              entry.extract(name,destination_directory: out_dir)
            end
          end

          puts
          puts "Extracted #{GET_URL_FILENAME} to directory:"
          puts "> #{out_dir}"
        end
      ensure
        down.close if !down.nil? && !down.closed?
      end
    end
  end
end
end
