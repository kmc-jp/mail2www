# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler/setup'
require 'time'
require 'erb'
require 'mail'
require 'kconv'

require_relative 'config'
require_relative 'utils'

class Application
  include Config
  include Utils

  def call(env)
    req = Rack::Request.new(env)

    folder = req.params['f'] || FOLDERS[0]
    mailnum = req.params['m']
    page = req.params['p'].to_i

    # dispatch
    response = nil
    if mailnum.nil?
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

  def make_response(template, bind)
    html = nil
    File.open(template) do |f|
      html = ERB.new(f.read).result(bind)
    end

    Rack::Response.new do |r|
      r.status = 200
      r.write html
    end
  end

  def list(folder, page)
    mails_path = File.join(MAIL_DIR, folder)
    files = Dir.entries(mails_path).map!{|file| file.to_i}
            .sort.reject{|n| n == 0}.reverse
    pages = files.size / MAILS_PER_PAGE
    pages = pages + 1 if (files.size % MAILS_PER_PAGE != 0)
    page = 0 unless page.between?(0, pages - 1)

    files = files.slice(page * MAILS_PER_PAGE, MAILS_PER_PAGE)
    mails = files.map do |num|
      mail_path = File.join(mails_path, num.to_s)
      mail = Mail.read(mail_path)
      t = mail.date.nil? ? Time.now : Time.parse(mail.date.to_s)
      time = "#{t.month}/#{t.day} (#{how_old(t)})"

      [num.to_s, mail.from.join(','), time, mail.subject.toutf8]
    end

    make_response('./template/list.rhtml', binding)
  end

  def get_header(mail)
    ['From: ' << (mail.from.join(',') || "(none)"),
     'To: ' << (mail.to.join(',') || "(none)"),
     'Subject: ' << (mail.subject.toutf8 || "(none)"),
     'Date: ' << (mail.date.to_s || "(none)")
    ].join("\n")
  end

  def mail(folder, mailnum)
    path = File.join(MAIL_DIR, folder, mailnum)
    if File.exists? path
      mail = Mail.read(path)
      subject = mail.subject.toutf8 || '(no subject)'
      header = get_header(mail)

      body = ''
      if mail.multipart?
        mail.parts.map do |part|
          # TODO: Show something for non-text part.
          if part.content_type.start_with?('text/plain')
            body << part.decoded.toutf8 << "\n---------------\n"
          end
        end
      else
        body << mail.body.decoded.toutf8
      end
    end

    make_response('./template/mail.rhtml', binding)
  end
end
