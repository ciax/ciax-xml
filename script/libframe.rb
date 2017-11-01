#!/usr/bin/ruby
require 'libmsg'
require 'libfrmcode'
require 'libfrmcheck'

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
        return verify(e0) if e0[:val] # Verify value
        str = _cut_by_type_(e0)
        return '' if str.empty?
        verbose { "Cut String: [#{str.inspect}]" }
        str = _pick_part_(str, e0[:slice])
        decode(str, e0)
      end

      private

      def _cut_by_type_(e0)
        _cut_len_(e0[:length]) || _cut_delim_(e0[:delimiter]) || _cut_rest_
      end

      def _cut_len_(len)
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

      def _cut_delim_(del)
        return unless del
        dlm = esc_code(del).to_s
        verbose { "Cut by Delimiter [#{dlm.inspect}]" }
        str, dlm, @frame = @frame.partition(dlm)
        @cc.push(str + dlm)
        str
      end

      def _cut_rest_
        verbose { 'Cut all the rest' }
        str = @frame
        @cc.push(str)
        str
      end

      def _pick_part_(str, range)
        return str unless range
        str = str.slice(*range.split(':').map(&:to_i))
        verbose { "Pick: [#{str.inspect}] by range=[#{range}]" }
        str
      end

      def verify(e0)
        ref = e0[:val]
        len = e0[:length] || ref.size
        val = str = @frame.slice!(0, len.to_i)
        if e0[:decode]
          val = decode(val, e0)
          ref = expr(ref).to_s
        end
        _check(e0, ref, val)
        @cc.push(str)
        str
      end

      def _check(e0, ref, val)
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
