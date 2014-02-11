# -*- conding: utf-8 -*-

require 'rubygems'
require 'bundler/setup'
require 'time'
require 'erb'
require 'mail'

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
      response = list(folder, page)
    else
      response = mail(folder, mailnum)
    end

    if response.nil?
      response = Rack::Response.new do |r|
        r.status = 500
        r.write 'Something went wrong!'
      end
    end
    response.finish
  end

  def list(folder, page)
    mails_path = File.join(MAIL_DIR, folder)
    files = Dir.entries(mails_path).map!{|file| file.to_i}
            .sort.reject{|n| n == 0}.reverse
    pages = files.size / MAILS_PER_PAGE + 1
    if page < 0
      page = 0
    elsif page > pages - 1
      page = pages - 1
    end
    files = files.slice(page * MAILS_PER_PAGE, MAILS_PER_PAGE)
    mails = files.map do |num|
      mail_path = File.join(mails_path, num.to_s)
      mail = Mail.read(mail_path)
      t = Time.parse(mail.date.to_s)
      time = "#{t.month}/#{t.day} (#{how_old(t)})"

      [num.to_s, mail.from, time, mail.subject]
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

  def mail(folder, mailnum)

    path = File.join(MAIL_DIR, folder, mailnum)
    if File.exists? path
      mail = Mail.read(path)
      subject = mail.subject || '(no subject)'
      header = ''
      header << 'From: ' << (mail.from.join(',') || "(none)") << "\n"
      header << 'To: ' << (mail.to.join(',') || "(none)") << "\n"
      header << 'Subject: ' << (mail.subject || "(none)") << "\n"
      header << 'Date: ' << (mail.date.to_s || "(none)") << "\n"
      body = mail.body.decoded
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
