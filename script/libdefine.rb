#!/usr/bin/ruby
# Class/Module Definition
module CIAX
  require 'debug' if ENV['DEBUG']
  ScrDir = ::File.dirname(__FILE__)
  Indent = '  '

  # Layer Color
  module Frm; NsColor = 2; end
  module App; NsColor = 3; end
  module Wat; NsColor = 9; end
  module Hex; NsColor = 5; end
  module Mcr; NsColor = 12; end
  module Xml; NsColor = 4; end
  module Dev; NsColor = 2; end
  module Ins; NsColor = 6; end
  module Sym; NsColor = 1; end
  module SqLog; NsColor = 1; end

  # User input Error
  class UserError < RuntimeError; end
  # When invalid Project, exit from shell/server
  class InvalidProj < UserError; end
  # When invalid Device, exit from shell/server
  class InvalidID < InvalidProj; end
  # When invalid Command, continue in shell/server
  class InvalidCMD < InvalidID; end
  # When invalid Parameter, continue in shell/server
  class InvalidPAR < InvalidCMD; end

  # Mangaged Exception(Long Jump)
  class LongJump < RuntimeError; end
  # Switching Shell
  class SiteJump < LongJump; end
  class LayerJump < LongJump; end

  # Macro
  class Interlock < LongJump; end
  class Retry < LongJump; end

  # Server error
  class ServerError < RuntimeError; end

  # No Data in Field for Status
  class NoData < ServerError; end

  # Stream Open Error
  class StreamError < ServerError; end
  # Communication Error
  class CommError < ServerError; end
  # Verification Error
  class VerifyError < ServerError; end
  # Configuration Error
  class ConfigError < ServerError; end
end
