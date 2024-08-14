# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020-2021 Jonathan Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++


module NHKore
  ###
  # @author Jonathan Bradley Whited
  # @since  0.2.0
  ###
  class Error < ::StandardError; end

  # @since 0.2.0
  class CLIError < Error; end

  class Http404Error < Error; end

  # @since 0.2.0
  class ParseError < Error; end

  # @since 0.2.0
  class ScrapeError < Error; end

  # @since 0.2.0
  class ZipError < Error; end
end
