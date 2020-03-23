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


require 'nhkore/util'


module NHKore
module CLI
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  module GetCmd
    def build_get_cmd()
      app = self
      
      @get_cmd = @app_cmd.define_command() do
        name    'get'
        usage   'get [OPTIONS] [COMMAND]...'
        aliases :g
        summary "Download NHKore's pre-scraped files from the latest release (aliases: #{app.color_alias('g')})"
        
        description <<-EOD
          Download NHKore's pre-scrapped files from the latest release &
          save to folder: #{Util::CORE_DIR}
          
          Note: the latest NHK articles may not have been scraped yet.
        EOD
        
        option :o,:out,'directory to save downloaded files to',argument: :required,default: Util::CORE_DIR,
            transform: -> (value) do
          app.check_empty_opt(:out,value)
        end
        flag nil,:'show-url','show download URL and exit (for downloading manually)' do |value,cmd|
          exit
        end
        
        run do |opts,args,cmd|
          app.refresh_cmd(opts,args,cmd)
          app.run_get_cmd()
        end
      end
    end
    
    def run_get_cmd()
      # TODO: if core/ exists, warn that files may be deleted & do ask() for confirm
    end
  end
end
end
