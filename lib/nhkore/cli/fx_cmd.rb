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


module NHKore
module CLI
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  module FXCmd
    def build_fx_cmd()
      app = self
      
      @fx_cmd = @app_cmd.define_command() do
        name    'fx'
        usage   'fx [OPTIONS] [COMMAND]...'
        summary 'Test spinner/progress special effects (for running long tasks)'
        
        description <<-EOD
          Test if the special effects work on your command line:\n
          - #{App::NAME} [-c/-X] fx
        EOD
        
        flag :a,:all,'test all special effects regardless of global options'
        
        run do |opts,args,cmd|
          app.refresh_cmd(opts,args,cmd)
          app.run_fx_cmd()
        end
      end
    end
    
    def run_fx_cmd()
      app_spinner = @spinner
      spinners = nil
      
      if @cmd_opts[:all]
        spinners = {
          default: App::DEFAULT_SPINNER,
          classic: App::CLASSIC_SPINNER,
          no: App::NO_SPINNER
        }
      else
        spinners = {
          user: app_spinner
        }
      end
      
      spinners.each() do |name,spinner|
        @spinner = spinner
        
        start_spin("Testing #{name.to_s().capitalize()} spinner")
        
        1.upto(3) do |i|
          sleep(1.1)
          update_spin_detail(" (#{i}/3)")
        end
        
        stop_spin()
      end
      
      # Reset back to users'.
      @spinner = app_spinner
    end
  end
end
end
