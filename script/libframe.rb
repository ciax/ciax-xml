#!/usr/bin/ruby
require 'libmsg'
require 'libfrmcode'

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
        @cls_color = 11
        @endian = endian
        @ccrange = nil
        @method = ccmethod
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
      def add(frame, e = {})
        if frame
          code = encode(frame, e)
          @frame << code
          @ccrange << code if @ccrange
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
        str = _cut_by_type(e0)
        return '' if str.empty?
        verbose { "Cut String: [#{str.inspect}]" }
        str = _pick_part(str, e0[:slice])
        decode(str, e0)
      end

      # Check Code
      def cc_add(str) # Add to check code
        @ccrange << str if @ccrange
        verbose { "Cc Add to Range Frame [#{str.inspect}]" }
        self
      end

      def cc_mark # Check Code Start
        verbose { 'Cc Mark Range Start' }
        @ccrange = ''
        self
      end

      def cc_set # Check Code End
        verbose { "Cc Frame [#{@ccrange.inspect}]" }
        chk = 0
        case @method
        when 'len'
          chk = @ccrange.length
        when 'bcc'
          @ccrange.each_byte { |c| chk ^= c }
        when 'sum'
          @ccrange.each_byte { |c| chk += c }
          chk = chk % 256
        else
          Msg.cfg_err("No such CC method #{@method}")
        end
        verbose { "Cc Calc [#{@method.upcase}] -> (#{chk})" }
        @ccrange = nil
        @cc = chk.to_s
      end

      def cc_check(cc)
        return self unless cc
        if cc == @cc
          verbose { "Cc Verify OK [#{cc}]" }
        else
          fmt = 'CC Mismatch:[%s] (should be [%s]) in [%s]'
          cc_err(format(fmt, cc, @cc, @ccrange.inspect))
        end
        self
      end

      private

      def _cut_by_type(e0)
        _cut_len(e0[:length]) || _cut_delim(e0[:delimiter]) || _cut_rest
      end

      def _cut_len(len)
        return unless len
        verbose { "Cut by Size [#{len}]" }
        if len.to_i > @frame.size
          alert("Cut reached end [#{@frame.size}/#{len}] ")
          str = @frame
        else
          str = @frame.slice!(0, len.to_i)
        end
        cc_add(str)
        str
      end

      def _cut_delim(del)
        return unless del
        dlm = esc_code(del).to_s
        verbose { "Cut by Delimiter [#{dlm.inspect}]" }
        str, dlm, @frame = @frame.partition(dlm)
        cc_add(str + dlm)
        str
      end

      def _cut_rest
        verbose { 'Cut all the rest' }
        str = @frame
        cc_add(str)
        str
      end

      def _pick_part(str, range)
        return str unless range
        str = str.slice(*range.split(':').map(&:to_i))
        verbose { "Pick: [#{str.inspect}] by range=[#{range}]" }
        str
      end

      def verify(e0)
        ref = e0[:val]
        len = e0[:length] || ref.size
        str = @frame.slice!(0, len.to_i)
        if e0[:decode]
          val = decode(str, e0)
          ref = expr(ref).to_s
        else
          val = str
        end
        if ref == val
          verbose { "Verify:(#{e0[:label]}) [#{ref.inspect}] OK" }
        else
          fmt = 'Mismatch(%s/%s):%s for %s'
          cc_err(format(fmt, e0[:label], e0[:decode], val.inspect, ref.inspect))
        end
        cc_add(str)
        str
      end
    end
  end
end
