# frozen_string_literal: true

# Check if vips is available at registration time
begin
  require "image_processing/vips"
  require "fileutils"

  # Ensure asset directory exists
  ASSET_DIR = File.expand_path("../../assets", __dir__)
  FileUtils.mkdir_p(ASSET_DIR)
  SAMPLE_IMAGE = File.join(ASSET_DIR, "sample.jpg")

  # Only register if vips is actually available
  RailsBenchmarkSuite.register_workload("Image Heft", weight: 0.1) do
    # Gracefully handle missing dependencies
    if File.exist?(SAMPLE_IMAGE)
      ImageProcessing::Vips
        .source(SAMPLE_IMAGE)
        .resize_to_limit(800, 800)
        .call
    else
      # Maintain benchmark stability if asset is missing
      true
    end
  end

rescue LoadError, StandardError
  # Don't register the workload at all if vips is unavailable
  puts "\n⚠️  Skipping Image Workload: libvips not available. Install with: 'brew install vips' (macOS) or 'sudo apt install libvips-dev' (Linux)\n\n"
end
