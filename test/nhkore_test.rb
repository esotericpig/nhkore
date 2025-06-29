# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020 Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++

require 'nhkore/test_helper'

describe(NHKore) do
  subject { NHKore }

  it 'has the version' do
    _(subject::VERSION).must_match(/\d+\.\d+\.\d+(-[0-9A-Za-z\-.]+)?(\+[0-9A-Za-z\-.]+)?/)
  end
end
