default_platform(:android)
platform :android do
  lane :uploadToOpenTesting do
    upload_to_play_store(track: "beta",aab:"build/app/outputs/bundle/release/app-release.aab")
  end

  lane :uploadToClosedTesting do
    upload_to_play_store(track: "alpha",aab:"build/app/outputs/bundle/release/app-release.aab")
  end

  lane :promoteToProduction do | options |
    if options[:version_code]
      supply(track: "beta",track_promote_to: "production",skip_upload_apk: true, version_code: options[:version_code])
    else
      UI.user_error!("You must provide a version_code option when promoting a version to production.")
    end
  end
end
