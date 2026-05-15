# Parser Package Entry Point
# This file includes all parser files without module wrapping
# All functions are included directly into the parent scope

# Parser needs CommonMark for parsing markdown
import CommonMark
using CommonMark: Heading, Paragraph, BlockQuote, List, FootnoteRule, Strong, Text, enable!

# Include all parser subfiles in dependency order
include("utils.jl")
include("core.jl")
include("manifest.jl")
include("taxonomy.jl")
include("norms.jl")
include("procedures.jl")
include("validation.jl")
