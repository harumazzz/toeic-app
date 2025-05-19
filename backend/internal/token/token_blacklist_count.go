package token

// Count returns the number of tokens currently in the blacklist
func (tb *TokenBlacklist) Count() int {
	tb.mu.RLock()
	defer tb.mu.RUnlock()
	return len(tb.blacklistedTokens)
}
