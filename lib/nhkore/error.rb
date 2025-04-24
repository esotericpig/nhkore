# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020-2021 Jonathan Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++

module NHKore
  class Error < ::StandardError; end

  class CLIError < Error; end
  class Http404Error < Error; end
  class ParseError < Error; end
  class ScrapeError < Error; end
  class ZipError < Error; end
end
