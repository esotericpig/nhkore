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


require 'down/net_http'
require 'tempfile'
require 'zip'

require 'nhkore/util'


module NHKore
module CLI
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  module GetCmd
    DEFAULT_GET_CHUNK_SIZE = 4 * 1024
    DEFAULT_GET_URL_LENGTH = 5_000_000 # Just a generous estimation used as a fallback; may be outdated
    GET_URL_FILENAME = 'nhkore-core.zip'
    GET_URL = "https://github.com/esotericpig/nhkore/releases/latest/download/#{GET_URL_FILENAME}"
    
    def build_get_cmd()
      app = self
      
      @get_cmd = @app_cmd.define_command() do
        name    'get'
        usage   'get [OPTIONS] [COMMAND]...'
        aliases :g
        summary "Download NHKore's pre-scraped files from the latest release (aliases: #{app.color_alias('g')})"
        
        description <<-EOD
          Download NHKore's pre-scraped files from the latest release &
          save to folder: #{Util::CORE_DIR}
          
          Note: the latest NHK articles may not have been scraped yet.
        EOD
        
        option :o,:out,'directory to save downloaded files to',argument: :required,default: Util::CORE_DIR,
          transform: -> (value) do
          app.check_empty_opt(:out,value)
        end
        flag nil,:'show-url','show download URL and exit (for downloading manually)' do |value,cmd|
          puts GET_URL
          exit
        end
        
        run do |opts,args,cmd|
          app.refresh_cmd(opts,args,cmd)
          app.run_get_cmd()
        end
      end
    end
    
    def run_get_cmd()
      build_out_dir(:out,default_dir: Util::CORE_DIR)
      
      return unless check_out_dir(:out)
      
      chunk_size = DEFAULT_GET_CHUNK_SIZE
      down = nil
      dry_run = @cmd_opts[:dry_run]
      force = @cmd_opts[:force]
      max_retries = @scraper_kargs[:max_retries]
      max_retries = 3 if max_retries.nil?()
      out_dir = @cmd_opts[:out]
      
      begin
        start_spin('Opening URL')
        
        begin
          down = Down::NetHttp.open(GET_URL,rewindable: false,**@scraper_kargs)
        rescue Down::ConnectionError
          raise if (max_retries -= 1) < 0
          retry
        end
        
        stop_spin()
        
        return if dry_run
        
        Tempfile.create([App::NAME,'.zip'],binmode: true) do |file|
          puts
          puts 'Downloading to temp file:'
          puts "> #{file.path}"
          puts
          
          len = down.size
          len = DEFAULT_GET_LENGTH if len.nil?()
          bar = build_progress_bar("Downloading #{GET_URL_FILENAME}",download: true,total: len)
          
          bar.start()
          
          while !down.eof?()
            file.write(down.read(chunk_size))
            bar.advance(chunk_size)
          end
          
          down.close()
          file.close()
          bar.finish()
          
          start_spin("Extracting #{GET_URL_FILENAME}")
          
          Zip.on_exists_proc = force # true will force overwriting files on extract()
          
          Zip::File.open(file) do |zip_file|
            zip_file.each() do |entry|
              if !entry.name_safe?()
                raise ZipError,"unsafe entry name[#{entry.name}] in Zip file"
              end
              
              name = File.basename(entry.name)
              
              update_spin_detail(" (file=#{name})")
              
              entry.extract(File.join(out_dir,name))
            end
          end
          
          stop_spin()
          puts
          
          puts "Extracted #{GET_URL_FILENAME} to directory:"
          puts "> #{out_dir}"
        end
      ensure
        down.close() if !down.nil?() && !down.closed?()
      end
    end
  end
end
end
