#!/usr/bin/ruby
module CIAX
  # Frame Layer
  module Frm
    # Frame Exe module
    module Drv
      def self.extended(obj)
        Msg.type?(obj, Exe)
      end

      def ext_driver
        _init_stream
        _init_drv_ext
        _init_drv_save
        _init_drv_load
        _init_drv_set
        _init_drv_flush
        self
      end

      def _init_stream
        @stream = Stream.new(@id, @cfg)
        @stream.ext_log if @cfg[:option].log?
        @stream.pre_open_proc = proc { @sv_stat.up(:ioerr) }
        @stream.post_open_proc = proc { @sv_stat.dw(:ioerr) }
        @stat.ext_rsp(@stream).ext_file.auto_save
      end

      def _init_drv_ext
        @cobj.rem.ext.def_proc do|ent, src|
          @sv_stat.dw(:comerr)
          @stream.snd(ent[:frame], ent.id)
          if ent[:response]
            @stream.rcv
            @stat.conv(ent)
          end
          @stat.flush if src != 'buffer'
          ent.msg = 'OK'
        end
      end

      def _init_drv_save
        @cobj.get('save').def_proc do|ent|
          @stat.save_key(ent.par[0].split(','), ent.par[1])
          verbose { "Save [#{ent.par[0]}]" }
          ent.msg = 'OK'
        end
      end

      def _init_drv_load
        @cobj.get('load').def_proc do|ent|
          @stat.load(ent.par[0] || '')
          @stat.flush
          verbose { "Load [#{ent.par[0]}]" }
          ent.msg = 'OK'
        end
      end

      def _init_drv_set
        @cobj.get('set').def_proc do|ent|
          @stat.repl(ent.par[0], ent.par[1])
          @stat.flush
          verbose { "Set [#{ent.par[0]}] = #{ent.par[1]}" }
          ent.msg = 'OK'
        end
      end

      def _init_drv_flush
        @cobj.get('flush').def_proc do
          @stream.rcv
          @stat.flush
          verbose { 'Flush Stream' }
          ent.msg = 'OK'
        end
      end
    end
  end
end
