Pod::Spec.new do |s|
  s.name = 'SocketLogger'
  s.version = '0.1.0'
  s.summary = 'Lightweight, flexible logging utility compatible with any socket-based syslog service.'

  s.homepage = 'https://github.com/instacart/SocketLogger.swift'
  s.license = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.author = { 'Jason Kozemczak' => 'jason.kozemczak@instacart.com', 'Michael Sanders' => 'michael.sanders@fastmail.com' }
  s.source = { :git => 'https://github.com/instacart/SocketLogger.swift.git', :tag => s.version }

  s.requires_arc = true
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '9.0'

  s.source_files = 'Sources/*.{swift}'
  s.dependency 'CocoaAsyncSocket', '~> 7.6'
end
