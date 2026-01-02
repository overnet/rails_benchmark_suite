# frozen_string_literal: true

module RailsBenchmarkSuite
  module Reporter
    module_function

    def system_info
      {
        ruby_version: RUBY_VERSION,
        platform: RUBY_PLATFORM,
        processors: Concurrent.processor_count,
        libvips: libvips?,
        yjit: yjit_enabled?
      }
    end

    def yjit_enabled?
      defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled?
    end

    def libvips?
      # Naive check for libvips presence
      system("vips --version", out: File::NULL, err: File::NULL)
    end
  end
end
