#!/usr/bin/env ruby
require 'libdefine'
require 'libmsgfmt'
# Common Module
module CIAX
  ### Error Display Methods ###
  module Msg
    module_function

    def show(str = '')
      $stderr.puts str
    end

    # For user prompting
    def show_err(str = nil)
      show(view_err(str))
    end

    def view_err(str = nil)
      ary = $ERROR_INFO.to_s.split("\n")
      ary << str if str
      ary << $ERROR_INFO.backtrace if ENV['VER'] =~ /traceback/
      ary[0] = colorize(ary[0], 1)
      ary.compact.join("\n")
    end

    # Messaging methods
    def dot(f = true)
      p = colorize(f ? '.' : 'x', 5)
      $stderr.print(p)
    end

    def msg(str = 'message', color = 2, ind = 0) # Display only
      show colorize(str, color) + indent(ind)
    end

    # Exception methods
    def usr_err(*ary) # Raise User error
      raise UserError, cfmt(*ary), caller(1)
    end

    def args_err(*ary) # Raise ARGS error
      raise InvalidARGS, cfmt(*ary), caller(1)
    end

    def id_err(id, type, comment = '') # Raise User error (Invalid User input)
      str = cfmt("No such ID (%s) in %s\n%s", id, type, comment)
      raise InvalidID, str, caller(1)
    end

    def cmd_err(*ary) # Raise User error (Invalid User input)
      line = [cfmt(*ary)]
      line.concat([yield]) if defined? yield
      raise InvalidCMD, line.flatten.join("\n"), caller(1)
    end

    def par_err(*ary) # Raise User error (Invalid User input)
      raise InvalidPAR, cfmt(*ary), caller(1)
    end

    def cfg_err(*ary) # Raise Device error (Bad Configulation)
      ary[0] = "#{self.class}: #{ary[0]}"
      raise ConfigError, cfmt(*ary), caller(1)
    end

    def cc_err(*ary) # Raise Device error (Check Code Verification Failed)
      raise CheckCodeError, cfmt(*ary), caller(1)
    end

    def com_err(*ary) # Raise Device error (Communication Failed)
      raise CommError, cfmt(*ary), caller(1)
    end

    def data_err(*ary) # Raise Device error (Data invalid)
      raise InvalidData, cfmt(*ary), caller(1)
    end

    def ver_err(*ary) # Raise Device error (Format Version Mismatch)
      raise VerMismatch, cfmt(*ary), caller(1)
    end

    def str_err(*ary) # Raise Device error (Stream open Failed)
      raise StreamError, cfmt(*ary), caller(1)
    end

    def mcr_err(*ary) # Raise No Macro commandd error (Not an option)
      raise NoMcrCmd, cfmt(*ary), caller(1)
    end

    def relay(str)
      str = "#{str}\n#{$ERROR_INFO}"
      raise $ERROR_INFO.class, str, caller(1)
    end

    def sv_err(*ary) # Raise Server error (Parameter type)
      raise ServerError, cfmt(*ary), caller(2)
    end

    def give_up(str = 'give_up')
      ary = [str, $ERROR_INFO.to_s, *$ERROR_POSITION]
      Kernel.abort(cfmt(*ary))
    end

    def usage(str)
      warn("Usage: #{$PROGRAM_NAME.split('/').last} #{str}")
      show_err
      safe_exit
    end

    def safe_exit
      exit 2 unless $ERROR_INFO
      es = $ERROR_INFO.class.to_s.sub('CIAX::', '').to_sym
      exit Errors.index(es) + 3
    end
  end
end
