#!/usr/bin/ruby
require "libapplist"
require "libcmdext"
require "libmcrblk"

module Mcr
  module Cmd
    extend Msg::Ver
    # @<< (index),(id*),(par*),cmd*,(def_proc*)
    # @< select*
    # @ aint,opt,interrupt
    attr_reader :block
    def self.extended(obj)
      init_ver('McrCmd',9)
      Msg.type?(obj,Command::ExtItem)
    end

    def ext_mcrcmd(aint,block,opt={})
      @aint=Msg.type?(aint,App::List)
      @block=Msg.type?(block,Block)
      @opt=Msg.type?(opt,Hash)
      self
    end

    def exe
      @block.newline({'type'=>'mcr','mcr'=>@cmd,'label'=>self[:label]})
      @block.crnt.prt
      macro(@block)
      super
      @block.fin
      self
    rescue Interlock
      @block.fin('fail')
    rescue Broken,Interrupt
      @interrupt.exe if @interrupt
      @block.fin('broken')
      Thread.exit
    rescue Quit
      @block.fin('done')
    ensure
      self
    end

    # Should be public for recursive call
    def macro(block,depth=1)
      block[:stat]='run'
      @select.each{|e1|
        next if block.newline(e1,depth)
        case e1['type']
        when 'exec'
          block.crnt.prt
          query(block,depth)
          @interrupt=@aint[e1['site']].exe(e1['cmd']).interrupt
        when 'mcr'
          block.crnt.prt
          @index.dup.setcmd(e1['mcr']).macro(block,depth+1)
        end
      }
      self
    end

    private
    def query(block,depth)
      block[:stat]="query"
      if @opt['v']
        prompt='  '*depth+Msg.color("Proceed?[Y/N]",5)
        true while (res=Readline.readline(prompt,true)).empty?
        raise Broken unless /[Yy]/ === res
      elsif !@opt['n']
        sleep
      end
      block[:stat]='run'
    end
  end
end

class Command::ExtDom
  def ext_mcrcmd(aint,opt={})
    values.each{|item|
      block=Mcr::Block.new(aint,opt)
      item.extend(Mcr::Cmd).ext_mcrcmd(aint,block,opt)
    }
    self
  end
end

if __FILE__ == $0
  require "libmcrdb"

  opt=Msg::GetOpts.new("tn")
  opt['v']=true
  begin
    app=App::List.new
    mdb=Mcr::Db.new('ciax')
    mcobj=Command.new
    mcobj.add_extdom(mdb,:macro).ext_mcrcmd(app,opt)
    item=mcobj.setcmd(ARGV).exe
    item.block.ext_file(item.id).ext_save.save
    puts Msg.view_struct(item.block)
  rescue InvalidCMD
    opt.usage("[cmd] (par)")
  rescue UserError
    Msg.exit(3)
  ensure
  end
end
