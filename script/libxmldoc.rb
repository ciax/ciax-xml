#!/usr/bin/ruby
require "libxmlgn"

class XmlDoc < Hash
  private
  def initialize(dbid = nil,type = nil)
    @v=Verbose.new("Doc/#{dbid}",4)
    @domain={}
    if type && ! readxml(dbid,type){|e|
        @domain[e.name]=e
        update(e.to_h)
        e.each{|e1|
          @domain[e1.name]=e1
          @v.msg{"Domain:#{e1.name}"}
        }
      }.empty?
    else
      list={}
      readxml(dbid){|e| list[e['id']]=e }
      @v.list(list)
    end
  end

  def readxml(dbid,type='*')
    pre="#{ENV['XMLPATH']}/#{dbid}"
    path="#{pre}-#{type}.xml"
    Dir.glob(path).each{|p|
      XmlGn.new(p).each{|e|
        yield e
      }
    }
  end

  public
  def select_id(domain,id,xpath='*')
    elem=find_each(domain,"#{xpath}[@id='#{id}']"){|e| return e }
    return elem if elem
    err=''
    err << "No such command [#{id}]\n" if id
    err << "== Command List ==\n"
    find_each(domain,xpath){|e|
      err << e.item('id')
    }
    raise SelectID,err
  end

  def find_each(domain,xpath=nil)  # child or find
# For Symbol, domain is not <symbol> at sdb_all
    return unless @domain.key?(domain)
    if xpath
      @domain[domain].find_each(xpath){|e| yield e}
    else
      @domain[domain].each{|e| yield e}
    end
  end

  def domain(domain)
    @domain[domain]
  end
end
