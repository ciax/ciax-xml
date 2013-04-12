#!/usr/bin/ruby
VarDir="#{ENV['HOME']}/.var"
ScrDir=File.dirname(__FILE__)
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
class SelectID < LongJump; end
# Macro
class Interlock < LongJump; end
class Retry < LongJump; end
class Skip < LongJump; end

# Communication Error
class CommError < UserError; end
# Configuration Error
class ConfigError < RuntimeError; end


module Msg
  # Should be extended in module/class
  module Ver
    Start_time=Time.now
    @@base=1
    def init_ver(fmt,col=2,obj=nil)
      @ver_color=col
      if fmt.instance_of?(String)
        raise("Empty Prefix") if fmt.empty?
        @ver_prefix=obj ? fmt % obj.class.name : fmt
      elsif fmt
        @ver_prefix=fmt.class.name
      else
        raise "No Prefix"
      end
      @ver_indent=1
      verbose{"Initialize Messaging"}
    end

    # Public Method
    def verbose(add=0)
      # block takes array (shown by each line)
      # Description of values
      #   [val] -> taken from  xml (criteria)
      #   <val> -> taken from status (incoming)
      #   (val) -> calcurated from status
      return if ENV['VER'].to_s.empty?
      @ver_indent=@@base
      @@base+=add
      @ver_indent=@@base if add < 0
      [*yield].each{|str|
        msg=mkmsg(str)
        Kernel.warn msg if condition(msg)
      }
      self
    end

    # Private Method
    private
    def mkmsg(text)
      return unless text
      pass=sprintf("%5.4f",Time.now-Start_time)
      ts= STDERR.tty? ? '' : "[#{pass}]"
      tc=Thread.current
      ts << Msg.color("#{tc[:name]||'Main'}:",tc[:color]||15,@ver_indent)
      ts << Msg.color("#{@ver_prefix}:",@ver_color)
      ts << text.inspect
    end

    # VER= makes setenv "" to VER otherwise nil
    def condition(msg)
      return true if /\*/ === ENV['VER']
      ENV['VER'].upcase.split(',').any?{|s|
        s.split(':').all?{|e|
          msg.upcase.include?(e)
        }
      }
    end
  end

  # Hash of title
  class CmdList < Hash
    attr_accessor :conf
    def initialize(attr)
      Msg.type?(attr,Hash)
      caption=attr["caption"]
      color=(attr["color"]||6).to_i
      @col=(attr["column"]||1).to_i
      @caption='==== '+Msg.color(caption,color)+' ====' if caption
      @conf={:exclude => ''}
    end

    # For ver 1.9 or more
    def sort!
      hash={}
      keys.sort.each{|k|
        hash[k]=self[k]
      }
      replace(hash)
    end

    def to_s
      page=[]
      keys.reject{|i| /^(#{@conf[:exclude]})$/i === i}.each_slice(@col){|a|
        l=a.map{|key|
          Msg.item(key,self[key]) if self[key]
        }.compact
        page << l.join("\t") unless l.empty?
      }
      page.unshift @caption unless page.empty?
      page.compact.join("\n")
    end

    def error
      raise InvalidCMD,to_s
    end
  end

  # Global option
  class GetOpts < Hash
    def initialize(str='',db={})
      require 'optparse'
      Msg.type?(str,String) << 'd'
      optdb={}
      optdb['c']='client'
      optdb['f']='client at frm'
      optdb['h']='client for [host]'
      #Comm to devices
      optdb['e']='execution mode'
      optdb['s']='simulation mode'
      optdb['t']='test mode'
      #For appearance
      optdb['r']='raw data output'
      optdb['v']='visual output'
      #For debug
      optdb['d']='debug mode'
      optdb.update(db)
      str << db.keys.join('')
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

  ### Class method ###
  module_function
  # Messaging methods
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
    modules.each{|mod|
      unless name.is_a?(mod)
        raise("Parameter type error <#{name.class}> for (#{mod.to_s})")
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

  def view_struct(data,title=nil,ind=0)
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
    end
    case data
    when Array
      vary=data
      idx=data.size.times
      if vary.any?{|v| v.kind_of?(Enumerable)}
        idx.each{|i|
          str << view_struct(data[i],i,ind)
        }
        return str
      elsif  data.size > col
        str << indent(ind)+"["
        line=[]
        vary.each_slice(col){|a|
          line << a.map{|v| v.inspect}.join(",")
        }
        str << line.join(",\n "+indent(ind))+"]\n"
        return str
      end
    when Hash
      vary=data.values
      idx=data.keys
      if vary.any?{|v| v.kind_of?(Enumerable)}
        idx.each{|i|
          str << view_struct(data[i],i,ind)
        }
        return str
      elsif data.size > 2
        idx.each_slice(title ? 2 : 1){|a|
          line=a.map{|k|
            color("%-8s" % k.inspect,3)+(": %-10s" % data[k].inspect)
          }.join("\t")
          str << indent(ind)+line+"\n"
        }
        return str
      end
    end
    str.chomp + " #{data.inspect}\n"
  end
end
