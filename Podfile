# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

target 'AtMe' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for AtMe
  pod 'Firebase/Core'
  pod 'Firebase/Auth'
  pod 'Firebase/Database'
  pod 'Firebase/Storage'
  pod 'Kingfisher', '~> 4.0'
  pod 'OneSignal', '>= 2.6.2', '< 3.0'

  target 'AtMeTests' do
    inherit! :search_paths
    pod 'Firebase'
  end
end

target 'OneSignalNotificationServiceExtension' do
  use_frameworks!
  pod 'OneSignal', '>= 2.6.2', '< 3.0'
end
