#!/usr/bin/ruby
require 'libprompt'
require 'libhexdb'
module CIAX
  # Ascii Hex Pack
  module Hex
    # View class
    class Rsp < Varx
      # sv_stat should have server status (isu,watch,exe..) like App::Exe
      def initialize(stat, hdb = nil, sv_stat = nil)
        @stat = type?(stat, App::Status)
        super('hex', @stat[:id], @stat[:ver])
        @dbi = (hdb || Db.new).get(@stat.dbi[:app_id])
        id = self[:id] || id_err("NO ID(#{id}) in Stat")
        @sv_stat = sv_stat || Prompt.new('site', id)
        vmode('x')
        _init_upd_
      end

      def to_x
        self[:hexpack]
      end

      private

      def _init_upd_
        @sv_stat.cmt_procs << proc do
          verbose { 'Propagate Prompt#upd -> Hex::Rsp#upd' }
          upd
        end
        @stat.cmt_procs << proc do
          verbose { 'Propagate Status#upd -> Hex::Rsp#upd' }
          upd
        end
        upd
      end

      def upd_core
        time_upd(@stat[:time])
        self[:hexpack] = _get_header_ + _get_body_
        self
      end

      # Server Status
      def _get_header_
        ary = ['%', self[:id]]
        ary << b2e(@sv_stat.up?(:udperr))
        ary << b2i(@sv_stat.up?(:event))
        ary << b2i(@sv_stat.up?(:busy))
        ary << b2e(@sv_stat.up?(:comerr))
        ary.join('')
      end

      def _get_body_
        return '' unless (hdb = @dbi[:hexpack])
        str = ''
        if hdb[:packs]
          str << _packed(hdb[:packs])
        elsif hdb[:fields]
          str << _mk_frame(hdb)
        end
        str
      end

      def _packed(packs)
        packs.map do |hash|
          binstr = _mk_frame(hash)
          pkstr = hash[:code] + hash[:length]
          [binstr].pack(pkstr).unpack('h')[0]
        end.join
      end

      def _mk_frame(db)
        db[:fields].map do |hash|
          key = hash[:ref]
          cfg_err("No such key [#{key}]") unless @stat[:data].key?(key)
          dat = _padding(hash, @stat[:data][key])
          verbose { "Get from Status #{key} = #{dat}" }
          dat
        end.join
      end

      def _padding(hash, val)
        len = hash[:length].to_i
        pfx = { float: '.2f', int: 'd', binary: 'b' }[hash[:type].to_sym]
        if pfx
          _fmt(pfx, len, val)
        else
          val.to_s.rjust(len, '*')[0, len]
        end
      end

      def _fmt(sfx, len, val)
        num = /f/ =~ sfx ? val.to_f : val.to_i
        format("%0#{len}#{sfx}", num)[0, len]
      end

      def b2i(b) # Boolean to Integer (1,0)
        b ? '1' : '0'
      end

      def b2e(b) # Boolean to Error (E,_)
        b ? 'E' : '_'
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libinsdb'
      require 'libstatus'
      begin
        stat = App::Status.new.ext_file
        puts Rsp.new(stat)
      rescue InvalidARGS
        Msg.usage(' < status_file')
      end
    end
  end
end
