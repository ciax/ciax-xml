#!/usr/bin/ruby
# Class/Module Definition
module CIAX
  require 'English' # To use $! -> $ERROR_INFO
  require 'debug' if ENV['DEBUG']

  # MY HOST
  HOST = `hostname`.strip
  # MY NAME
  PROGRAM = $PROGRAM_NAME.split('/').pop
  # Initial View Mode
  VMODE = 'v'.freeze
  # User input Error
  class UserError < RuntimeError; end
  # When invalid Argument, exit from shell/server
  class InvalidARGS < UserError; end
  # When invalid Option, exit from shell/server
  class InvalidOPT < InvalidARGS; end
  # When invalid Device, exit from shell/server
  class InvalidID < InvalidARGS; end
  # When invalid Command, continue in shell/server
  class InvalidCMD < InvalidID; end
  # When invalid Parameter, continue in shell/server
  class InvalidPAR < InvalidCMD; end

  # Mangaged Exception(Long Jump)
  class LongJump < RuntimeError; end
  # Switching Shell
  class SiteJump < LongJump; end
  # Switching Layer
  class LayerJump < LongJump; end

  # Macro
  class Interlock < LongJump; end
  class Verification < LongJump; end
  class Retry < LongJump; end

  # Server error (Handled in Server)
  class ServerError < RuntimeError; end

  # Configuration Error
  class ConfigError < ServerError; end

  # Device Communication Error
  class CommError < ServerError; end

  # Stream Open Error
  class StreamError < CommError; end
  # CC Verification Error
  class CheckCodeError < CommError; end
  # No Data in Field for Status
  class NoData < CommError; end
  # Invalid Data in Field for Status
  class BadData < CommError; end
end
