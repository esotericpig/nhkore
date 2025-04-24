# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020-2021 Jonathan Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++

require 'nhkore/test_helper'

describe(NHKore) do
  subject { NHKore }

  it 'has version' do
    expect(subject::VERSION).wont_be_nil
  end
end
