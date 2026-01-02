# frozen_string_literal: true

begin
  require "image_processing/vips"
  require "fileutils"

  # Ensure asset directory exists
  ASSET_DIR = File.expand_path("../../assets", __dir__)
  FileUtils.mkdir_p(ASSET_DIR)
  SAMPLE_IMAGE = File.join(ASSET_DIR, "sample.jpg")

  RailsBenchmarkSuite.register_suite("Image Heft", weight: 0.1) do
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

rescue LoadError, StandardError => e
  # Register a skipped suite if Libvips is unavailable
  RailsBenchmarkSuite.register_suite("Image Heft (Skipped)", weight: 0.0) do
    @warned ||= begin
      warn "⚠️  [RailsBenchmarkSuite] ImageHeft skipped: #{e.message}. Install libvips to enable."
      true
    end
  end
end

