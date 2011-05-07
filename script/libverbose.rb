#!/usr/bin/ruby

class UserError < RuntimeError; end
class SelectID < UserError; end

class Verbose
  Start_time=Time.now
  $DEBUG=true if ENV['VER']
  @@base=1
  def initialize(title='',color=7)
    @title=title.upcase
    @color=color
    @ind=1
 end

  # Public Method
  def msg(add=0)
    return unless ENV['VER']
    @ind=@@base
    @@base+=add
    @ind=@@base if add < 0
    msg=mkmsg(yield) || return
    if ENV['VER'].split(':').any? {|s|
        (msg+'all').upcase.include?(s.upcase) }
      Kernel.warn msg
    end
    return
  end

  def abort(msg='abort')
    Kernel.abort color(msg,1)
  end

  def err(msg='error') # Raise User error (Invalid User input)
    raise UserError,color(msg,1)
  end

  def warn(msg='warning') # Display only
    Kernel.warn color(msg,3)
  end

  def list(list,title='')
    err=[$!.to_s,color(title,2)]
    list.each{|key,val|
      case val
      when String
        label=val
      when Hash,XmlGn
        label=val['label']
      end
      err << color(" %-10s" % key,3)+": #{label}" if label
    }
    raise SelectID,err.grep(/./).join("\n")
  end

  # Private Method
  private
  # 1=red,2=green,4=blue,8=bright
  def color(text,c=@color)
    return '' if text == ''
    return text unless STDERR.tty?
    "\033[#{c>>3};3#{c&7}m#{text}\33[0m"
  end

  def mkmsg(text)
    return unless text
    pass=sprintf("%5.4f",Time.now-Start_time)
    ts= STDERR.tty? ? '' : "[#{pass}]"
    ts+'  '*@ind+color("#{@title}:",@color)+text.inspect
  end
end
