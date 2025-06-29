# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020 Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++

require 'minitest/autorun'
require 'simplecov'

SimpleCov.start do
  enable_coverage :branch
end

require 'nhkore'
