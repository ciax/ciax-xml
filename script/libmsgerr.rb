#!/usr/bin/ruby
require 'libdefine'
require 'libmsgfmt'
# Common Module
module CIAX
  ### Error Display Methods ###
  module Msg
    module_function

    def show(str, nl = "\n")
      $stderr.print(str + nl.to_s)
    end

    # Messaging methods
    def progress(f = true)
      p = colorize(f ? '.' : 'x', 1)
      show(p,nil)
    end

    def msg(str = 'message', color = 2, ind = 0) # Display only
      show colorize(str, color) + indent(ind)
    end

    # Exception methods
    def usr_err(*ary) # Raise User error
      ary[0] = colorize(ary[0], 1)
      fail UserError, ary.join("\n  "), caller(1)
    end

    def id_err(*ary) # Raise User error (Invalid User input)
      ary[0] = colorize(ary[0], 1)
      fail InvalidID, ary.join("\n  "), caller(1)
    end

    def cmd_err(*ary) # Raise User error (Invalid User input)
      ary[0] = colorize(ary[0], 1)
      fail InvalidCMD, ary.join("\n  "), caller(1)
    end

    def par_err(*ary) # Raise User error (Invalid User input)
      ary[0] = colorize(ary[0], 1)
      fail InvalidPAR, ary.join("\n  "), caller(1)
    end

    def cfg_err(*ary) # Raise Device error (Bad Configulation)
      ary[0] = colorize(ary[0], 1)
      fail ConfigError, ary.join("\n  "), caller(1)
    end

    def cc_err(*ary) # Raise Device error (Check Code Verification Failed)
      ary[0] = colorize(ary[0], 1)
      fail CheckCodeError, ary.join("\n  "), caller(1)
    end

    def com_err(*ary) # Raise Device error (Communication Failed)
      ary[0] = colorize(ary[0], 1)
      fail CommError, ary.join("\n  "), caller(1)
    end

    def str_err(*ary) # Raise Device error (Stream open Failed)
      ary[0] = colorize(ary[0], 1)
      fail StreamError, ary.join("\n  "), caller(1)
    end

    def relay(str)
      str = str ? colorize(str, 3) + ':' + $ERROR_INFO.to_s : ''
      fail $ERROR_INFO.class, str, caller(1)
    end

    def sv_err(*ary) # Raise Server error (Parameter type)
      ary[0] = colorize(ary[0], 1)
      fail ServerError, ary.join("\n  "), caller(2)
    end

    def give_up(str = 'give_up')
      Kernel.abort([colorize(str, 1), $ERROR_INFO.to_s].join("\n"))
    end

    def usage(str, code = 1)
      warn("Usage: #{$PROGRAM_NAME.split('/').last} #{str}")
      warn($ERROR_INFO) if $ERROR_INFO
      exit code
    end
  end
end
