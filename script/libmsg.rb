#!/usr/bin/ruby
require "fileutils"
module CIAX
  require 'debug' if ENV['DEBUG']
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
  class SiteJump < LongJump; end
  class LayerJump < LongJump; end

  # Macro
  class Interlock < LongJump; end
  class Retry < LongJump; end
  class Skip < LongJump; end

  # No Data in Field for Status
  class NoData < UserError; end

  # Communication Error
  class CommError < UserError; end
  # Verification Error
  class VerifyError < UserError; end
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
      Kernel.warn make_msg(prefix,Msg.color(title.to_s,1))
      self
    end

    def alert
      @ver_indent=@@base
      Kernel.warn make_msg($!.class,$!,5)
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
      ts << Msg.color("#{tc[:name]||'Main Thread'}:",tc[:color]||15,@ver_indent)
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

    def msg(msg='message',color=2,ind=0) # Display only
      Kernel.warn color(msg,color,ind)
    end

    def _w(var,msg='') # watch var for debug
      if var.kind_of?(Enumerable)
        Kernel.warn color(msg,5)+color("(#{var.object_id})",3)+':'+caller(1).first.split('/').last
        Kernel.warn var.dup.extend(Enumx).path
      else
        Kernel.warn color(var,5)+':'+caller(1).first.split('/').last
      end
    end

    # Exception methods
    def id_err(*msg) # Raise User error (Invalid User input)
      msg[0]=color(msg[0],1)
      raise InvalidID,msg.join("\n  "),caller(1)
    end

    def cmd_err(*msg) # Raise User error (Invalid User input)
      msg[0]=color(msg[0],1)
      raise InvalidCMD,msg.join("\n  "),caller(1)
    end

    def par_err(*msg) # Raise User error (Invalid User input)
      msg[0]=color(msg[0],1)
      raise InvalidPAR,msg.join("\n  "),caller(1)
    end

    def cfg_err(*msg) # Raise Device error (Bad Configulation)
      msg[0]=color(msg[0],1)
      raise ConfigError,msg.join("\n  "),caller(1)
    end

    def vfy_err(*msg) # Raise Device error (Verification Failed)
      msg[0]=color(msg[0],1)
      raise VerifyError,msg.join("\n  "),caller(1)
    end

    def com_err(*msg) # Raise Device error (Communication Failed)
      msg[0]=color(msg[0],1)
      raise CommError,msg.join("\n  "),caller(1)
    end

    def relay(msg)
      msg=msg ? color(msg,3)+':'+$!.to_s : ''
      raise $!.class,msg,caller(1)
    end

    def err(*msg) # Raise User error (Invalid Configuration)
      msg[0]=color(msg[0],1)
      raise UserError,msg.join("\n  "),caller(1)
    end

    def abort(msg='abort')
      Kernel.abort([color(msg,1),$!.to_s].join("\n"))
    end

    def usage(str,code=1)
      Kernel.warn("Usage: #{$0.split('/').last} #{str}")
      exit code
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

    # Query options
    def optlist(list)
      list.empty? ? '' :  color("[#{list.join('/')}]?",5)
    end
  end
end
