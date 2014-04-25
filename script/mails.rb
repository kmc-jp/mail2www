# -*- coding: utf-8

require 'rubygems'
require 'bundler/setup'

require_relative 'index'

class Mails
  def initialize(config)
    @config = config
    @config[:folders].each do |folder|
      dir = File.join(@config[:mail_dir], folder)
      Dir.mkdir dir unless File.exist? dir
    end
  end

  def add(mail)
    folder = @config.assort(mail)
    index = Index.new(@config, folder)
    index.inc
    index.close

    mailpath = File.join(@config[:mail_dir], folder, index.value.to_s)
    File.open(mailpath, 'wb') do |f|
      f.write mail
      f.chmod @config[:perm_files]
    end
  end
end
