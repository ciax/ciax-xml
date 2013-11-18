#!/usr/bin/ruby
require "fileutils"
module CIAX
  VarDir="#{ENV['HOME']}/.var"
  ScrDir=::File.dirname(__FILE__)
  Indent='  '

  # User input Error
  class UserError < RuntimeError; end
  # When invalid Device, exit from shell/server
  class InvalidID < UserError; end
  # When invalid Command, continue in shell/server
  class InvalidCMD < InvalidID; end
  # When invalid Parameter, continue in shell/server
  class InvalidPAR < InvalidCMD; end

  # Mangaged Exception(Long Jump)
  class LongJump < RuntimeError; end
  # Switching Shell
  class SwSite < LongJump; end
  class SwLayer < LongJump; end

  # Macro
  class Interlock < LongJump; end
  class Retry < LongJump; end
  class Skip < LongJump; end

  # Communication Error
  class CommError < UserError; end
  # Configuration Error
  class ConfigError < RuntimeError; end

  class Threadx < Thread
    def initialize(name,color=4)
      th=super{
        Thread.pass
        yield
      }
      th[:name]=name
      th[:color]=color
    end
  end

  # Global option
  class GetOpts < Hash
    def initialize(str='',db={})
      require 'optparse'
      Msg.type?(str,String) << 'd'
      optdb={}
      #Layer
      optdb['a']='app layer (default)'
      optdb['f']='frm layer'
      optdb['x']='hex layer'
      #Client option
      optdb['c']='client'
      optdb['h']='client for [host]'
      #Comm to devices
      optdb['t']='test mode (default)'
      optdb['s']='simulation mode'
      optdb['e']='execution mode'
      #For appearance
      optdb['v']='visual output (default)'
      optdb['r']='raw data output'
      #For macro
      optdb['n']='non-stop mode'
      optdb['m']='movable mode'
      #For debug
      optdb['d']='debug mode'
      optdb.update(db)
      db.keys.each{|k|
        str << k unless str.include?(k)
      }
      @list=str.split('').map{|c|
        optdb.key?(c) && Msg.item("-"+c,optdb[c]) || nil
      }.compact
      update(ARGV.getopts(str))
      require 'debug' if self['d']
      $opt=self
    end

    def usage(str)
      Msg.usage(str,@list)
    end
  end

  # Sortable Hash of title
  # Used by Command and XmlDoc
  class CmdList < Hash
    def initialize(attr,select=[])
      @attr=Msg.type?(attr,Hash)
      @select=Msg.type?(select,Array)
      @dummy=[]
    end

    def []=(k,v)
      @select << k
      super
    end

    def dummy(k,v)
      @dummy << k
      store(k,v)
    end

    def update(h)
      @select.concat h.keys
      super
    end

    # Reset @select(could be shared)
    def reset!
      @select.concat(keys).uniq!
      self
    end

    # For ver 1.9 or more
    def sort!
      @select.sort!
      self
    end

    def to_s
      cap=@attr["caption"]
      cap= '==== '+Msg.color(cap,(@attr["color"]||6).to_i)+' ====' if cap
      page=[cap]
      ((@select+@dummy) & keys).each_slice((@attr["column"]||1).to_i){|a|
        l=a.map{|key|
          Msg.item(key,self[key]) if self[key]
        }.compact
        page << l.join("\t") unless l.empty?
      }
      if @attr["show_all"] || page.size > 1
        page.compact.join("\n")
      else
        ''
      end
    end

    def error
      raise InvalidCMD,to_s
    end
  end

  # Should be extended in module/class
  module Msg
    attr_accessor :ver_color
    Start_time=Time.now
    @@base=1
    # Public Method
    def verbose(prefix,title,color=nil)
      # block takes array (shown by each line)
      # Description of values
      #   [val] -> taken from  xml (criteria)
      #   <val> -> taken from status (incoming)
      #   (val) -> calcurated from status
      @ver_indent=@@base
      msg=make_msg(prefix,title,color)
      Kernel.warn msg if msg && condition(msg)
      self
    end

    def ver?
      !ENV['VER'].to_s.empty?
    end

    def warning(prefix,title)
      @ver_indent=@@base
      Kernel.warn make_msg(prefix,title,3)
      self
    end

    def fatal(prefix)
      @ver_indent=@@base
      title=[$!.to_s,*$@].join("\n")
      Kernel.warn make_msg(prefix,title,1)
      Kernel.exit
    end

    def enclose(prefix,title1,title2,color=nil)
      verbose(prefix,title1,color)
      @@base+=1
      res=yield
    ensure
      @@base-=1
      verbose(prefix,sprintf(title2,res),color)
    end

    # Private Method
    private
    def make_msg(prefix,title,c=nil)
      return unless title
      pass=sprintf("%5.4f",Time.now-Start_time)
      ts= STDERR.tty? ? '' : "[#{pass}]"
      tc=Thread.current
      ts << Msg.color("#{tc[:name]||'Main'}:",tc[:color]||15,@ver_indent)
      ts << Msg.color("#{prefix}:",c||@ver_color)
      ts << title.to_s
    end

    # VER= makes setenv "" to VER otherwise nil
    def condition(msg)
      return unless msg
      return unless ver?
      return true if /\*/ === ENV['VER']
      ENV['VER'].upcase.split(',').any?{|s|
        s.split(':').all?{|e|
          msg.upcase.include?(e)
        }
      }
    end
    ### Class method ###

    module_function
    # Messaging methods
    def progress(f=true)
      p=color(f ? '.' : 'x',1)
      $stderr.print p
    end

    def msg(msg='message',ind=0) # Display only
      Kernel.warn color(msg,2,ind)
    end

    def hidden(msg='hidden',ind=0) # Display only
      Kernel.warn color(msg,8,ind)
    end

    def warn(msg='warning',ind=0) # Display only
      Kernel.warn color(msg,3,ind)
    end

    def alert(msg='alert',ind=0) # Display only
      Kernel.warn color(msg,1,ind)
    end

    # Exception methods
    def cmd_err(*msg) # Raise User error (Invalid User input)
      msg[0]=color(msg[0],1)
      raise InvalidCMD,msg.join("\n  "),caller(1)
    end

    def par_err(*msg) # Raise User error (Invalid User input)
      msg[0]=color(msg[0],1)
      raise InvalidPAR,msg.join("\n  "),caller(1)
    end

    def cfg_err(*msg) # Raise User error (Invalid User input)
      msg[0]=color(msg[0],1)
      raise ConfigError,msg.join("\n  "),caller(1)
    end

    def com_err(*msg) # Raise User error (Invalid User input)
      msg[0]=color(msg[0],1)
      raise CommError,msg.join("\n  "),caller(1)
    end

    def err(*msg) # Raise User error (Invalid Configuration)
      msg[0]=color(msg[0],1)
      raise UserError,msg.join("\n  "),caller(1)
    end

    def abort(msg='abort')
      Kernel.abort([color(msg,1),$!.to_s].join("\n"))
    end

    def usage(str,optlist=[])
      Kernel.warn("Usage: #{$0.split('/').last} #{str}")
      optlist.each{|s| Kernel.warn s}
      exit
    end

    def exit(code=1)
      Kernel.warn($!.to_s) if $!
      Kernel.exit(code)
    end

    # Assertion
    def type?(name,*modules)
      src=caller(1)
      modules.each{|mod|
        unless name.is_a?(mod)
          raise(RuntimeError,"Parameter type error <#{name.class}> for (#{mod.to_s})",src)
        end
      }
      name
    end

    def data_type?(data,type)
      return data if data['type'] == type
      raise "Data type error <#{name.class}> for (#{mod.to_s})"
    end

    # Thread is main
    def fg?
      Thread.current == Thread.main
    end

    # Display methods
    def item(key,val)
      indent(1)+color("%-6s" % key,3)+": #{val}"
    end

    def now_msec
      (Time.now.to_f*1000).to_i
    end

    def elps_sec(msec,base=now_msec)
      return 0 unless msec
      "%.3f" % ((base-msec).to_f/1000)
    end

    def elps_date(msec,base=now_msec)
      return 0 unless msec
      sec=(base-msec).to_f/1000
      if sec > 86400
        "%.1f days" % (sec/86400)
      elsif sec > 3600
        Time.at(sec).utc.strftime("%H:%M")
      elsif sec > 60
        Time.at(sec).utc.strftime("%M'%S\"")
      else
        Time.at(sec).utc.strftime("%S\"%L")
      end
    end

    def date(msec)
      Time.at(msec.to_f/1000).inspect
    end

    # Color 1=red,2=green,4=blue,8=bright
    def color(text,c=7,i=0)
      return '' if text == ''
      return text unless STDERR.tty?
      (c||=7).to_i
      indent(i)+"\033[#{c>>3};3#{c&7}m#{text}\33[0m"
    end

    def indent(ind=0)
      Indent*ind
    end
  end
end
