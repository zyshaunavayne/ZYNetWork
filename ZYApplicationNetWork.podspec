
Pod::Spec.new do |spec|

  spec.name         = "ZYApplicationNetWork"
  spec.version      = "0.1.0"
  spec.summary      = "ZYApplicationNetWork"
  spec.description  = "based AFN for ZYApplicationNetWork"
  spec.homepage     = "https://github.com/zyshaunavayne/ZYNetWork"
  spec.license      = "MIT"
  spec.author       = { "zhangyushaunavayne" => "shaunavayne@vip.qq.com" }
  spec.platform     = :ios,"9.0"
  spec.dependency    "AFNetworking"
  spec.dependency    "MMKV"
  spec.frameworks   = "Foundation","UIKit"
  spec.source       = { git: "https://github.com/zyshaunavayne/ZYNetWork.git", tag: spec.version, submodules: true }
  spec.source_files  = "ZYNetWork/ZYNetWork/*.{h,m}"

end
