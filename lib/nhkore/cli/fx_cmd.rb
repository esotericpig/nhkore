# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020 Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++

module NHKore
module CLI
  module FXCmd
    def build_fx_cmd
      app = self

      @fx_cmd = @app_cmd.define_command do
        name    'fx'
        usage   'fx [OPTIONS] [COMMAND]...'
        summary 'Test spinner/progress special effects (for running long tasks)'

        description <<-DESC
          Test if the special effects work on your command line:\n
          - #{App::NAME} [-s/-X] fx
        DESC

        flag :a,:all,'test all special effects regardless of global options'

        run do |opts,args,cmd|
          app.refresh_cmd(opts,args,cmd)
          app.run_fx_cmd
        end
      end
    end

    def run_fx_cmd
      test_fx_progress_bar
      test_fx_spinner
    end

    def test_fx_progress_bar
      bars = if @cmd_opts[:all]
               {default: :default,classic: :classic,no: :no}
             else
               {user: @progress_bar}
             end

      bars.each do |name,bar|
        name = name.to_s.capitalize
        bar = build_progress_bar("Testing #{name} progress",download: true,type: bar)

        bar.start

        0.upto(99) do
          sleep(0.05)
          bar.advance
        end

        bar.finish
      end
    end

    def test_fx_spinner
      app_spinner = @spinner
      spinners = if @cmd_opts[:all]
                   {
                     default: App::DEFAULT_SPINNER,
                     classic: App::CLASSIC_SPINNER,
                     no: {},
                   }
                 else
                   { user: app_spinner }
                 end

      spinners.each do |name,spinner|
        @spinner = spinner

        start_spin("Testing #{name.to_s.capitalize} spinner")

        1.upto(3) do |i|
          sleep(1.1)
          update_spin_detail(" (#{i}/3)")
        end

        stop_spin
      end

      # Reset back to users'.
      @spinner = app_spinner
    end
  end
end
end
