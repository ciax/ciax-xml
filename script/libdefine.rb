#!/usr/bin/ruby
# Class/Module Definition
module CIAX
  require 'English' # To use $! -> $ERROR_INFO
  require 'debug' if ENV['DEBUG']
  NS_COLOR = 15

  # Site Domain
  module Site; NS_COLOR = 13; end
  # Frame Layer
  module Frm; NS_COLOR = 2; end
  # Application Layer
  module App; NS_COLOR = 3; end
  # Watch Layer
  module Wat; NS_COLOR = 9; end
  # HexString Layer
  module Hex; NS_COLOR = 5; end
  # Macro Domain
  module Mcr; NS_COLOR = 12; end
  # Device Site DB
  module Dev; NS_COLOR = 2; end
  # Instance Site DB
  module Ins; NS_COLOR = 6; end
  # XML module
  module Xml; NS_COLOR = 4; end
  # Cmd module
  module Cmd; NS_COLOR = 2; end
  # Symbol module
  module Sym; NS_COLOR = 1; end
  # SqLog module
  module SqLog; NS_COLOR = 1; end

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
end
