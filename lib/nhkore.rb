# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020 Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++

module NHKore
  IS_TEST = ($PROGRAM_NAME == __FILE__)
end

if NHKore::IS_TEST
  require 'rubygems'
  require 'bundler/setup'
end

require 'nhkore/lib'
require 'nhkore/app'

module NHKore
  def self.run(args = ARGV)
    app = App.new(args)

    begin
      app.run
    rescue CLIError => e
      puts "Error: #{e}"
      exit 1
    end
  end
end

NHKore.run if NHKore::IS_TEST
