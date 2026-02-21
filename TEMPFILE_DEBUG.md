# Debug-Aware Tempfile System

This gem provides a debug-aware temporary file management system for the Metanorma stack.

## Overview

The `Metanorma::Utils::Tempfile` class is a drop-in replacement for Ruby's standard `Tempfile` that respects a debug configuration flag. When debug mode is enabled, temporary files are created but never deleted, allowing developers to inspect intermediate files during processing.

## Components

### 1. TempfileConfig (Singleton Configuration)

Controls the behavior of all `Metanorma::Utils::Tempfile` instances.

```ruby
# Enable debug mode (preserve temp files)
Metanorma::Utils::TempfileConfig.debug = true

# Disable debug mode (normal Tempfile behavior)
Metanorma::Utils::TempfileConfig.debug = false

# Check current mode
Metanorma::Utils::TempfileConfig.debug?  # => true or false
```

### 2. Metanorma::Utils::Tempfile

A subclass of Ruby's `Tempfile` with identical API, but deletion-aware in debug mode.

```ruby
# Use exactly like Ruby's Tempfile
file = Metanorma::Utils::Tempfile.new("prefix")
file.write("content")
file.close

# Or with a block
Metanorma::Utils::Tempfile.open("prefix") do |file|
  file.write("content")
end
```

## Integration Guide

### In metanorma-cli

Initialize debug mode at application startup:

```ruby
# In metanorma-cli initialization code
if options[:debug]
  Metanorma::Utils::TempfileConfig.debug = true
end
```

### In Other Gems (isodoc, metanorma-iso, etc.)

Replace `Tempfile` with `Metanorma::Utils::Tempfile`:

**Before:**
```ruby
require 'tempfile'

Tempfile.open(["image", ".svg"]) do |f|
  f.write(img.to_xml)
  # ... use f.path ...
end
```

**After:**
```ruby
# No require needed if metanorma-utils is already loaded

Metanorma::Utils::Tempfile.open(["image", ".svg"]) do |f|
  f.write(img.to_xml)
  # ... use f.path ...
end
```

## Behavior

### Normal Mode (debug=false)

- Files are created in the system temp directory
- Files are automatically deleted when:
  - `close(true)` is called
  - `unlink` or `delete` is called
  - The object is garbage collected (finalizer)
- **Identical to Ruby's standard Tempfile**

### Debug Mode (debug=true)

- Files are created in the system temp directory
- Files are **NEVER deleted** by any method:
  - `close(true)` → closes file but doesn't delete
  - `unlink` → no-op, file preserved
  - `delete` → no-op, file preserved
  - Finalizer → file preserved
- Files remain for manual inspection

## Example Usage

```ruby
# Enable debug mode
Metanorma::Utils::TempfileConfig.debug = true

# Create temp files - they will be preserved
file1 = Metanorma::Utils::Tempfile.new("test")
file1.write("debug content")
file1.close(true)  # File NOT deleted

puts "Temp file location: #{file1.path}"
# File still exists at this path for inspection!

# Disable debug mode for normal operation
Metanorma::Utils::TempfileConfig.debug = false
```

## Thread Safety

The configuration is thread-safe and can be safely accessed from multiple threads.

## API Compatibility

`Metanorma::Utils::Tempfile` inherits from `::Tempfile` and provides 100% API compatibility:
- All instance methods
- All class methods
- Same initialization signatures
- Same behavior (except deletion in debug mode)

## Testing

Run the test suite:

```bash
bundle exec rspec spec/tempfile_spec.rb
```

All 20 specs should pass, covering:
- Normal mode behavior
- Debug mode behavior
- Configuration management
- API compatibility
- Thread safety
