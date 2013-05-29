require 'openssl'

default['mongodb']['keyfile']['string'] = ::OpenSSL::Random.random_bytes(753).gsub(/\W/, '')
