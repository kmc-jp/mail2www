# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler/setup'
require 'time'
require 'erb'
require 'mail'
require 'kconv'
require 'sinatra/base'

require_relative 'utils'

class Application < Sinatra::Base
  include Utils

  set :views, "#{File.dirname(__FILE__)}/../views"
  set :public_folder, "#{File.dirname(__FILE__)}/../public"

  def initialize(config)
    @config = config
    super
  end

  get '/' do
    folder = params['f'] || @config[:folders][0]
    mailnum = params['m']
    page = params['p'].to_i

    # dispatch
    response = nil
    if mailnum.nil?
      response = list(folder, page)
    else
      response = mail(folder, mailnum)
    end

    response = 'Something went wrong!' if response.nil?
    response
  end

  # Stop annoying errors
  get '/favicon.ico' do
  end

  def list(folder, page)
    mails_path = File.join(@config[:mail_dir], folder)
    files = Dir.entries(mails_path).map! { |file| file.to_i }
            .sort.reject { |n| n == 0 }.reverse
    mails_per_page = @config[:mails_per_page]
    pages = files.size / mails_per_page
    pages += 1 if files.size % mails_per_page != 0
    page = 0 unless page.between?(0, pages - 1)

    files = files.slice(page * mails_per_page, mails_per_page)
    mails = files.map do |num|
      mail_path = File.join(mails_path, num.to_s)
      mail = Mail.read(mail_path)
      t = mail.date.nil? ? Time.now : Time.parse(mail.date.to_s)
      time = "#{t.month}/#{t.day} (#{how_old(t)})"

      [num.to_s, mail.from.join(','), time, mail.subject.toutf8]
    end

    vars = { folder: folder, pages: pages, page: page, mails: mails }
    erb :list, locals: vars
  end

  def get_header(mail)
    ['From: ' << (mail.from.join(',') || '(none)'),
     'To: ' << (mail.to.join(',') || '(none)'),
     'Subject: ' << (mail.subject.toutf8 || '(none)'),
     'Date: ' << (mail.date.to_s || '(none)')
    ].join("\n")
  end

  def mail(folder, mailnum)
    path = File.join(@config[:mail_dir], folder, mailnum)
    if File.exist? path
      mail = Mail.read(path)
      subject = mail.subject.toutf8 || '(no subject)'
      header = get_header(mail)

      body = ''
      if mail.multipart?
        body = mail.parts.reduce('') do |enum, part|
          # TODO: Show something for non-text part.
          if part.content_type.start_with?('text/plain')
            enum << '\n---------------\n' unless body.empty?
            enum << part.decoded.toutf8
          end
          enum
        end
      else
        body << mail.body.decoded.toutf8
      end
    end

    vars = { folder: folder, subject: subject, mail: mail, header: header, body: body }
    erb :mail, locals: vars
  end

  def cgi_link(query)
    "#{h @config[:cgi_name]}?#{build_query(query)}"
  end
end
