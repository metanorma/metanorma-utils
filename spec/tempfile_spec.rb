require "spec_helper"
require "tempfile"

RSpec.describe Metanorma::Utils::Tempfile do
  # Reset debug mode before each test
  before(:each) do
    Metanorma::Utils::TempfileConfig.debug = false
  end

  describe "normal mode (debug=false)" do
    it "creates a temporary file" do
      file = Metanorma::Utils::Tempfile.new("test")
      expect(File.exist?(file.path)).to be true
      path = file.path
      file.close
      expect(File.exist?(path)).to be true
      file.unlink
      expect(File.exist?(path)).to be false
    end

    it "deletes file when close(true) is called" do
      file = Metanorma::Utils::Tempfile.new("test")
      path = file.path
      file.write("test content")
      file.close(true)
      expect(File.exist?(path)).to be false
    end

    it "deletes file when unlink is called" do
      file = Metanorma::Utils::Tempfile.new("test")
      path = file.path
      file.close
      expect(File.exist?(path)).to be true
      file.unlink
      expect(File.exist?(path)).to be false
    end

    it "deletes file when delete is called" do
      file = Metanorma::Utils::Tempfile.new("test")
      path = file.path
      file.close
      expect(File.exist?(path)).to be true
      file.delete
      expect(File.exist?(path)).to be false
    end

    it "works with open block syntax" do
      path = nil
      Metanorma::Utils::Tempfile.open("test") do |file|
        path = file.path
        file.write("content")
        expect(File.exist?(path)).to be true
      end
      # Note: File deletion in block form happens via finalizer
      # which may be delayed, so we just verify the file was created
      expect(path).not_to be_nil
      expect(Pathname.new(path).absolute?).to be true
    end

    it "supports writing and reading" do
      file = Metanorma::Utils::Tempfile.new("test")
      file.write("test content")
      file.rewind
      expect(file.read).to eq("test content")
      file.close
      file.unlink
    end

    it "accepts tmpdir parameter" do
      tmpdir = Dir.tmpdir
      file = Metanorma::Utils::Tempfile.new("test", tmpdir)
      expect(file.path).to start_with(tmpdir)
      file.close
      file.unlink
    end
  end

  describe "debug mode (debug=true)" do
    before(:each) do
      Metanorma::Utils::TempfileConfig.debug = true
    end

    after(:each) do
      # Clean up any files created during debug mode tests
      Metanorma::Utils::TempfileConfig.debug = false
    end

    it "creates a temporary file" do
      file = Metanorma::Utils::Tempfile.new("test")
      expect(File.exist?(file.path)).to be true
      file.close
    end

    it "does not delete file when close(true) is called" do
      file = Metanorma::Utils::Tempfile.new("test")
      path = file.path
      file.write("preserved content")
      file.close(true)
      expect(File.exist?(path)).to be true

      # Cleanup
      File.unlink(path) if File.exist?(path)
    end

    it "does not delete file when unlink is called" do
      file = Metanorma::Utils::Tempfile.new("test")
      path = file.path
      file.close
      file.unlink
      expect(File.exist?(path)).to be true

      # Cleanup
      File.unlink(path) if File.exist?(path)
    end

    it "does not delete file when delete is called" do
      file = Metanorma::Utils::Tempfile.new("test")
      path = file.path
      file.close
      file.delete
      expect(File.exist?(path)).to be true

      # Cleanup
      File.unlink(path) if File.exist?(path)
    end

    it "does not delete file after open block" do
      path = nil
      Metanorma::Utils::Tempfile.open("test") do |file|
        path = file.path
        file.write("content")
        expect(File.exist?(path)).to be true
      end
      # File should still exist after block in debug mode
      expect(File.exist?(path)).to be true

      # Cleanup
      File.unlink(path) if File.exist?(path)
    end

    it "preserves file content" do
      file = Metanorma::Utils::Tempfile.new("test")
      path = file.path
      file.write("debug content")
      file.close(true)

      # File should exist and contain the content
      expect(File.exist?(path)).to be true
      expect(File.read(path)).to eq("debug content")

      # Cleanup
      File.unlink(path) if File.exist?(path)
    end

    it "allows multiple deletion attempts without error" do
      file = Metanorma::Utils::Tempfile.new("test")
      path = file.path
      file.close

      expect { file.unlink }.not_to raise_error
      expect { file.delete }.not_to raise_error
      expect { file.close(true) }.not_to raise_error

      expect(File.exist?(path)).to be true

      # Cleanup
      File.unlink(path) if File.exist?(path)
    end
  end

  describe Metanorma::Utils::TempfileConfig do
    it "defaults to debug=false" do
      # Create a fresh state
      config = Metanorma::Utils::TempfileConfig
      expect(config.debug?).to be false
    end

    it "allows setting debug mode" do
      Metanorma::Utils::TempfileConfig.debug = true
      expect(Metanorma::Utils::TempfileConfig.debug?).to be true

      Metanorma::Utils::TempfileConfig.debug = false
      expect(Metanorma::Utils::TempfileConfig.debug?).to be false
    end

    it "coerces non-boolean values to boolean" do
      Metanorma::Utils::TempfileConfig.debug = "true"
      expect(Metanorma::Utils::TempfileConfig.debug?).to be true

      Metanorma::Utils::TempfileConfig.debug = nil
      expect(Metanorma::Utils::TempfileConfig.debug?).to be false

      Metanorma::Utils::TempfileConfig.debug = 1
      expect(Metanorma::Utils::TempfileConfig.debug?).to be true
    end

    it "is thread-safe" do
      threads = 10.times.map do |i|
        Thread.new do
          100.times do
            Metanorma::Utils::TempfileConfig.debug = (i % 2).zero?
            Metanorma::Utils::TempfileConfig.debug?
          end
        end
      end

      expect { threads.each(&:join) }.not_to raise_error
    end
  end

  describe "API compatibility with Tempfile" do
    it "responds to all core Tempfile instance methods" do
      file = Metanorma::Utils::Tempfile.new("test")

      # Test key Tempfile methods
      core_methods = %i[path close unlink delete closed?
                        write read rewind size length]

      core_methods.each do |method|
        expect(file).to respond_to(method),
                        "Metanorma::Utils::Tempfile should respond to #{method}"
      end

      file.close
      file.unlink
    end

    it "is a subclass of Tempfile" do
      expect(Metanorma::Utils::Tempfile.ancestors).to include(::Tempfile)
    end
  end
end
