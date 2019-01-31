#!/usr/bin/env ruby
# XML Attribute vs Text Exchanger
require 'optparse'
require 'xml'
include XML

opt = ARGV.getopts('r')
if ARGV.size < 3
  abort <<EOF
Usage: a2t (-r) [xpath] [attr] (ns) < xml
       //(xpath)@(attr) <-> //xpath.text()
       http://ciax.sum.naoj.org/ciax-xml/(ns)
EOF
end
xpath = ARGV.shift
attr = ARGV.shift || abort('No attr')
doc = Document.io(STDIN)
ns = ARGV.shift
if ns
  url = 'http://ciax.sum.naoj.org/ciax-xml'
  nodes = doc.find("//dns:#{xpath}", "dns:#{url}/#{ns}")
else
  nodes = doc.find("//#{xpath}")
end

nodes.each do |e|
  if opt['r']
    e[attr] = e.content
    e.content = ''
  else
    str = e[attr] || next
    e.content = str
    e.attributes.get_attribute(attr).remove!
  end
end
puts doc
