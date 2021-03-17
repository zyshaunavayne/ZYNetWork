#
#  Be sure to run `pod spec lint ZYNetWork.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name         = "ZYNetWork"
  spec.version      = "0.0.4"
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
