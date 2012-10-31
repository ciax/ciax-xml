#!/usr/bin/ruby
VarDir="#{ENV['HOME']}/.var"
ScrDir=File.dirname(__FILE__)

# User input Error
class UserError < RuntimeError; end
# When invalid Device, exit from shell/server
class InvalidID < UserError; end
# When invalid Command, continue in shell/server
class InvalidCMD < InvalidID; end
# When invalid Parameter, continue in shell/server
class InvalidPAR < InvalidCMD; end

# Mangaged Error
class ManagedError < RuntimeError; end
class SelectID < ManagedError; end
# Broken session in Macro
class Broken < ManagedError; end
class Quit < ManagedError; end

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
      @color=col
      if fmt.instance_of?(String)
        raise("Empty Prefix") if fmt.empty?
        @prefix=obj ? fmt % obj.class.name : fmt
      elsif fmt
        @prefix=fmt.class.name
      else
        raise "No Prefix"
      end
      @ind=1
      msg{"Initialize Messaging (#{self})"}
    end

    # Public Method
    def msg(add=0)
      # block takes array (shown by each line)
      # Description of values
      #   [val] -> taken from  xml (criteria)
      #   <val> -> taken from status (incoming)
      #   (val) -> calcurated from status
      return if ENV['VER'].to_s.empty?
      @ind=@@base
      @@base+=add
      @ind=@@base if add < 0
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
      ts << '  '*@ind
      tc=Thread.current
      ts << Msg.color("#{tc[:name]||'Main'}:",tc[:color]||15)
      ts << Msg.color("#{@prefix}:",@color)
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
    def initialize(attr)
      Msg.type?(attr,Hash)
      caption=attr["caption"]
      color=(attr["color"]||6).to_i
      @col=(attr["column"]||1).to_i
      @caption='==== '+Msg.color(caption,color)+' ====' if caption
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
      keys.each_slice(@col){|a|
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

  ### Class method ###
  module_function
  # Messaging methods
  def msg(msg='message') # Display only
    Kernel.warn color(msg,2)
  end

  def warn(msg='warning') # Display only
    Kernel.warn color(msg,3)
  end

  def alert(msg='alert') # Display only
    Kernel.warn color(msg,1)
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
    raise ConfigError,msg.join("\n  "),caller(1)
  end

  def err(*msg) # Raise User error (Invalid Configuration)
    msg[0]=color(msg[0],1)
    raise UserError,msg.join("\n  "),caller(1)
  end

  def abort(msg='abort')
    Kernel.abort([color(msg,1),$!.to_s].join("\n"))
  end

  def usage(str,*opt)
    Kernel.warn("Usage: #{$0.split('/').last} #{str}")
    opt.each{|s|
      Kernel.warn(" "*6+s)
    }
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

  # Display methods
  def item(key,val)
    Msg.color("  %-6s" % key,3)+": #{val}"
  end

  def now
    "%.3f" % Time.now.to_f
  end

  # Color 1=red,2=green,4=blue,8=bright
  def color(text,c=7)
    return '' if text == ''
    return text unless STDERR.tty?
    (c||=7).to_i
    "\033[#{c>>3};3#{c&7}m#{text}\33[0m"
  end

  def view_struct(data,title=nil,indent=0)
    str=''
    col=4
    if title
      case title
      when Numeric
        title="[#{title}]"
      else
        title=title.inspect
      end
      str << "  " * indent + color("%-6s" % title,5)+" :\n"
      indent+=1
    end
    case data
    when Array
      vary=data
      idx=data.size.times
      if vary.any?{|v| v.kind_of?(Enumerable)}
        idx.each{|i|
          str << view_struct(data[i],i,indent)
        }
        return str
      elsif  data.size > col
        str << "  "* indent + "["
        line=[]
        vary.each_slice(col){|a|
          line << a.map{|v| v.inspect}.join(",")
        }
        str << line.join(",\n "+"  " * indent)+"]\n"
        return str
      end
    when Hash
      vary=data.values
      idx=data.keys
      if vary.any?{|v| v.kind_of?(Enumerable)}
        idx.each{|i|
          str << view_struct(data[i],i,indent)
        }
        return str
      elsif data.size > 2
        idx.each_slice(title ? 2 : 1){|a|
          line=a.map{|k|
            color("%-8s" % k.inspect,3)+(": %-10s" % data[k].inspect)
          }.join("\t")
          str << "  " * indent + line + "\n"
        }
        return str
      end
    end
    str.chomp + " #{data.inspect}\n"
  end

  # Global option
  # set $opt and $optlist(for usage)
  def getopts(str,db={})
    require 'optparse'
    str << 'd'
    optdb={}
    optdb['a']='app level'
    optdb['f']='frm level'
    optdb['l']='simulation mode'
    optdb['t']='test mode'
    optdb['s']='server mode'
    optdb['c']='client mode'
    optdb['h']='[host] remote url'
    optdb['r']='raw display mode'
    optdb['v']='view display mode'
    optdb['d']='debug mode'
    optdb.update(db)
    $optlist=str.split('').map{|c|
      optdb.key?(c) && "-#{c}:#{optdb[c]}" || nil
    }.compact
    $opt=ARGV.getopts(str)
    require 'debug' if $opt['d']
  end
end
