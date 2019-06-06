# Uncomment the next line to define a global platform for your project
platform :macos, '10.9'

target 'Aerial' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Aerial
  pod 'Sparkle'

  target 'Aerial Tests' do
    inherit! :search_paths
    # Pods for testing
  end
end

target 'AerialApp' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for AerialApp
  pod 'Sparkle'
  

end

post_install do |installer|
    # Sign the Sparkle helper binaries to pass App Notarization.
    system("codesign --force -o runtime -s 'Developer ID Application: Guillaume Louel (3L54M5L5KK)' Pods/Sparkle/Sparkle.framework/Resources/Autoupdate.app/Contents/MacOS/Autoupdate")
    system("codesign --force -o runtime -s 'Developer ID Application: Guillaume Louel (3L54M5L5KK)' Pods/Sparkle/Sparkle.framework/Resources/Autoupdate.app/Contents/MacOS/fileop")
end
