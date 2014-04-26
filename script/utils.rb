# -*- coding: utf-8

require 'rubygems'
require 'bundler/setup'

module Mail2www
  module Utils
    def in_to_or_cc?(mail, regexp)
      (mail.to && mail.to.join(',') =~ regexp) || (mail.cc && mail.cc.join(',') =~ regexp)
    end
  end
end
