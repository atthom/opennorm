# ============================================================================
# Translation System for Multi-language Support
# ============================================================================

"""
    TranslationTable

Holds mappings from source language terms to target language terms.
"""
struct TranslationTable
    mappings::Dict{String, String}
    source_lang::String
    target_lang::String
end

"""
    load_translation_table(source_lang::String, target_lang::String, project_root::String)

Load translation table from stdlib/frameworks/universal/translations/{source_lang}-{target_lang}.md
Returns a TranslationTable with all mappings.
"""
function load_translation_table(source_lang::String, target_lang::String, project_root::String)
    # Construct path to translation file
    trans_file = joinpath(project_root, "stdlib", "frameworks", "universal", "translations", 
                         "$(lowercase(source_lang))-$(lowercase(target_lang)).md")
    
    if !isfile(trans_file)
        @warn "Translation file not found: $trans_file"
        return TranslationTable(Dict{String, String}(), source_lang, target_lang)
    end
    
    # Read and parse the translation file
    content = read(trans_file, String)
    mappings = Dict{String, String}()
    
    # Parse lines with format: "Source → Target"
    for line in split(content, '\n')
        line = strip(line)
        # Skip empty lines, headers, and comments
        if isempty(line) || startswith(line, '#') || startswith(line, "**") || startswith(line, ">")
            continue
        end
        
        # Match pattern: "- Source → Target"
        m = match(r"^-\s*(.+?)\s*→\s*(.+?)$", line)
        if m !== nothing
            source_term = strip(m.captures[1])
            target_term = strip(m.captures[2])
            mappings[source_term] = target_term
        end
    end
    
    return TranslationTable(mappings, source_lang, target_lang)
end

"""
    apply_translations(content::String, table::TranslationTable)

Apply translations to markdown content.
Translates section headers and taxonomy node names while preserving structure.
"""
function apply_translations(content::String, table::TranslationTable)
    if isempty(table.mappings)
        return content
    end
    
    lines = split(content, '\n')
    translated_lines = String[]
    
    for line in lines
        translated_line = line
        
        # Apply translations to the line
        # Sort by length (longest first) to avoid partial matches
        sorted_terms = sort(collect(keys(table.mappings)), by=length, rev=true)
        
        for source_term in sorted_terms
            target_term = table.mappings[source_term]
            
            # Replace whole words/phrases, being careful with special characters
            # Use word boundaries for single words, exact match for phrases
            if occursin(" ", source_term)
                # Multi-word phrase - exact match
                translated_line = replace(translated_line, source_term => target_term)
            else
                # Single word - use word boundaries
                # Match at start of line, after whitespace, or after certain punctuation (including single asterisks for italic markers)
                translated_line = replace(translated_line, 
                    Regex("(^|\\s|\\*\\*|\\*|##|###|-)\\K($source_term)(?=\\s|\$|:|\\*\\*|\\*|\\))") => target_term)
            end
        end
        
        push!(translated_lines, translated_line)
    end
    
    return join(translated_lines, '\n')
end

"""
    translate_document_if_needed(content::String, language::String, project_root::String)

Check if document needs translation and apply if necessary.
If language is not "EN", loads appropriate translation table and translates content.
"""
function translate_document_if_needed(content::String, language::String, project_root::String)
    # If already in English, no translation needed
    if uppercase(language) == "EN"
        return content
    end
    
    # Load translation table from source language to English
    table = load_translation_table(language, "EN", project_root)
    
    if isempty(table.mappings)
        @warn "No translations available for $(language) → EN, parsing document as-is"
        return content
    end
    
    # Apply translations
    translated_content = apply_translations(content, table)
    
    return translated_content
end