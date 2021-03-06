require "mkmf"

File.write "Makefile", dummy_makefile(?.).join
unless Gem::Platform.local.os == "darwin" && ENV["RBENV_ROOT"] && ENV["RBENV_VERSION"]
else
  unless Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.3.8")
    # https://github.com/rbenv/rbenv/issues/1199
    if found = Dir.glob("#{ENV["RBENV_ROOT"]}/sources/#{ENV["RBENV_VERSION"]}/ruby-*/").first
    append_cppflags "-I#{found}"
    append_cppflags "-DRUBY_EXPORT" unless Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.4")
    create_makefile "idhash"
    # Why this hack?
    # 1. Because I want to use Ruby and ./idhash.bundle for tests, not C.
    # 2. Because I don't want to bother users with two gems instead of one.
    File.write "Makefile", <<~HEREDOC + File.read("Makefile")
      .PHONY: test
      test: all
      \t$(RUBY) -r./lib/dhash-vips.rb ./lib/dhash-vips-post-install-test.rb
    HEREDOC
    end
  end
end

# Cases to check:
# 0. everything is ok
# `rm -f idhash.o idhash.bundle idhash.so Makefile && ruby extconf.rb && make`
# `bundle exec rake -rdhash-vips -e "p DHashVips::IDHash.method(:distance3).source_location"`
# => # ["/Users/nakilon/_/dhash-vips/lib/dhash-vips.rb", 52] # or 42 with Ruby<2.4
# => # ["/Users/nakilon/_/dhash-vips/lib/dhash-vips.rb", 32] # if LoadError
# 1. not macOS && rbenv
# 2. fail during append_cppflags
# 3. failed compilation
# 4. failed tests
