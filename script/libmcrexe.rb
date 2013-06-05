#!/usr/bin/ruby
require "libmcrdb"
require "libmcrrec"
require "libcommand"
require "libinssh"

module Mcr
  include CmdExt
  class Exe < Sh::Exe
    attr_reader :record,:valid_keys
    def initialize(mitem,il,&mcr_proc)
      @mitem=Msg.type?(mitem,Command::Item)
      @il=Msg.type?(il,Ins::Layer)
      @record=Record.new(@mitem.cmd,@mitem[:label])
      @record.extend(Prt) unless $opt['r']
      self['layer']='mcr'
      self['id']=@mitem[:cmd]
      # @mcr_proc{|cmd,async?(t/f)|} for submacro
      @mcr_proc=mcr_proc
    end

    def start(valid_keys=[]) # separated for sub thread
      @valid_keys=Msg.type?(valid_keys,Array)
      self['stat']='run'
      puts @record if Msg.fg?
      macro(@mitem)
      result('done')
      self
    rescue Interlock
      result('error')
      self
    rescue Interrupt
      @appint.call if @appint
      result('interrupted')
      self
    ensure
      @record.fin
    end

    def to_s
      @mitem[:cmd]+'('+self['stat']+')'
    end

    private
    def macro(item,depth=1)
      item.select.each{|e1|
        begin
          step=@record.add_step(e1,depth){|site|
            @il['app'][site].stat
          }
          qry=Query.new(step,self)
          case e1['type']
          when 'goal'
            res= step.skip? && !qry.dryrun?
            puts step if Msg.fg?
            raise(Skip) if res
          when 'check'
            res=step.fail?
            puts step if Msg.fg?
            raise(Interlock) if res && qry.done?
          when 'wait'
            print step.title if Msg.fg?
            max=qry.dryrun? ? 3 : nil
            res=step.timeout?(max){ print '.' if Msg.fg?}
            puts step.result if Msg.fg?
            raise(Interlock) if res && qry.done?
          when 'exec'
            puts step.title if Msg.fg?
            step.exec(qry.exec?){|site,cmd,depth|
              ash=@il['app'][site]
              ash.exe(cmd)
              @appint=ash.cobj['sv']['hid']['interrupt']
            }
            puts step.action if Msg.fg?
          when 'mcr'
            puts step if Msg.fg?
            item=@mcr_proc.call(e1['cmd'],/true|1/ === e1['async'])
            macro(item,depth+1) if item.is_a? Command::Item
          end
        rescue Retry
          retry
        rescue Skip
          return
        end
      }
      self
    end

    def result(str)
      self['stat']=str
      @record['result']=str
      puts str if Msg.fg?
    end
  end

  class Query
    def initialize(step,sh)
      @step=Msg.type?(step,Step)
      @sh=Msg.type?(sh,Exe)
    end

    def exec?
      return false if dryrun?
      while ! $opt['n']
        case query(['Exec','Skip'])
        when /^E/i
          break
        when /^S/i
          @step['action']='skip'
          return false
        end
      end
      @step['action']='exec'
    end

    def done?
      return true if $opt['n']
      loop{
        case query(['Done','Force','Retry'])
        when /^D/i
          @step['action']='done'
          return true
        when /^F/i
          @step['action']='forced'
          return false
        when /^R/i
          @step['action']='retry'
          raise(Retry)
        end
      }
    end

    def dryrun?
      ! ['e','s','t'].any?{|i| $opt[i]} && @step['action']='dryrun'
    end

    private
    def query(cmds)
      vk=@sh.valid_keys.clear
      cmds.each{|s| vk << s[0].downcase}
      @sh['stat']='query'
      if Msg.fg?
        prompt=Msg.color('['+cmds.join('/')+']?',5)
        print Msg.indent(@step['depth'].to_i+1)
        res=Readline.readline(prompt,true)
      else
        @step['option']=cmds
        sleep
        @step.delete('option')
        res=Thread.current[:query]
      end
      @sh['stat']='run'
      vk.clear
      res
    end
  end
end

if __FILE__ == $0
  Msg::GetOpts.new('rest',{'n' => 'nonstop mode'})
  begin
    il=Ins::Layer.new('app')
    mdb=Mcr::Db.new.set('ciax')
    mobj=Mcr::Command.new(mdb)
    mitem=mobj.setcmd(ARGV)
    msh=Mcr::Exe.new(mitem,il){|cmd,asy|
      mobj.setcmd(cmd) unless asy
    }
    msh.start
  rescue InvalidCMD
    $opt.usage("[mcr] [cmd] (par)")
  end
end
