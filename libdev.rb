#!/usr/bin/ruby
require "libxmldb"
class Dev < XmlDb
  def initialize(dev,cmd)
    begin
      super('ddb',dev)
      select_id(cmd)
    rescue
      puts $!
      exit 1
    end
  end

  # Public Method
  public

  def calc_cc(str)
    a=@doc.attributes
    chk=0
    case a['method']
    when 'len'
      chk=str.length
    when 'bcc'
      str.each_byte {|c| chk ^= c } 
    else
      raise "No such CC method #{a['method']}"
    end
    val=format(chk)
    @v.msg "[#{a['method']}/#{a['format']}] -> [#{val}]"
    @var[a['var']]=val
  end

  def select_id(id)
    begin
      @sel=@doc.elements[TopNode+"//[@id='#{id}']"] || raise
    rescue
      list_id(TopNode+'//select')
      raise("No such a command")
    end
    self
  end

  def each
    super do |e|
      if e.name == 'select'
        raise "ID not selected" unless @sel
        @sel.elements.each do |s|
          yield copy_self(s)
        end
      else
        yield e
      end
    end
  end

end
