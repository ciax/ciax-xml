#!/usr/bin/ruby

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
  # Macro
  class Interlock < LongJump; end
  class Retry < LongJump; end
  class Skip < LongJump; end

  # Communication Error
  class CommError < UserError; end
  # Configuration Error
  class ConfigError < RuntimeError; end

  class UnixTime < Time
    def to_s
      "%.3f" % to_f
    end

    def self.parse(str)
      return str if UnixTime === str
      UnixTime.at(*str.split('.').map{|i| i.to_i})
    end
  end

  # Global option
  class GetOpts < Hash
#    include Msg
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
      optdb['e']='execution mode'
      optdb['s']='simulation mode'
      #For appearance
      optdb['v']='visual output (default)'
      optdb['r']='raw data output'
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
      Msg.type?(attr,Hash)
      @select=Msg.type?(select,Array)
      @dummy=[]
      caption=attr["caption"]
      color=(attr["color"]||6).to_i
      @col=(attr["column"]||1).to_i
      @caption='==== '+Msg.color(caption,color)+' ====' if caption
      @show_all=attr["show_all"]
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
      @select+=h.keys
      super
    end

    # Reset @select
    def reset!
      @select.replace keys
      self
    end

    # For ver 1.9 or more
    def sort!
      @select.sort!
      self
    end

    def to_s
      page=[@caption]
      ((@select+@dummy) & keys).each_slice(@col){|a|
        l=a.map{|key|
          Msg.item(key,self[key]) if self[key]
        }.compact
        page << l.join("\t") unless l.empty?
      }
      if @show_all || page.size > 1
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
      msg=mkmsg(prefix,title,color)
      Kernel.warn msg if msg && condition(msg)
      self
    end

    def ver?
      !ENV['VER'].to_s.empty?
    end

    def warning(prefix,title)
      @ver_indent=@@base
      Kernel.warn mkmsg(prefix,title,3)
      self
    end

    def fatal(prefix,title)
      @ver_indent=@@base
      Kernel.warn mkmsg(prefix,title,1)
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
    def mkmsg(prefix,title,c=nil)
      return unless title
      pass=sprintf("%5.4f",Time.now-Start_time)
      ts= STDERR.tty? ? '' : "[#{pass}]"
      tc=Thread.current
      ts << Msg.color("#{tc[:name]||'Main'}:",tc[:color]||15,@ver_indent)
      ts << Msg.color("#{prefix}:",c||@ver_color)
      ts << title.inspect
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

    def now
      "%.3f" % Time.now.to_f
    end

    def elps_sec(time)
      return 0 unless time
      "%.3f" % (Time.now.to_f-time.to_f)
    end

    def elps_date(time)
      return 0 unless time
      sec=(Time.now.to_f-time.to_f)
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

    def view_struct(data,title=nil,ind=0,show_iv=false)
      raise('Hash Loop') if ind > 5
      str=''
      col=4
      if title
        case title
        when Numeric
          title="[#{title}]"
        else
          title=title.inspect
        end
        str << color("%-6s" % title,5,ind)+" :\n"
        ind+=1
      else
        str << "===\n"
      end
      iv={}
      data.instance_variables.each{|n|
        iv[n]=data.instance_variable_get(n)
      } if show_iv
      _show(str,iv,ind,col,title,show_iv)
      _show(str,data,ind,col,title,show_iv)
    end

    def _show(str,data,ind,col,title,show_iv)
      case data
      when Array
        return str if _mixed?(str,data,data,data.size.times,ind,show_iv)
        return _only_ary(str,data,ind,col) if data.size > col
      when Hash
        return str if _mixed?(str,data,data.values,data.keys,ind,show_iv)
        return _only_hash(str,data,ind,col,title) if data.size > 2
      end
      str.chomp + " #{data.inspect}\n"
    end

    def _mixed?(str,data,vary,idx,ind,show_iv)
      if vary.any?{|v| v.kind_of?(Enumerable)}
        idx.each{|i|
          str << view_struct(data[i],i,ind,show_iv)
        }
      end
    end

    def _only_ary(str,data,ind,col)
      str << indent(ind)+"["
      line=[]
      data.each_slice(col){|a|
        line << a.map{|v| v.inspect}.join(",")
      }
      str << line.join(",\n "+indent(ind))+"]\n"
    end

    def _only_hash(str,data,ind,col,title)
      data.keys.each_slice(title ? 2 : 1){|a|
        str << indent(ind)+a.map{|k|
          color("%-8s" % k.inspect,3)+(": %-10s" % data[k].inspect)
        }.join("\t")+"\n"
      }
      str
    end
  end
end
