Pod::Spec.new do |s|
  s.name     = 'DMEThumnailer'
  s.version  = '1.0'
  s.license  = 'BSD' 
  s.summary  = 'DMEThumnailer is a class to generate thumbnails for local images, videos and PDFs'
  s.homepage = 'https://github.com/damarte/DMEBottomView'
  s.author   = { 'David Martínez' => 'damarte86@gmail.com' }
  s.source   = {
    :git => 'https://github.com/damarte/DMEThumnailer.git',
    :tag => '1.0'
  }
  s.requires_arc = true
  s.platform = :ios, '6.0'
  s.source_files = 'DMEThumnailer/*.{h,m}'
end