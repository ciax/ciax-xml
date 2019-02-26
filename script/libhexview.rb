#!/usr/bin/env ruby
require 'libprompt'
require 'libappstat'
require 'libhexdb'
module CIAX
  # Ascii Hex Pack
  module Hex
    # Sub Status DB (Frame, Field, Status)
    class SubStat < Hashx
      include DicToken
      def initialize(status)
        type?(status, App::Status)
        super(status.pick(%i(id time data_ver data class msg)))
        field = type?(status.field, Frm::Field)
        self[:field] = field[:data]
        frame = type?(field.frame, Frm::Frame)
        self[:frame] = frame[:data]
        warn to_v
      end
    end
    # View class
    class View < Varx
      # sv_stat should have server status (isu,watch,exe..) like App::Exe
      # stat contains Status (data:name ,class:name ,msg:name)
      #   + Field (field:name) + Frame (frame:name)
      def initialize(status, hdb = nil, sv_stat = nil)
        @status = type?(status, App::Status)
        @stat = SubStat.new(status)
        super('hex')
        _attr_set(@stat[:id], @stat[:data_ver])
        @dbi = (hdb || Db.new).get(status.dbi[:app_id])
        id = self[:id] || args_err("NO ID(#{id}) in Stat")
        @sv_stat = sv_stat || Prompt.new('site', id)
        vmode('x')
        ___init_cmt_procs
      end

      def to_x
        self[:hexpack]
      end

      private

      def ___init_cmt_procs
        init_time2cmt(@status)
        propagation(@sv_stat)
        propagation(@status)
        @cmt_procs << proc { self[:hexpack] = ___header + ___body }
        cmt
      end

      # Server Status
      def ___header
        ary = ['%', self[:id]]
        ary << __b2e(@sv_stat.up?(:udperr))
        ary << __b2i(@sv_stat.up?(:event))
        ary << __b2i(@sv_stat.up?(:busy))
        ary << __b2e(@sv_stat.up?(:comerr))
        ary.join('')
      end

      def ___body
        return '' unless (hdb = @dbi[:hexpack])
        str = ''
        if hdb[:packs]
          str << ___packed(hdb[:packs])
        elsif hdb[:fields]
          str << ___mk_frame(hdb[:fields])
        end
        str
      end

      def ___packed(packs)
        packs.map do |hash|
          bits = hash[:bits]
          binstr = ___mk_bit(bits)
          pkstr = format('%s%d', hash[:code], bits.size)
          upkstr = format('h%d', hash[:length])
          [binstr].pack(pkstr).unpack(upkstr)[0]
        end.join
      end

      def ___mk_bit(bits)
        bits.map do |hash|
          @stat.get(hash[:ref])
        end.join
      end

      def ___mk_frame(fields)
        fields.map do |hash|
          ___padding(hash, @stat.get(hash[:ref]))
        end.join
      end

      def ___padding(hash, val)
        len = hash[:length].to_i
        type = hash[:type].to_s.to_sym
        pfx = { float: '.2f', int: 'd', binary: 'b' }[type]
        if pfx
          ___fmt_num(pfx, len, val)
        else
          val.to_s.rjust(len, '*')[0, len]
        end
      end

      def ___fmt_num(sfx, len, val)
        num = /f/ =~ sfx ? val.to_f : val.to_i
        format("%0#{len}#{sfx}", num)[0, len]
      end

      def __b2i(b) # Boolean to Integer (1,0)
        b ? '1' : '0'
      end

      def __b2e(b) # Boolean to Error (E,_)
        b ? 'E' : '_'
      end
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('[id]', options: 'h') do |opt, args|
        stat = App::Status.new(args.shift)
        if opt.host
          stat.ext_remote(opt.host)
        else
          stat.ext_local.load
        end
        puts View.new(stat)
      end
    end
  end
end
