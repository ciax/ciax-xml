#!/usr/bin/env ruby
require 'libmsg'
require 'libframecode'
require 'libframecc'

module CIAX
  # Frame Layer
  module Frm
    # For Command/Response Frame
    class Frame
      include Msg
      include Codec
      attr_reader :cc
      # terminator: used for detecting end of stream,
      #             cut off before processing in Frame#set().
      #             never being included in CC range
      # delimiter: cut 'variable length data' by delimiter
      #             can be included in CC range
      def initialize(endian = nil, ccmethod = nil, terminator = nil)
        @endian = endian
        @cc = CheckCode.new(ccmethod)
        @terminator = esc_code(terminator)
        reset
      end

      # For Command
      def reset
        @frame = ''
        verbose { 'Reset' }
        self
      end

      # For Command
      def push(frame, e = {}) # returns self
        if frame
          code = encode(frame, e)
          @frame << code
          @cc.push(code)
          verbose { "Add [#{frame.inspect}]" }
        end
        self
      end

      def copy
        verbose { "Copy [#{@frame.inspect}]" }
        @frame
      end

      # For Response
      def set(frame = '')
        if frame && !frame.empty?
          verbose { "Set [#{frame.inspect}]" }
          @frame = @terminator ? frame.split(@terminator).shift : frame
        end
        self
      end

      # Cut frame and decode
      # If param includes 'val' key, it checks value  only
      # If cut str incldes terminetor, str will be trimmed
      def cut(e0)
        verbose { "Cut Start for [#{@frame.inspect}](#{@frame.size})" }
        return ___verify(e0) if e0[:val] # Verify value
        str = ___cut_by_type(e0)
        return '' if str.empty?
        verbose { "Cut String: [#{str.inspect}]" }
        str = ___pick_part(str, e0[:slice])
        decode(str, e0)
      end

      private

      def ___cut_by_type(e0)
        ___cut_by_size(e0[:length]) || \
          ___cut_by_code(e0[:delimiter] || e0[:suffix]) || ___cut_rest
      end

      def ___cut_by_size(len)
        return unless len
        verbose { "Cut by Size [#{len}]" }
        if len.to_i > @frame.size
          alert("Cut reached end [#{@frame.size}/#{len}] ")
          str = @frame
        else
          str = @frame.slice!(0, len.to_i)
        end
        @cc.push(str)
        str
      end

      def ___cut_by_code(code)
        return unless code
        dlm = esc_code(code).to_s
        verbose { "Cut by Code [#{dlm.inspect}]" }
        str, dlm, @frame = @frame.partition(dlm)
        @cc.push(str + dlm)
        str
      end

      def ___cut_rest
        verbose { 'Cut all the rest' }
        str = @frame
        @cc.push(str)
        str
      end

      def ___pick_part(str, range)
        return str unless range
        str = str.slice(*range.split(':').map(&:to_i))
        verbose { "Pick: [#{str.inspect}] by range=[#{range}]" }
        str
      end

      def ___verify(e0)
        ref = e0[:val]
        len = e0[:length] || ref.size
        val = str = @frame.slice!(0, len.to_i)
        if e0[:decode]
          val = decode(val, e0)
          ref = expr(ref).to_s
        end
        ___check(e0, ref, val)
        @cc.push(str)
        str
      end

      def ___check(e0, ref, val)
        if ref == val
          verbose { "Verify:(#{e0[:label]}) [#{ref.inspect}] OK" }
        else
          fmt = 'Mismatch(%s/%s):%s for %s'
          cc_err(format(fmt, e0[:label], e0[:decode], val.inspect, ref.inspect))
        end
      end
    end
  end
end
