#!/usr/bin/env ruby
require 'libmsg'
require 'libfrmcodec'
require 'libfrmcc'

module CIAX
  # Frame Layer
  module Frm
    # For Response Frame
    class CutFrame
      include Msg
      # Parameter "frame" could be destroyed
      # terminator: used for detecting end of stream,
      #             cut off before processing in Frame#set().
      #             never being included in CC range
      # delimiter: cut 'variable length data' by delimiter
      #             can be included in CC range
      #
      # dbe(//frm/stream) could have [endian, ccmethod, termineter]
      def initialize(frame, dbe = {})
        @dbe = type?(dbe, Hash)
        @frame = ___cut_by_term(type?(frame, String))
        @codec = Codec.new(@dbe[:endian])
        @cc_proc = proc {}
      end

      def cc_start
        return self unless @dbe.key?(:ccmethod)
        verbose { 'CC Range Start' }
        @cc = CheckCode.new(@dbe[:ccmethod])
        @cc_proc = proc { |str| @cc << str }
        self
      end

      def cc_reset
        verbose { 'CC Range End' }
        @cc_proc = proc {}
        self
      end

      def cc_check(str)
        return unless @cc
        @cc.check(str)
        verbose { "CC Verified [#{str}]" }
      end

      # Cut frame and decode
      # If param includes 'val' key, it checks value  only
      # If cut str incldes terminetor, str will be trimmed
      def cut(e0)
        verbose do
          cfmt('Cut for %s from [%p](%d)', e0[:type], @frame, @frame.size)
        end
        e0[:type] == 'verify' ? ___verify(e0) : ___assign(e0)
      end

      private

      # Assign or CCRange/Body
      def ___assign(e0)
        str = ___cut_by_rule(e0)
        return '' if str.empty?
        verbose { cfmt('Assign:(%s) [%s = %p]', e0[:label], e0[:ref], str) }
        str = ___slice_part(str, e0[:slice])
        @codec.decode(str, e0).to_s
      end

      def ___cut_by_term(frame)
        return '' unless frame
        return frame unless @dbe.key?(:terminator)
        frame.split(esc_code(@dbe[:terminator])).shift
      end

      def ___cut_by_rule(e0)
        ___cut_by_size(e0[:length]) || \
          ___cut_by_code(e0[:delimiter] || e0[:suffix]) || ___cut_rest
      end

      def ___cut_by_size(len)
        return unless len
        verbose { "Cut by Size [#{len}]" }
        if len.to_i > @frame.size
          alert('Cut reached end [%d/%s]', @frame.size, len)
          str = @frame
        else
          str = @frame.slice!(0, len.to_i)
        end
        @cc_proc.call(str)
        str
      end

      def ___cut_by_code(code)
        return unless code
        dlm = esc_code(code).to_s
        verbose { "Cut by Code [#{dlm.inspect}]" }
        str, dlm, @frame = @frame.partition(dlm)
        @cc_proc.call(str + dlm)
        str
      end

      def ___cut_rest
        verbose { 'Cut all the rest' }
        str = @frame
        @cc_proc.call(str)
        str
      end

      def ___slice_part(str, range)
        return str unless range
        res = str.slice(*range.split(':').map(&:to_i))
        verbose { cfmt('Slice: [%p] from [%p] by [%s]', res, str, range) }
        res
      end

      def ___verify(e0)
        ref = e0[:val]
        len = e0[:length] || ref.size
        val = str = @frame.slice!(0, len.to_i)
        if e0[:decode] && e0[:decode] != 'string'
          val = @codec.decode(val, e0)
          ref = expr(ref)
        end
        ___check(e0, ref, val)
        @cc_proc.call(str)
        str
      end

      def ___check(e0, ref, val)
        if ref == val
          verbose { cfmt('Verify:(%s) [%p] OK', e0[:label], ref) }
        else
          fmt = 'Mismatch(%s/%s):%p for %p'
          cc_err(fmt, e0[:label], e0[:decode], val, ref)
        end
      end
    end
  end
end
