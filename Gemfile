Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}" }

gemspec

# The noko seam needs moxml#584 fragment building (0.6.20); relax to
# the released ~> 0.6 constraint once consumers roll past 0.6.20.
gem "moxml", github: "lutaml/moxml", branch: "main"

eval_gemfile("Gemfile.devel") rescue nil
