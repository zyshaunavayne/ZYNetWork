
Pod::Spec.new do |spec|

  spec.name         = "ZYNetWork"
  spec.version      = "1.0.5"
  spec.summary      = "ZYNetWorking request of zhangyushaunavayne"
  spec.homepage     = "https://github.com/zyshaunavayne/ZYNetWork"
  spec.license = { type: 'MIT', file: 'LICENSE' }
  spec.authors = { "zyshaunavayne" => "shaunavayne@vip.qq.com" }
  spec.source = { git: "https://github.com/zyshaunavayne/ZYNetWork.git", tag: "v#{spec.version}", submodules: true }
  spec.platform      = :ios,"11.0"
  spec.dependency    "AFNetworking"
  spec.dependency    "MMKV"
  spec.dependency    "MJExtension"
  spec.frameworks   = "Foundation","UIKit"
  spec.source_files  = "ZYNetWork/*.{h,m}"

end
