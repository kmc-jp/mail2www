# -*- coding: utf-8

require 'rubygems'
require 'bundler/setup'

require_relative 'config'
require_relative 'index'

class Mails
  include Config

  def initialize
    FOLDERS.each do |folder|
      dir = File.join(MAIL_DIR, folder)
      Dir.mkdir dir unless File.exists? dir
    end
  end

  def add(mail)
    folder = assort(mail)
    index = Index.new(folder)
    index.inc
    index.close

    mailpath = File.join(MAIL_DIR, folder, index.value.to_s)
    File.open(mailpath, "wb") do |f|
      f.write mail
      f.chmod PERM_FILES
    end
  end
end
