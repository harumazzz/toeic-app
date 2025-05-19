package token

// BlacklistCount returns the number of tokens in the blacklist
func (maker *JWTMaker) BlacklistCount() int {
	if maker.blacklist != nil {
		return maker.blacklist.Count()
	}
	return 0
}
