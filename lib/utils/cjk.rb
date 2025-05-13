module Metanorma
  module Utils
    class << self
      # Basic CJK scripts
      HAN = "\\p{Han}".freeze
      BOPOMOFO = "\\p{Bopomofo}".freeze
      HANGUL = "\\p{Hangul}".freeze
      HIRAGANA = "\\p{Hiragana}".freeze
      KATAKANA = "\\p{Katakana}".freeze
      
      # Script extensions - characters shared between scripts
      
      # CJK Symbols and Punctuation (U+3000–U+303F)
      # Used across all CJK scripts
      CJK_SYMBOLS = "[\\u3000-\\u303F]".freeze
      
      # CJK Punctuation (subset of CJK Symbols commonly used)
      CJK_PUNCTUATION = "[\\u3001-\\u3003\\u3008-\\u3011\\u3014-\\u301F]".freeze
      
      # Halfwidth and Fullwidth Forms (U+FF00–U+FFEF)
      # Used in all CJK contexts
      CJK_HALFWIDTH_FULLWIDTH = "[\\uFF00-\\uFFEF]".freeze
      
      # CJK Compatibility Forms (U+FE30–U+FE4F)
      # Primarily used with Han but relevant for all CJK
      CJK_COMPAT = "[\\uFE30-\\uFE4F]".freeze
      
      # Vertical Forms (U+FE10–U+FE1F)
      # Used in vertical text layout for all CJK
      CJK_VERTICAL = "[\\uFE10-\\uFE1F]".freeze
      
      # Small Form Variants (U+FE50–U+FE6F)
      # Used in all CJK contexts
      CJK_SMALL_FORMS = "[\\uFE50-\\uFE6F]".freeze
      
      # Ideographic Description Characters (U+2FF0–U+2FFF)
      # Used with Han script
      HAN_IDC = "[\\u2FF0-\\u2FFF]".freeze
      
      # Kanbun (U+3190–U+319F)
      # Used with Han script for Japanese
      KANBUN = "[\\u3190-\\u319F]".freeze
      
      # CJK Compatibility (U+3300–U+33FF)
      # Used with Han script
      CJK_COMPAT_IDEOGRAPHS = "[\\u3300-\\u33FF]".freeze
      
      # CJK Compatibility Ideographs (U+F900–U+FAFF)
      HAN_COMPAT_IDEOGRAPHS = "[\\uF900-\\uFAFF]".freeze
      
      # Script extensions by primary script
      HAN_EXTENSIONS = [
        HAN,
        CJK_SYMBOLS,
        CJK_PUNCTUATION,
        CJK_HALFWIDTH_FULLWIDTH,
        CJK_COMPAT,
        CJK_VERTICAL,
        CJK_SMALL_FORMS,
        HAN_IDC,
        KANBUN,
        CJK_COMPAT_IDEOGRAPHS,
        HAN_COMPAT_IDEOGRAPHS
      ].join("|").freeze
      
      HANGUL_EXTENSIONS = [
        HANGUL,
        CJK_SYMBOLS,
        CJK_PUNCTUATION,
        CJK_HALFWIDTH_FULLWIDTH,
        CJK_VERTICAL,
        CJK_SMALL_FORMS
      ].join("|").freeze
      
      HIRAGANA_EXTENSIONS = [
        HIRAGANA,
        CJK_SYMBOLS,
        CJK_PUNCTUATION,
        CJK_HALFWIDTH_FULLWIDTH,
        CJK_VERTICAL,
        CJK_SMALL_FORMS
      ].join("|").freeze
      
      KATAKANA_EXTENSIONS = [
        KATAKANA,
        CJK_SYMBOLS,
        CJK_PUNCTUATION,
        CJK_HALFWIDTH_FULLWIDTH,
        CJK_VERTICAL,
        CJK_SMALL_FORMS
      ].join("|").freeze
      
      BOPOMOFO_EXTENSIONS = [
        BOPOMOFO,
        CJK_SYMBOLS,
        CJK_PUNCTUATION,
        CJK_HALFWIDTH_FULLWIDTH
      ].join("|").freeze
      
      # Combined CJK pattern including all script extensions
      CJK = [
        HAN_EXTENSIONS,
        HANGUL_EXTENSIONS,
        HIRAGANA_EXTENSIONS,
        KATAKANA_EXTENSIONS,
        BOPOMOFO_EXTENSIONS
      ].join("|").freeze
    end
  end
end
