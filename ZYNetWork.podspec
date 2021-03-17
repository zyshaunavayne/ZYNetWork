
Pod::Spec.new do |spec|

  spec.name         = "ZYNetWork"
  spec.version      = "0.0.5"
  spec.summary      = "ZYNetWork"
  spec.description  = "基于AFN的网络请求二次封装，适用于MVC/MVVM"
  spec.homepage     = "https://github.com/zyshaunavayne/ZYNetWork"
  spec.license      = "MIT"
  spec.author       = { "zhangyushaunavayne" => "shaunavayne@vip.qq.com" }
  spec.platform     = :ios,"9.0"
  spec.dependency    "AFNetworking"
  spec.dependency    "MMKV"
  spec.source       = { git: "https://github.com/zyshaunavayne/ZYNetWork.git", tag: spec.version, submodules: true }
  spec.source_files  = "ZYNetWork/ZYNetWork/*.{h,m}"

end
