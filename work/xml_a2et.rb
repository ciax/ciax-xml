#!/usr/bin/env ruby
# XML Attribute to Name and Text
#alias a2et
require 'optparse'
require 'rexml/document'
include REXML

if ARGV.size < 2
  abort <<EOF
Usage: a2et (-r) [xpath] [attr] < xml
       //xpath(/element)@attr=str -> //xpath(/attr).text(str)
EOF
end

xpath = ARGV.shift
attr = ARGV.shift
doc = Document.new(gets(nil))
doc.each_element(xpath) do |e|
  str = e.attributes[attr] || next
  e.delete_attribute(attr)
  e.name = attr
  e.text = str
end
doc.write
