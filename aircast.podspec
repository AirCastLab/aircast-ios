Pod::Spec.new do |s|

  s.name          = 'aircast'
  s.version       = '1.0.2'
  s.summary       = 'airplay mirroring and airplay casting'
  s.homepage      = 'https://github.com/AirCastLab'
  s.author        = { 'LianXiang Liu' => 'leeoxiang@gmail.com' }
  s.source        = { :git => 'https://github.com/AirCastLab/aircast-ios.git' }
  s.platform      = :ios, '8.0'
  s.source_files  = 'aircast_sdk_ios.framework/Headers/*.{h}'
  s.vendored_frameworks = 'aircast_sdk_ios.framework'
  s.public_header_files = 'aircast_sdk_ios.framework/Headers/acast_c.h'
  s.frameworks    = 'CoreMedia','AVFoundation'
end
