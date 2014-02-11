# -*- conding: utf-8 -*-

require 'rubygems'
require 'bundler/setup'
require 'time'
require 'erb'

require 'config'
require 'lib/utils'

class Application
  include Config
  include Utils

  def call(env)
    req = Rack::Request.new(env)

    folder = req.params['f'] || FOLDERS[0]
    mailnum = req.params['m']
    page = req.params['p'].to_i - 1

    # dispatch
    response = nil
    if mailnum == nil
      response = list(folder, mailnum, page)
    else
      response = mail(folder, mailnum, page)
    end

    if response.nil?
      response = Rack::Response.new do |r|
        r.status = 500
        r.write 'Something went wrong!'
      end
    end
    response.finish
  end

  def list(folder, mailnum, page)
    files = Dir.entries(File.join(MAIL_DIR, folder)).map!{|file| file.to_i}
            .sort.reject{|n| n == 0}.reverse
    pages = files.size / MAILS_PER_PAGE + 1
    if page < 0
      page = 0
    elsif page > pages - 1
      page = pages - 1
    end
    files = files.slice(page * MAILS_PER_PAGE, MAILS_PER_PAGE)
    files.map! do |num|
      n = num.to_s
      m = "Me"
      from = "Me"
      t = Time.now
      time = "#{t.month}/#{t.day} (#{how_old(t)})"
      subject = "How are you?"

      [n, from, time, subject]
    end

    html = nil
    File.open('./template/list.rhtml') do |f|
      erb = ERB.new(f.read)
      html = erb.result(binding)
    end

    Rack::Response.new do |r|
      r.status = 200
      r.write html
    end
  end

  def mail(folder, mailnum, page)

    path = File.join(MAIL_DIR, folder, mailnum)
    if File.exists? path
      m = nil
      subject = '(no subject)'
      header = {"From" => "Me", "To" => "Me", "Subject" => "Hi!", "Date" => "when?"}
      body = 'How are you?'
    end

    html = nil
    File.open('./template/mail.rhtml') do |f|
      erb = ERB.new(f.read)
      html = erb.result(binding)
    end

    Rack::Response.new do |r|
      r.status = 200
      r.write html
    end
  end
end
