# -*- coding: utf-8

require 'rubygems'
require 'bundler/setup'
require 'rack'
require 'sinatra/base'

module Mail2www
  module Helpers
    def h(str)
      Rack::Utils.escape_html(str)
    end

    def u(str)
      Rack::Utils.escape(str)
    end

    def how_old(t)
      diff = Time.now - t

      m = 60
      h = 60*m
      d = 24*h

      case diff
      when 0...m
        format "%ds", diff
      when m...h
        format "%dm", diff/m
      when h...d
        format "%dh", diff/h
      when d..d*30
        format "%dd", diff/d
      else
        format "%dM", diff/(d*30) # Do we need more precise way?
      end
    end

    def append_slash(url)
      if url.include?('?')
        path, q, query = url.rpartition('?')
        path = path + '/' unless path.end_with?('/')
        url = path + q + query
      else
        url = url + '/' unless url.end_with?('/')
      end
      url
    end

    def to_string(x)
      if x.is_a?(Array)
        x.map { |item| item.to_s } .join(',')
      else
        x.to_s
      end
    end

    def get_from(mail)
      to_string(mail.from)
    end

    def get_to(mail)
      to_string(mail.to)
    end

    def get_header(mail)
      ['From: ' << (get_from(mail) || '(none)'),
       'To: ' << (get_to(mail) || '(none)'),
       'Subject: ' << (mail.subject.toutf8 || '(none)'),
       'Date: ' << (mail.date.to_s || '(none)')
      ].join("\n")
    end

    def cgi_link(query)
      "?#{build_query(query)}"
    end
  end
end
