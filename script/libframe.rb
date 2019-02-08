#!/usr/bin/env ruby
require 'libmsg'
require 'libfrmcodec'
require 'libfrmccode'

module CIAX
  # Frame Layer
  module Frm
    # For Command/Response Frame
    class Frame
      include Msg
      # terminator: used for detecting end of stream,
      #             cut off before processing in Frame#set().
      #             never being included in CC range
      # delimiter: cut 'variable length data' by delimiter
      #             can be included in CC range
      #
      # db could have [endian, ccmethod, termineter]
      def initialize(frame, db = {})
        return unless frame && !frame.empty?
        @db = type?(db, Hash)
        @codec = Codec.new(db[:endian])
        term = esc_code(db[:terminator])
        @frame = term ? frame.split(term).shift : frame
        cc_reset
      end

      def cc_start
        return self unless @db.key?(:ccmethod)
        @cc = CheckCode.new(@db[:ccmethod])
        @cc_proc = proc { |str| @cc << str }
        self
      end

      def cc_reset
        @cc_proc = proc {}
        self
      end

      def cc_check(str)
        @cc.check(str) if @cc
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
        @codec.decode(str, e0)
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
          val = @codec.decode(val, e0)
          ref = expr(ref)
        end
        ___check(e0, ref, val)
        @cc_proc.call(str)
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
