module Sterile
  class << self
    alias_method :old_smart_format_rules, :smart_format_rules
=begin
# what would replace the Sterile rules with more broadly applicable \{Zs}
        [/(\p{Zs}|\A|"|\(|\[)'/, "\\1‘"],
        [/(\S)'([^\'\p{Zs}])/, "\\1’\\2"],
        [/(\p{Zs}|\A|\(|\[)"(?!\s)/, "\\1“\\2"],
        [/"(\p{Zs}|\S|\Z)/, "”\\1"],
        [/'([\p{Zs}.]|\Z)/, "’\\1"],
      ] + old_smart_format_rules
=end
    def smart_format_rules
      [
        [/(\S)'([^\'\p{Zs}])/, "\\1’\\2"],
        [/(\p{Zs})"(?!\s)/, "\\1“\\2"],
        [/"(\p{Zs})/, "”\\1"],
        [/'([\p{Zs}.])/, "’\\1"],
      ] + old_smart_format_rules
    end
  end
end
