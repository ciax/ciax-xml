#!/usr/bin/ruby
module CIAX
  # Frame Layer
  module Frm
    class Exe
      # Frame Exe module
      module Drv
        def self.extended(obj)
          Msg.type?(obj, Exe)
        end

        def ext_local_driver
          ___init_stream
          ___init_drv_ext
          ___init_drv_save
          ___init_drv_load
          ___init_drv_flush
          ___init_log_mode
          self
        end

        private

        def ___init_stream
          @stream = Stream.new(@id, @cfg)
          @stream.pre_open_proc = proc { @sv_stat.up(:ioerr) }
          @stream.post_open_proc = proc { @sv_stat.dw(:ioerr) }
          @stat.ext_local_rsp(@stream).ext_local_file.auto_save
        end

        def ___init_drv_ext
          @cobj.rem.ext.def_proc do |ent, src|
            @sv_stat.dw(:comerr)
            @stream.snd(ent[:frame], ent.id)
            if ent[:response]
              @stream.rcv
              @stat.conv(ent)
            end
            @stat.flush if src != 'buffer'
          end
        end

        def ___init_drv_save
          @cobj.get('save').def_proc do |ent|
            @stat.save_key(ent.par[0].split(','), ent.par[1])
            verbose { "Save [#{ent.par[0]}]" }
          end
        end

        def ___init_drv_load
          @cobj.get('load').def_proc do |ent|
            @stat.load(ent.par[0] || '')
            @stat.flush
            verbose { "Load [#{ent.par[0]}]" }
          end
        end

        def ___init_drv_flush
          @cobj.get('flush').def_proc do
            @stream.rcv
            @stat.flush
            verbose { 'Flush Stream' }
          end
        end

        def ___init_log_mode
          return unless @cfg[:opt].log?
          @stream.ext_local_log
          @cobj.rem.ext_input_log
        end
      end
    end
  end
end
