import json
import re
from collections import Counter
import nltk
from nltk.corpus import wordnet

# Download required NLTK data
try:
    nltk.data.find('corpora/wordnet')
except LookupError:
    nltk.download('wordnet')

def load_word_levels():
    """Load word levels from all CSV files"""
    word_levels = {}
    csv_files = ['a1.csv', 'a2.csv', 'b1.csv', 'b2.csv', 'c1.csv']
    for file_path in csv_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                next(f)
                for line in f:
                    word, level = line.strip().split('|')
                    if word.lower() not in word_levels or level > word_levels[word.lower()]:
                        word_levels[word.lower()] = level
        except FileNotFoundError:
            print(f"Warning: {file_path} not found")
            continue
    
    return word_levels

def get_synonym_suggestions(word, word_levels, min_level='A2'):
    """Get synonym suggestions using WordNet"""
    suggestions = []
    synsets = wordnet.synsets(word.lower())
    all_synonyms = set()
    for synset in synsets:
        # Get lemmas (word forms) from the synset
        for lemma in synset.lemmas():
            # Get the word form and remove underscores
            synonym = lemma.name().replace('_', ' ')
            if synonym != word.lower():
                all_synonyms.add(synonym)
    for synonym in all_synonyms:
        level = word_levels.get(synonym.lower())
        if level and level >= min_level:
            suggestions.append({
                "word": synonym,
                "level": level,
                "definition": synsets[0].definition() if synsets else ""
            })
    
    return suggestions

def analyze_text(text, word_levels):
    """Analyze text and return word levels in JSON format"""
    words = re.findall(r'\b\w+\b', text.lower())
    word_counts = Counter(words)
    result = []
    for word, count in word_counts.items():
        level = word_levels.get(word)
        if level is not None:
            word_data = {
                "word": word,
                "level": level,
                "count": count
            }
            if level == 'A1' or count > 1:
                suggestions = get_synonym_suggestions(word, word_levels)
                if suggestions:
                    word_data["suggestions"] = suggestions
            
            result.append(word_data)
    
    # Sort by level and then by word
    result.sort(key=lambda x: (x["level"], x["word"]))
    
    return json.dumps(result, indent=2)