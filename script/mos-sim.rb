#!/usr/bin/ruby
require 'libsimap'
require 'libsimarm'
require 'libsimbb'
require 'libsimcar'
require 'libsimfp'

module CIAX::Simulator
  cfg=Conf.new
  Process.daemon(true,true)
  Ap.new(cfg).start
  Arm.new(cfg).start
  BBIO.new(cfg).start
  Carousel.new(cfg).start
  FpDio.new(cfg).start
  sleep
end
