package token

import (
	"fmt"
	"time"

	"github.com/dgrijalva/jwt-go"
)

const minSecretKeySize = 32

// JWTMaker is a JSON Web Token maker
type JWTMaker struct {
	secretKey string
	blacklist *TokenBlacklist
}

// NewJWTMaker creates a new JWTMaker
func NewJWTMaker(secretKey string) (Maker, error) {
	if len(secretKey) < minSecretKeySize {
		return nil, fmt.Errorf("invalid key size: must be at least %d characters", minSecretKeySize)
	}

	// Create a token blacklist with a cleanup interval of 1 hour
	blacklist := NewTokenBlacklist(1 * time.Hour)

	return &JWTMaker{
		secretKey: secretKey,
		blacklist: blacklist,
	}, nil
}

// CreateToken creates a new token for a specific username and duration
func (maker *JWTMaker) CreateToken(id int32, username string, duration time.Duration) (string, error) {
	payload, err := NewPayload(id, username, duration)
	if err != nil {
		return "", err
	}

	jwtToken := jwt.NewWithClaims(jwt.SigningMethodHS256, payload)
	return jwtToken.SignedString([]byte(maker.secretKey))
}

// VerifyToken checks if the token is valid or not
func (maker *JWTMaker) VerifyToken(token string) (*Payload, error) {
	// Check if the token is blacklisted before doing any other validation
	if maker.blacklist.IsBlacklisted(token) {
		return nil, ErrInvalidToken
	}

	keyFunc := func(token *jwt.Token) (interface{}, error) {
		_, ok := token.Method.(*jwt.SigningMethodHMAC)
		if !ok {
			return nil, ErrInvalidToken
		}
		return []byte(maker.secretKey), nil
	}
	jwtToken, err := jwt.ParseWithClaims(token, &Payload{}, keyFunc)
	if err != nil {
		verr, ok := err.(*jwt.ValidationError)
		if ok && verr.Errors == jwt.ValidationErrorExpired {
			return nil, ErrExpiredToken
		}
		return nil, ErrInvalidToken
	}
	payload, ok := jwtToken.Claims.(*Payload)
	if !ok {
		return nil, ErrInvalidToken
	}

	return payload, nil
}

// BlacklistToken adds a token to the blacklist
func (maker *JWTMaker) BlacklistToken(token string) error {
	// Parse the token to extract its expiry, even if it's expired
	keyFunc := func(token *jwt.Token) (interface{}, error) {
		_, ok := token.Method.(*jwt.SigningMethodHMAC)
		if !ok {
			return nil, ErrInvalidToken
		}
		return []byte(maker.secretKey), nil
	}

	// We need to extract payload even from expired tokens
	jwtToken, err := jwt.ParseWithClaims(token, &Payload{}, keyFunc)
	if err != nil {
		// Check if it's because the token is expired
		verr, ok := err.(*jwt.ValidationError)
		if !ok || (verr.Errors != jwt.ValidationErrorExpired && verr.Errors&jwt.ValidationErrorExpired == 0) {
			return ErrInvalidToken
		}
	}

	// Extract payload from token
	payload, ok := jwtToken.Claims.(*Payload)
	if !ok {
		return ErrInvalidToken
	}

	// Add to blacklist with the expiry time
	maker.blacklist.Add(token, payload.ExpiredAt)
	return nil
}

// Stop stops the token blacklist cleanup goroutine
func (maker *JWTMaker) Stop() {
	if maker.blacklist != nil {
		maker.blacklist.Stop()
	}
}
