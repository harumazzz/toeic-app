package performance

import (
	"sync"

	db "github.com/toeic-app/internal/db/sqlc"
)

// ObjectPool provides object pooling for frequently allocated objects
type ObjectPool struct {
	wordResponsePool    *sync.Pool
	wordSlicePool       *sync.Pool
	grammarResponsePool *sync.Pool
	grammarSlicePool    *sync.Pool
	stringSlicePool     *sync.Pool
}

// WordResponse represents the API response structure for words
type WordResponse struct {
	ID            int32       `json:"id"`
	Word          string      `json:"word"`
	Pronounce     string      `json:"pronounce,omitempty"`
	Level         int32       `json:"level"`
	DescriptLevel string      `json:"descript_level,omitempty"`
	ShortMean     string      `json:"short_mean,omitempty"`
	Means         interface{} `json:"means,omitempty"`
	Snym          interface{} `json:"snym,omitempty"`
	Freq          float32     `json:"freq,omitempty"`
	Conjugation   interface{} `json:"conjugation,omitempty"`
}

// GrammarResponse represents the API response structure for grammars
type GrammarResponse struct {
	ID         int32       `json:"id"`
	Title      string      `json:"title"`
	GrammarKey string      `json:"grammar_key"`
	Level      int32       `json:"level"`
	Tag        interface{} `json:"tag,omitempty"`
	Contents   string      `json:"contents,omitempty"`
	Examples   interface{} `json:"examples,omitempty"`
}

// NewObjectPool creates a new object pool with optimized allocations
func NewObjectPool() *ObjectPool {
	return &ObjectPool{
		wordResponsePool: &sync.Pool{
			New: func() interface{} {
				return &WordResponse{}
			},
		},
		wordSlicePool: &sync.Pool{
			New: func() interface{} {
				// Pre-allocate slice with capacity 20 (common search result size)
				slice := make([]WordResponse, 0, 20)
				return &slice
			},
		},
		grammarResponsePool: &sync.Pool{
			New: func() interface{} {
				return &GrammarResponse{}
			},
		},
		grammarSlicePool: &sync.Pool{
			New: func() interface{} {
				slice := make([]GrammarResponse, 0, 20)
				return &slice
			},
		},
		stringSlicePool: &sync.Pool{
			New: func() interface{} {
				slice := make([]string, 0, 10)
				return &slice
			},
		},
	}
}

// GetWordResponse gets a WordResponse from the pool
func (p *ObjectPool) GetWordResponse() *WordResponse {
	return p.wordResponsePool.Get().(*WordResponse)
}

// PutWordResponse returns a WordResponse to the pool
func (p *ObjectPool) PutWordResponse(wr *WordResponse) {
	// Reset the object before returning to pool
	*wr = WordResponse{}
	p.wordResponsePool.Put(wr)
}

// GetWordSlice gets a word slice from the pool
func (p *ObjectPool) GetWordSlice() *[]WordResponse {
	slice := p.wordSlicePool.Get().(*[]WordResponse)
	*slice = (*slice)[:0] // Reset slice length but keep capacity
	return slice
}

// PutWordSlice returns a word slice to the pool
func (p *ObjectPool) PutWordSlice(slice *[]WordResponse) {
	if cap(*slice) < 100 { // Don't pool overly large slices
		p.wordSlicePool.Put(slice)
	}
}

// GetGrammarResponse gets a GrammarResponse from the pool
func (p *ObjectPool) GetGrammarResponse() *GrammarResponse {
	return p.grammarResponsePool.Get().(*GrammarResponse)
}

// PutGrammarResponse returns a GrammarResponse to the pool
func (p *ObjectPool) PutGrammarResponse(gr *GrammarResponse) {
	*gr = GrammarResponse{}
	p.grammarResponsePool.Put(gr)
}

// GetGrammarSlice gets a grammar slice from the pool
func (p *ObjectPool) GetGrammarSlice() *[]GrammarResponse {
	slice := p.grammarSlicePool.Get().(*[]GrammarResponse)
	*slice = (*slice)[:0]
	return slice
}

// PutGrammarSlice returns a grammar slice to the pool
func (p *ObjectPool) PutGrammarSlice(slice *[]GrammarResponse) {
	if cap(*slice) < 100 {
		p.grammarSlicePool.Put(slice)
	}
}

// GetStringSlice gets a string slice from the pool
func (p *ObjectPool) GetStringSlice() *[]string {
	slice := p.stringSlicePool.Get().(*[]string)
	*slice = (*slice)[:0]
	return slice
}

// PutStringSlice returns a string slice to the pool
func (p *ObjectPool) PutStringSlice(slice *[]string) {
	if cap(*slice) < 50 {
		p.stringSlicePool.Put(slice)
	}
}

// ConvertWordToResponse efficiently converts db.Word to WordResponse using object pool
func (p *ObjectPool) ConvertWordToResponse(word db.Word) *WordResponse {
	wr := p.GetWordResponse()
	wr.ID = word.ID
	wr.Word = word.Word
	wr.Pronounce = word.Pronounce
	wr.Level = word.Level
	wr.DescriptLevel = word.DescriptLevel
	wr.ShortMean = word.ShortMean
	wr.Means = word.Means.RawMessage
	wr.Snym = word.Snym.RawMessage
	wr.Freq = word.Freq
	wr.Conjugation = word.Conjugation.RawMessage
	return wr
}

// ConvertWordsToResponses efficiently converts a slice of db.Word to []WordResponse
func (p *ObjectPool) ConvertWordsToResponses(words []db.Word) []WordResponse {
	responses := p.GetWordSlice()
	defer p.PutWordSlice(responses)

	// Ensure we have enough capacity
	if cap(*responses) < len(words) {
		newSlice := make([]WordResponse, 0, len(words))
		responses = &newSlice
	}

	for _, word := range words {
		wr := p.GetWordResponse()
		wr.ID = word.ID
		wr.Word = word.Word
		wr.Pronounce = word.Pronounce
		wr.Level = word.Level
		wr.DescriptLevel = word.DescriptLevel
		wr.ShortMean = word.ShortMean
		wr.Means = word.Means.RawMessage
		wr.Snym = word.Snym.RawMessage
		wr.Freq = word.Freq
		wr.Conjugation = word.Conjugation.RawMessage

		*responses = append(*responses, *wr)
		p.PutWordResponse(wr)
	}

	// Return a copy of the slice since we're going to put the original back in the pool
	result := make([]WordResponse, len(*responses))
	copy(result, *responses)
	return result
}
