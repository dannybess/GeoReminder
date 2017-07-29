# Uncomment this line to define a global platform for your project
platform :ios, '11.0'

target 'GeoReminder' do
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  inhibit_all_warnings!

  # Pods for GeoReminder
  pod 'Firebase/Core'
  pod 'Firebase/Database'
  pod 'Firebase/Auth'
  pod 'SwiftyJSON'
  pod 'FontAwesomeKit/FontAwesome'
  pod 'KLCPopup'
  pod 'Koloda'
  #pod 'SatoriRtmSdkWrapper', :git => "https://github.com/satori-com/satori-rtm-sdk-c.git", :inhibit_warnings => true
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.2'
        end
    end
  end
