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
      attr_reader :dbi, :sv_stat
      def initialize(status, sv_stat = nil)
        ext_dic(:data)
        self[:status] = type?(status, App::Status)
        super(status.pick(%i(id time data_ver data class msg)))
        self[:field] = type?(status.field, Frm::Field)
        self[:frame] = type?(self[:field].frame, Frm::Frame)
        @dbi = self[:status].dbi
        @sv_stat = sv_stat || Prompt.new('site', self[:id])
      end

      def ext_remote(host)
        %i(frame field status).each do |ky|
          self[ky].ext_remote(host)
        end
        self
      end

      def ext_local
        %i(frame field status).each do |ky|
          self[ky].ext_local
        end
        self
      end

      def mode(host)
        host ? ext_remote(host) : ext_local
      end
    end
    # View class
    class View < Varx
      # sv_stat should have server status (isu,watch,exe..) like App::Exe
      # stat contains Status (data:name ,class:name ,msg:name)
      #   + Field (field:name) + Frame (frame:name)
      def initialize(stat, hdb = nil)
        @stat = type?(stat, SubStat)
        super('hex')
        _attr_set(@stat[:id], @stat[:data_ver])
        @dbi = (hdb || Db.new).get(@stat.dbi[:app_id])
        @sv_stat = @stat.sv_stat
        vmode('x')
        ___init_cmt_procs
      end

      def to_x
        self[:hexpack]
      end

      private

      def ___init_cmt_procs
        init_time2cmt(@stat[:status])
        propagation(@sv_stat)
        propagation(@stat[:status])
        @cmt_procs.append { self[:hexpack] = ___header + ___body }
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
        pfx = { float: '.2f', int: 'd', binary: 'b', hex: 'x' }[type]
        if pfx
          ___fmt_num(pfx, len, val)
        else
          str = val.to_s.tr("\n", '')
          len > 0 ? str.rjust(len, '*')[0, len] : str
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
        stat = SubStat.new(App::Status.new(args.shift)).mode(opt.host)
        puts View.new(stat).to_x
      end
    end
  end
end
