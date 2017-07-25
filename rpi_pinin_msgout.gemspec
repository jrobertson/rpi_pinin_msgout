Gem::Specification.new do |s|
  s.name = 'rpi_pinin_msgout'
  s.version = '0.3.4'
  s.summary = 'Returns meaningful messages for humans from the capture of a Raspberry PI GPIO input pin.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/rpi_pinin_msgout.rb']
  s.add_runtime_dependency('rpi_pinin', '~> 0.1', '>=0.1.2')
  s.add_runtime_dependency('secret_knock', '~> 0.3', '>=0.3.0')
  s.add_runtime_dependency('chronic_duration', '~> 0.10', '>=0.10.6')
  s.add_runtime_dependency('morsecode', '~> 0.2', '>=0.2.0')
  s.add_runtime_dependency('morsecode_listener', '~> 0.1', '>=0.1.2')
  s.signing_key = '../privatekeys/rpi_pinin_msgout.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/rpi_pinin_msgout'
end
