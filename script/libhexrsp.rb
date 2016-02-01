#!/usr/bin/ruby
require 'libprompt'
require 'libhexdb'
module CIAX
  # Ascii Hex Pack
  module Hex
    # View class
    class Rsp < Varx
      # hint should have server status (isu,watch,exe..) like App::Exe
      def initialize(dbi, stat, sv_stat = nil)
        @dbi = type?(dbi, Dbi)
        @stat = type?(stat, App::Status)
        super('hex', @stat[:id], @stat[:ver])
        id = self[:id] || id_err("NO ID(#{id}) in Stat")
        @sv_stat = type?(sv_stat || Prompt.new('site', id), Prompt)
        @vmode = :x
        _init_upd_
      end

      def to_x
        self[:hexpack]
      end

      def to_s
        if @vmode == :x
          to_x
        else
          super
        end
      end

      private

      def _init_upd_
        @sv_stat.post_upd_procs << proc do
          verbose { 'Propagate Prompt#upd -> Hex::Rsp#upd' }
          upd
        end
        @stat.post_upd_procs << proc do
          verbose { 'Propagate Status#upd -> Hex::Rsp#upd' }
          upd
        end
        upd
      end

      def upd_core
        self[:hexpack] = _get_header_ + _get_body_
        self
      end

      # Server Status
      def _get_header_
        ary = ['%', self[:id]]
        ary << b2e(@sv_stat.get(:udperr))
        ary << b2i(@sv_stat.get(:event))
        ary << b2i(@sv_stat.get(:busy))
        ary << b2e(@sv_stat.get(:comerr))
        ary.join('')
      end

      def _get_body_
        return '' unless (hdb = @dbi[:hexpack])
        str = ''
        if hdb[:packs]
          hdb[:packs].each do |hash|
            binstr = _mk_frame(hash)
            pkstr = hash[:code] + hash[:length]
            str << [binstr].pack(pkstr).unpack('h')[0]
          end
        elsif hdb[:fields]
          str << _mk_frame(hdb)
        end
        str
      end

      def _mk_frame(db)
        str = ''
        db[:fields].each do |hash|
          key = hash[:ref]
          cfg_err("No such key [#{key}]") unless @stat[:data].key?(key)
          dat = _padding(hash, @stat[:data][key])
          verbose { "Get from Status #{key} = #{dat}" }
          str << dat
        end
        str
      end

      def _padding(hash, val)
        len = hash[:length].to_i
        case hash[:type]
        when /float/
          format("%0#{len}.2f", val.to_f)
        when /int/
          format("%0#{len}d", val.to_i)
        when /binary/
          format("%0#{len}b", val.to_i)
        else
          format("%#{len}s", val)
        end
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
        dbi = Db.new.get(stat.dbi[:app_id])
        puts Rsp.new(dbi, stat)
      rescue InvalidID
        Msg.usage(' < status_file')
      end
    end
  end
end
