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
      raise UserError, ary.join("\n  "), caller(1)
    end

    def args_err(*ary) # Raise ARGS error
      raise InvalidARGS, ary.join("\n  "), caller(1)
    end

    def id_err(id, type, comment = '') # Raise User error (Invalid User input)
      raise InvalidID, "No such ID (#{id}) in #{type}\n#{comment}", caller(1)
    end

    def cmd_err(*ary) # Raise User error (Invalid User input)
      raise InvalidCMD, ary.join("\n  "), caller(1)
    end

    def par_err(*ary) # Raise User error (Invalid User input)
      raise InvalidPAR, ary.join("\n  "), caller(1)
    end

    def cfg_err(*ary) # Raise Device error (Bad Configulation)
      ary[0] = colorize("#{self.class}: #{ary[0]}", 1)
      raise ConfigError, ary.join("\n  "), caller(1)
    end

    def cc_err(*ary) # Raise Device error (Check Code Verification Failed)
      raise CheckCodeError, ary.join("\n  "), caller(1)
    end

    def com_err(*ary) # Raise Device error (Communication Failed)
      raise CommError, ary.join("\n  "), caller(1)
    end

    def data_err(*ary) # Raise Device error (Data invalid)
      raise InvalidData, ary.join("\n  "), caller(1)
    end

    def ver_err(*ary) # Raise Device error (Format Version Mismatch)
      raise VerMismatch, ary.join("\n  "), caller(1)
    end

    def str_err(*ary) # Raise Device error (Stream open Failed)
      raise StreamError, ary.join("\n  "), caller(1)
    end

    def mcr_err(*ary) # Raise No Macro commandd error (Not an option)
      raise NoMcrCmd, ary.join("\n  "), caller(1)
    end

    def relay(str)
      str = "#{str}\n#{$ERROR_INFO}"
      raise $ERROR_INFO.class, str, caller(1)
    end

    def sv_err(*ary) # Raise Server error (Parameter type)
      raise ServerError, ary.join("\n  "), caller(2)
    end

    def give_up(str = 'give_up')
      Kernel.abort([colorize(str, 1), $ERROR_INFO.to_s,
                    *$ERROR_POSITION].join("\n"))
    end

    def usage(str, code = 2)
      warn("Usage: #{$PROGRAM_NAME.split('/').last} #{str}")
      if $ERROR_INFO
        show_err
        eid = $ERROR_INFO.class.to_s.sub('CIAX::Invalid', '')
        code = %w(ARGS OPT ID CMD PAR).index(eid).to_i + 2
      end
      exit code
    end
  end
end
