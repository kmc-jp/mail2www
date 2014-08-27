# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler/setup'
require 'time'
require 'erb'
require 'mail'
require 'kconv'
require 'sinatra/base'

require_relative 'helpers'
require_relative 'mail_extension'

module Mail2www
  class App < Sinatra::Base
    helpers Mail2www::Helpers

    configure :development do
      Bundler.require :development
      register Sinatra::Reloader
    end

    set :views, "#{File.dirname(__FILE__)}/../views"
    set :public_folder, "#{File.dirname(__FILE__)}/../public"
    set :protection, except: :path_traversal

    def initialize(config)
      @config = config
      @title = @config[:title]
      @config[:prefix] = ENV['SCRIPT_NAME'] unless
        ENV['SCRIPT_NAME'].nil? || ENV['SCRIPT_NAME'].empty?
      super
    end

    get '/' do
      redirect to(@config[:folders][0])
    end

    # Stop annoying errors
    get '/favicon.ico' do
    end

    get '/:folder/:mailnum/:filename' do |folder, mailnum, filename|
      path = File.join(@config[:mail_dir], folder, mailnum)
      halt(404, 'Mail not found') unless File.file?(path)
      mail = Mail.read(path)
      file = find_attachment_by_name(mail, filename)

      headers['Content-Type'] = file.mime_type
      file.decoded
    end

    get '/:folder/:mailnum' do |folder, mailnum|
      mail(folder, mailnum)
    end

    get '/:folder' do |folder|
      page = params['page'].to_i
      per_page = @config[:mails_per_page]
      per_page = params['pp'].to_i unless params['pp'].nil?
      list(folder, page, per_page)
    end

    def find_attachment_by_name(mail, filename)
      mail.attachments.find do |attachment|
        attachment.filename == filename
      end
    end

    def list(folder, page, mails_per_page)
      mails_path = File.join(@config[:mail_dir], folder)
      halt(404, 'Folder not found') unless File.directory?(mails_path)

      files = Dir.entries(mails_path).map! { |file| file.to_i }
        .sort.reject { |n| n == 0 }.reverse
      pages = files.size / mails_per_page
      pages += 1 if files.size % mails_per_page != 0
      page = 0 unless page.between?(0, pages - 1)

      files = files.slice(page * mails_per_page, mails_per_page)
      mails = files.map do |num|
        mail_path = File.join(mails_path, num.to_s)
        mail = Mail.read(mail_path)
        t = Time.parse(get_date(mail)) || Time.now
        time = "#{t.month}/#{t.day} (#{how_old(t)})"

        [num.to_s, get_from(mail), time, get_subject(mail)]
      end

      vars = {
        folder: folder, pages: pages, page: page, mails: mails,
        mails_per_page: mails_per_page
      }
      erb :list, locals: vars
    end

    def mail(folder, mailnum)
      path = File.join(@config[:mail_dir], folder, mailnum)
      halt(404, 'File not found') unless File.file?(path)

      mail = Mail.read(path)

      @title += "(#{folder || '(none)'}) / #{get_subject(mail)}"
      vars = { folder: folder, mail: mail, mailnum: mailnum }
      erb :mail, locals: vars
    end
  end
end
