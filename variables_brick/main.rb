# encoding: utf-8
require 'bundler/cli'
Bundler::CLI.new.invoke(:install, [], path: 'gems', verbose: true, :retry => 3, :jobs => 4)
require 'bundler/setup'
require 'gooddata/bricks'

require_relative 'variables_brick'

include GoodData::Bricks

p = GoodData::Bricks::Pipeline.prepare([
  DecodeParamsMiddleware,
  LoggerMiddleware,
  BenchMiddleware,
  GoodDataMiddleware,
  AWSMiddleware,
  WarehouseMiddleware,
  FsProjectUploadMiddleware.new(:destination => :staging),
  VariablesBrick])

p.call($SCRIPT_PARAMS.to_hash)
