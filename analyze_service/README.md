# Word Level Analyzer API

A FastAPI service that analyzes English text and suggests synonyms with CEFR levels (A1, A2, B1, B2,
C1).

## Setup

1. Install dependencies:

```bash
pip install -r requirements.txt
```

2. Run the API server:

```bash
python api.py
```

The server will start at `http://localhost:8000`

## API Documentation

Once the server is running, you can access:

-   Interactive API documentation: `http://localhost:8000/docs`
-   Alternative API documentation: `http://localhost:8000/redoc`

## API Endpoints

### POST /analyze

Analyzes text and returns word levels with synonym suggestions.

Request body:

```json
{
	"text": "Your English text here",
	"min_synonym_level": "A2" // Optional, defaults to "A2"
}
```

Response:

```json
[
	{
		"word": "good",
		"level": "A1",
		"count": 1,
		"suggestions": [
			{
				"word": "excellent",
				"level": "B1",
				"definition": "of the highest quality"
			}
		]
	}
]
```

### GET /health

Health check endpoint.

Response:

```json
{
	"status": "healthy",
	"word_levels_loaded": true
}
```

## Example Usage

Using curl:

```bash
curl -X POST "http://localhost:8000/analyze" \
     -H "Content-Type: application/json" \
     -d '{"text": "This is a good text with some difficult words."}'
```

Using Python requests:

```python
import requests

response = requests.post(
    "http://localhost:8000/analyze",
    json={"text": "This is a good text with some difficult words."}
)
print(response.json())
```

## Docker Support

To run with Docker:

1. Build the image:

```bash
docker build -t word-level-analyzer .
```

2. Run the container:

```bash
docker run -p 8000:8000 word-level-analyzer
```
