#!/usr/bin/ruby
# XML Attribute vs Child Element exchanger
require "optparse"
require "rexml/document"
include REXML

if ARGV.size < 2
  abort <<EOF
Usage: a2e (-r) [xpath] [attr] < xml
       //xpath@attr <-> //xpath/attr.text()
EOF
end

xpath=ARGV.shift
if /-r/ === xpath
  xpath=ARGV.shift
  attr=ARGV.shift || abort("No attr")
  doc=Document.new(gets(nil))
  doc.each_element(xpath) {|e|
    del=nil
    e.each_element{|e1|
      del=e1 if e1.name == attr
    }
    next unless del
    e.add_attribute(attr,del.text)
    e.delete_element(del)
    e.text=nil
  }
else
  attr=ARGV.shift
  doc=Document.new(gets(nil))
  doc.each_element(xpath) {|e|
    str=e.attributes[attr] || next
    e.delete_attribute(attr)
    e.add_element(attr).text=str
  }
end
doc.write
