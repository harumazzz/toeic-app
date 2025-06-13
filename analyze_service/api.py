from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from word_level_analyzer import load_word_levels, analyze_text
import uvicorn
import os
import sys
import json
from typing import List, Optional

app = FastAPI(
    title="Word Level Analyzer API",
    description="API for analyzing English text and suggesting synonyms with CEFR levels",
    version="1.0.0"
)

# Load word levels once when starting the service
try:
    word_levels = load_word_levels()
    if not word_levels:
        print("Error: No word levels loaded. Please check your CSV files.")
        sys.exit(1)
except Exception as e:
    print(f"Error loading word levels: {str(e)}")
    sys.exit(1)

class Suggestion(BaseModel):
    word: str
    level: str
    definition: str

class WordAnalysis(BaseModel):
    word: str
    level: str
    count: int
    suggestions: Optional[List[Suggestion]] = None

class TextRequest(BaseModel):
    text: str
    min_synonym_level: str = "A2"  # Default minimum level for synonyms

@app.post("/analyze", response_model=List[WordAnalysis])
async def analyze_text_endpoint(request: TextRequest):
    """
    Analyze text and return word levels with synonym suggestions.
    
    - **text**: The English text to analyze
    - **min_synonym_level**: Minimum CEFR level for synonym suggestions (A2, B1, B2, C1)
    """
    try:
        result_json = analyze_text(request.text, word_levels)
        result_list = json.loads(result_json)
        return [WordAnalysis(**item) for item in result_list]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "word_levels_loaded": len(word_levels) > 0,
        "word_count": len(word_levels)
    }

def run():
    # Get port from environment variable or use default
    port = int(os.getenv("PORT", 9000))
    print(f"Starting analysis service on port {port}")
    
    try:
        uvicorn.run(app, host="0.0.0.0", port=port)
    except OSError as e:
        if "address already in use" in str(e).lower():
            print(f"Error: Port {port} is already in use")
        raise e
    