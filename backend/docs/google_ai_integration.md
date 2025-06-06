# Google AI Integration

This document explains how to set up and use the Google AI integration in the TOEIC app backend.

## Setup

### 1. Get Google AI API Key

1. Go to [Google AI Studio](https://ai.google.dev/)
2. Sign in with your Google account
3. Create a new API key
4. Copy the API key

### 2. Configure Environment Variables

Add the following to your `.env` file:

```env
GOOGLE_AI_API_KEY=your_google_ai_api_key_here
```

### 3. Install Dependencies

The go-genai dependency has already been added to your project:

```bash
go get github.com/google/generative-ai-go/genai
```

## Features

### AI Service

The AI service is automatically initialized when the server starts if a valid API key is provided. It uses the Gemini Pro model with the following configuration:

- **Model**: `gemini-pro`
- **Temperature**: 0.7 (controls randomness)
- **Top P**: 0.8 (nucleus sampling)
- **Top K**: 40 (top-k sampling)
- **Max Output Tokens**: 1024

### Safety Settings

The AI service is configured with safety filters to block harmful content:

- Harassment: Medium and above
- Hate Speech: Medium and above
- Sexually Explicit: Medium and above
- Dangerous Content: Medium and above

## API Endpoints

### 1. Check AI Status

```http
GET /api/v1/ai/status
```

Returns the status of the AI service and whether it's available.

### 2. Generate Content

```http
POST /api/v1/ai/generate
Content-Type: application/json
Authorization: Bearer <your_token>

{
  "prompt": "Write a short explanation about TOEIC exam structure"
}
```

### 3. Generate Exam Question

```http
POST /api/v1/ai/generate-question
Content-Type: application/json
Authorization: Bearer <your_token>

{
  "question_type": "reading comprehension",
  "difficulty": "intermediate",
  "topic": "business communication"
}
```

## Usage Examples

### Generate Content

```go
aiService := server.GetAIService()
if aiService != nil {
    content, err := aiService.GenerateContent(ctx, "Explain TOEIC listening section")
    if err != nil {
        // Handle error
    }
    // Use generated content
}
```

### Generate Exam Question

```go
question, err := aiService.GenerateExamQuestion(ctx, "listening", "beginner", "daily conversation")
```

## Error Handling

- If the API key is not provided, the AI service will not be initialized, but the server will still start
- If the API key is invalid, the service initialization will fail with a warning
- All AI endpoints will return a 503 Service Unavailable if the AI service is not available
- Rate limiting and authentication still apply to AI endpoints

## Security Considerations

- Keep your API key secure and never commit it to version control
- The API key should be stored in environment variables or a secure configuration system
- Monitor your API usage to avoid unexpected charges
- Consider implementing additional rate limiting for AI endpoints if needed

## Troubleshooting

### AI Service Not Available

1. Check if `GOOGLE_AI_API_KEY` is set in your environment
2. Verify the API key is valid
3. Check the server logs for initialization errors
4. Ensure you have internet connectivity

### API Quota Exceeded

Google AI has usage quotas. If you exceed them:

1. Check your usage in Google AI Studio
2. Consider upgrading your plan if needed
3. Implement additional rate limiting

### Invalid Responses

If the AI generates unexpected responses:

1. Adjust the prompt to be more specific
2. Modify the generation parameters (temperature, top_p, etc.)
3. Add additional validation on the response format
