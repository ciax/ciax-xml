#!/usr/bin/ruby
require 'libmcrman'

module CIAX
  module Mcr
    module Shell
      include CIAX::Shell
      # cfg should have [:jump_groups]
      def ext_shell
        super
        @stat=View.new(@id,@valid_keys)
        list_mode
        @lastsize = 0
        @cobj.loc.add_view
        @prompt_proc = proc { upd_current }
        # Convert as command
        input_conv_num do|i|
          store_current(i)
        end
        # Convert as parameter
        input_conv_num(@cobj.rem.int.keys) do|i|
          store_current(i)
        end
        @post_exe_procs << proc { @cfg[:output].upd }
        vg = @cobj.loc.add_view
        vg.add_item('list', 'List mode').def_proc { list_mode }
        vg.add_dummy('[1-n]', 'Sequencer mode')
        @records = { nil => @stat }
        self
      end

      private

      def upd_current
        @stat.upd
        if @current > @stat.size || @stat.size > @lastsize
          store_current(@lastsize = @stat.size)
        end
        msg = format('[%d]', @current)
        if @current > 0
          seq = @stat.get(@parameter[:default])
          msg << "(#{seq['stat']})" + optlist(seq['option'])
        end
        msg
      end

      def store_current(i)
        return i.to_s if i > @stat.size
        @current = i
        if i > 0
          id = @stat.keys[i - 1]
          @records[id] ||= get_record(@stat.get(id))
        end
        @parameter[:default] = id
        @cfg[:output] = @records[id]
        nil
      end

      def list_mode
        @current = 0
        @cfg[:output] = @stat
        @parameter[:default] = nil
        ''
      end

      def get_record(seq)
        case seq
        when Hash
          Record.new(seq['id']).ext_http
        when Seq::Exe
          seq.record
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      OPT.parse('cmnlrt')
      begin
        cfg = Config.new
        cfg[:jump_groups] = []
        cfg[:dev_list] = Wat::List.new(cfg).sub_list
        Man.new(cfg).ext_shell.shell
      rescue InvalidCMD
        OPT.usage('[cmd] (par)')
      rescue InvalidID
        OPT.usage('[proj] [cmd] (par)')
      end
    end
  end
end
