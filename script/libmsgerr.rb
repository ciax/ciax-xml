#!/usr/bin/ruby
require 'libdefine'
require 'libmsgfmt'
# Common Module
module CIAX
  ### Error Display Methods ###
  module Msg
    module_function

    # Messaging methods
    def progress(f = true)
      p = color(f ? '.' : 'x', 1)
      $stderr.print p
    end

    def msg(str = 'message', color = 2, ind = 0) # Display only
      warn color(str, color) + indent(ind)
    end

    # Exception methods
    def id_err(*ary) # Raise User error (Invalid User input)
      ary[0] = color(ary[0], 1)
      fail InvalidID, ary.join("\n  "), caller(1)
    end

    def cmd_err(*ary) # Raise User error (Invalid User input)
      ary[0] = color(ary[0], 1)
      fail InvalidCMD, ary.join("\n  "), caller(1)
    end

    def par_err(*ary) # Raise User error (Invalid User input)
      ary[0] = color(ary[0], 1)
      fail InvalidPAR, ary.join("\n  "), caller(1)
    end

    def cfg_err(*ary) # Raise Device error (Bad Configulation)
      ary[0] = color(ary[0], 1)
      fail ConfigError, ary.join("\n  "), caller(1)
    end

    def cc_err(*ary) # Raise Device error (Verification Failed)
      ary[0] = color(ary[0], 1)
      fail VerifyError, ary.join("\n  "), caller(1)
    end

    def com_err(*ary) # Raise Device error (Communication Failed)
      ary[0] = color(ary[0], 1)
      fail CommError, ary.join("\n  "), caller(1)
    end

    def str_err(*ary) # Raise Device error (Stream open Failed)
      ary[0] = color(ary[0], 1)
      fail StreamError, ary.join("\n  "), caller(1)
    end

    def relay(str)
      str = str ? color(str, 3) + ':' + $ERROR_INFO.to_s : ''
      fail $ERROR_INFO.class, str, caller(1)
    end

    def sv_err(*ary) # Raise Server error (Parameter type)
      ary[0] = color(ary[0], 1)
      fail ServerError, ary.join("\n  "), caller(2)
    end

    def abort(str = 'abort')
      Kernel.abort([color(str, 1), $ERROR_INFO.to_s].join("\n"))
    end

    def usage(str, code = 1)
      warn("Usage: #{$PROGRAM_NAME.split('/').last} #{str}")
      exit code
    end

    def exit(code = 1)
      warn($ERROR_INFO.to_s) if $ERROR_INFO
      Kernel.exit(code)
    end
  end
end
