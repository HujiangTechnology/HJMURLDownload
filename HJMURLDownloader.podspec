Pod::Spec.new do |s|
  s.name         = "HJMURLDownloader"
  s.version      = "1.1.0"
  s.summary      = "common downloader based on NSURLSession"

  s.homepage     = "https://github.com/HujiangTechnology/HJMURLDownloader"
  s.license      = 'MIT'
  s.author       = 'Hujiang iOS Team'
  s.source       = { :git => "https://github.com/HujiangTechnology/HJMURLDownloader.git",
                     :tag => s.version.to_s }

  s.platform = :ios, '7.0'

  s.requires_arc = true
  s.source_files = 'HJMURLDownloader/*.{h,m}', 'HJMURLDownloader/Views/*.{h,m}','HJMURLDownloader/ViewControllers/*.{h,m}', 'HJMURLDownloader/M3U8Paser/*.{h,m}', 'HJMURLDownloader/Models/*.{h,m}', 'HJMURLDownloader/Extensions/*.{h,m}'  
  s.resources = 'HJMURLDownloader/Resource/HJMDownloader.xcdatamodeld', 'HJMURLDownloader/Resource/*.xcmappingmodel', 'HJMURLDownloader/Resource/*.png'
end
