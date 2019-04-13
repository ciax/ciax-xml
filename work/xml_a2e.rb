#!/usr/bin/env ruby
# XML Attribute to Element
require 'optparse'
require 'rexml/document'
include REXML

if ARGV.size < 2
  abort <<EOF
Usage: a2e [.//element)] [attr] < xml
       <element attr="str"... -> <str...
EOF
end

xpath = ARGV.shift
attr = ARGV.shift || abort('No attr')
doc = Document.new(gets(nil))
doc.each_element(xpath) do |e|
  str = e.attributes[attr] || next
  e.delete_attribute(attr)
  e.name = str
end
doc.write
