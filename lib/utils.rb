# -*- coding: utf-8

require 'rubygems'
require 'bundler/setup'
require 'rack'

module Mail2www
  module Utils
    include Rack::Utils

    def h(str)
      escape_html(str)
    end

    def u(str)
      escape(str)
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

    def in_to_or_cc?(mail, regexp)
      (mail.to && mail.to.join(',') =~ regexp) || (mail.cc && mail.cc.join(',') =~ regexp)
    end
  end
end
