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
      h = 60 * m
      d = 24 * h

      case diff
      when 0...m
        format '%ds', diff
      when m...h
        format '%dm', diff / m
      when h...d
        format '%dh', diff / h
      when d..d * 30
        format '%dd', diff / d
      else
        format '%dM', diff / (d * 30) # Do we need more precise way?
      end
    end

    def append_slash(url)
      if url.include?('?')
        path, q, query = url.rpartition('?')
        path += '/' unless path.end_with?('/')
        url = path + q + query
      else
        url += '/' unless url.end_with?('/')
      end
      url
    end

    def get_from(mail)
      mail.from_addrs.join(',').encode('utf-8')
    rescue Encoding::UndefinedConversionError
      "'From' contains invalid characters"
    end

    def get_to(mail)
      mail.to_addrs.join(',').encode('utf-8')
    rescue Encoding::UndefinedConversionError
      "'To' contains invalid characters"
    end

    def get_subject(mail)
      (mail.subject && mail.subject.toutf8) || '(no subject)'
    end

    def get_date(mail)
      (mail.date && mail.date.to_s) ||
        (mail.envelope_date && mail.envelope_date.to_s)
    end

    def get_header(mail)
      ['From: ' << (get_from(mail) || '(none)'),
       'To: ' << (get_to(mail) || '(none)'),
       'Subject: ' << get_subject(mail),
       'Date: ' << (get_date(mail) || '(none)')
      ].join("\n")
    end

    def get_multipart_body(parts)
      parts.map do |part|
        if part.multipart?
          get_multipart_body(part.parts) || ''
        elsif part.content_type.start_with?('text/')
          part.decoded.toutf8
        end
      end.compact.join("\n---------------\n")
    end

    def get_body(mail)
      if mail.multipart?
        get_multipart_body(mail.parts)
      else
        mail.body.decoded.toutf8
      end
    end

    def cgi_link(query)
      "?#{build_query(query)}"
    end

    def render_mail_body(mail)
      body = get_body(mail)
      urls = URI.extract(body, %w(http, https))
      surround_urls_with_a_tag(body, urls)
    end

    def surround_urls_with_a_tag(text, urls)
      result = ''
      urls.each do |url|
        pre, post = text.split(url, 2)
        # The not URL parts are escaped here.
        result += h(pre) + "<a href=\"#{h(url)}\">#{h(url)}</a>"
        text = post
      end
      result + h(text)
    end
  end
end
