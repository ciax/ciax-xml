#!/usr/bin/ruby
require 'libsimap'
require 'libsimarm'
require 'libsimbb'
require 'libsimcar'
require 'libsimfp'

module CIAX::Simulator
  cfg=Conf.new
  Process.daemon(true,true)
  Ap.new.start
  Arm.new.start
  BBIO.new.start
  Carousel.new.start
  FpDio.new.start
  sleep
end
