#!/usr/bin/ruby
require "libsh"
require "libmcrcmd"

module CIAX
  module Mcr
    module Man
      class Exe < Exe
        def initialize(port=nil)
          proj=ENV['PROJ']||'ciax'
          cfg=Config.new
          @mdb=cfg[:db]=Mcr::Db.new.set(proj)
          cfg[:app]=App::List.new
          @list=List.new.ext_file(proj)
          self['sid']='' # response id
          super('mcr',@mdb['id'],Command.new(cfg))
          ext_shell(@list)
        end

        def exe(args)
          self['sid']=''
          super
        end

        def shell_output
          sid=self['sid'].empty? ? '' : '('+self['sid']+')'
          self['msg'].empty? ? @output : self['msg']+sid
        end
      end

      class Sv < Exe
        def initialize(port=nil)
          super
          @cobj.interrupt.set_proc{
            @list.data.each{|st|
              st.thread.raise(Interrupt)
            }
          }
          @cobj.ext_proc{|ent|
            key,stat=ent.fork
            self['sid']=key
            @list.data[key]=stat
            "ACCEPT"
          }
          @cobj.save_procs{@list.save}
          # Internal Command Group
          ig=@cobj.add_int(:valid_keys =>[])
          ig.set_proc{|ent|
            n=ent.par[0]||@list.data.keys.last||""
            self['sid']=n
            if st=@list.data[n]
              if st[:stat] == 'query'
                st.cmd_que << ent.id
                st.res_que.pop
              else
                "IGNORE"
              end
            else
              "NOSID"
            end
          }
          ig.each{|k,v| v[:parameter]=[{:type => 'num',:default => nil}]}
          ig.add_item('clean','Clean macros').set_proc{
            if @list.clean
              @list.save
              'ACCEPT'
            else
              'NOSID'
            end
          }
          ext_server(port||@mdb['port']||55555)
        end
      end
    end

    class List < Datax
      def initialize
        super('macro',{},'procs')
        @caption='<<< '+Msg.color('Active Macros',2)+' >>>'
        @total=''
      end

      def clean
        res=nil
        @data.each{|key,st|
          unless st.thread.alive?
            @data.delete(key)
            res=1
          end
        }
        res
      end

      def to_s
        page=[@caption]
        @data.each{|key,st|
          title="[#{key}]"
          msg="#{st[:cid]} (#{st[:stat]})"
          msg << "[#{st[:option]}]?" if st[:option]
          page << Msg.item(title,msg)
        }
        page.join("\n")
      end
    end

    if __FILE__ == $0
      GetOpts.new('rest',{'n' => 'nonstop mode'})
      begin
        Man::Sv.new.shell
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
