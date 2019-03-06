#!/usr/bin/env ruby
# XML Element to Attribute
#alias e2a
require 'optparse'
require 'rexml/document'
include REXML

if ARGV.size < 2
  abort <<EOF
Usage: xml_e2a [xpath] [element] [attr] < xml
       <str... -> <element attr="str"...
EOF
end

xpath = ARGV.shift
elem = ARGV.shift || abort('No element')
attr = ARGV.shift || abort('No attr')
doc = Document.new(gets(nil))
doc.each_element(xpath) do |e0|
  e0.each_element do |e|
    str = e.name
    e.name = elem
    e.add_attribute(attr, str)
  end
end
doc.write
