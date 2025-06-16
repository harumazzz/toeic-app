package logger

import (
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"time"

	"github.com/sirupsen/logrus"
)

// Log levels
const (
	LevelDebug = iota
	LevelInfo
	LevelWarn
	LevelError
	LevelFatal
)

// Fields type for structured logging
type Fields map[string]interface{}

// Logger represents a structured logger instance
type Logger struct {
	logger *logrus.Logger
	mu     sync.Mutex
}

var defaultLogger *Logger
var once sync.Once

// GetLogger returns the default logger instance
func GetLogger() *Logger {
	once.Do(func() {
		defaultLogger = &Logger{
			logger: logrus.New(),
		}

		// Set default configuration
		defaultLogger.logger.SetLevel(logrus.InfoLevel)
		defaultLogger.logger.SetFormatter(&logrus.JSONFormatter{
			TimestampFormat: time.RFC3339,
			FieldMap: logrus.FieldMap{
				logrus.FieldKeyTime:  "timestamp",
				logrus.FieldKeyLevel: "level",
				logrus.FieldKeyMsg:   "message",
				logrus.FieldKeyFunc:  "function",
				logrus.FieldKeyFile:  "file",
			},
		})
		defaultLogger.logger.SetOutput(os.Stdout)
	})
	return defaultLogger
}

// InitFileLogger initializes the logger to write to both file and console
// It will create the logs directory if it doesn't exist
func InitFileLogger(logDir string, level int) error {
	logger := GetLogger()

	// Create logs directory if it doesn't exist
	if _, err := os.Stat(logDir); os.IsNotExist(err) {
		err = os.MkdirAll(logDir, 0755)
		if err != nil {
			return fmt.Errorf("failed to create log directory: %w", err)
		}
	}

	// Create log file with current date
	currentTime := time.Now().Format("2006-01-02")
	logPath := filepath.Join(logDir, fmt.Sprintf("app-%s.log", currentTime))

	file, err := os.OpenFile(logPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return fmt.Errorf("failed to open log file: %w", err)
	}

	logger.mu.Lock()
	defer logger.mu.Unlock()

	// Set up multi-writer to log to both file and console
	logger.logger.SetOutput(file)

	// Set log level
	switch level {
	case LevelDebug:
		logger.logger.SetLevel(logrus.DebugLevel)
	case LevelInfo:
		logger.logger.SetLevel(logrus.InfoLevel)
	case LevelWarn:
		logger.logger.SetLevel(logrus.WarnLevel)
	case LevelError:
		logger.logger.SetLevel(logrus.ErrorLevel)
	case LevelFatal:
		logger.logger.SetLevel(logrus.FatalLevel)
	default:
		logger.logger.SetLevel(logrus.InfoLevel)
	}

	return nil
}

// SetLevel sets the logging level
func (l *Logger) SetLevel(level int) {
	l.mu.Lock()
	defer l.mu.Unlock()

	switch level {
	case LevelDebug:
		l.logger.SetLevel(logrus.DebugLevel)
	case LevelInfo:
		l.logger.SetLevel(logrus.InfoLevel)
	case LevelWarn:
		l.logger.SetLevel(logrus.WarnLevel)
	case LevelError:
		l.logger.SetLevel(logrus.ErrorLevel)
	case LevelFatal:
		l.logger.SetLevel(logrus.FatalLevel)
	default:
		l.logger.SetLevel(logrus.InfoLevel)
	}
}

// getCallerInfo returns caller information for better debugging
func getCallerInfo() (string, int) {
	_, file, line, ok := runtime.Caller(3) // Skip 3 frames to get the actual caller
	if !ok {
		return "unknown", 0
	}
	// Extract just the file name without the full path
	fileName := filepath.Base(file)
	// Remove .go extension
	fileName = strings.TrimSuffix(fileName, ".go")
	return fileName, line
}

// WithFields creates a log entry with structured fields
func (l *Logger) WithFields(fields Fields) *logrus.Entry {
	file, line := getCallerInfo()

	// Add caller information to fields
	if fields == nil {
		fields = make(Fields)
	}
	fields["caller"] = fmt.Sprintf("%s:%d", file, line)

	return l.logger.WithFields(logrus.Fields(fields))
}

// WithField creates a log entry with a single structured field
func (l *Logger) WithField(key string, value interface{}) *logrus.Entry {
	file, line := getCallerInfo()

	return l.logger.WithFields(logrus.Fields{
		"caller": fmt.Sprintf("%s:%d", file, line),
		key:      value,
	})
}

// Debug logs a debug message with optional fields
func (l *Logger) Debug(format string, args ...interface{}) {
	file, line := getCallerInfo()
	entry := l.logger.WithField("caller", fmt.Sprintf("%s:%d", file, line))

	if len(args) > 0 {
		entry.Debugf(format, args...)
	} else {
		entry.Debug(format)
	}
}

// DebugWithFields logs a debug message with structured fields
func (l *Logger) DebugWithFields(fields Fields, format string, args ...interface{}) {
	file, line := getCallerInfo()
	if fields == nil {
		fields = make(Fields)
	}
	fields["caller"] = fmt.Sprintf("%s:%d", file, line)

	entry := l.logger.WithFields(logrus.Fields(fields))
	if len(args) > 0 {
		entry.Debugf(format, args...)
	} else {
		entry.Debug(format)
	}
}

// Info logs an info message with optional fields
func (l *Logger) Info(format string, args ...interface{}) {
	file, line := getCallerInfo()
	entry := l.logger.WithField("caller", fmt.Sprintf("%s:%d", file, line))

	if len(args) > 0 {
		entry.Infof(format, args...)
	} else {
		entry.Info(format)
	}
}

// InfoWithFields logs an info message with structured fields
func (l *Logger) InfoWithFields(fields Fields, format string, args ...interface{}) {
	file, line := getCallerInfo()
	if fields == nil {
		fields = make(Fields)
	}
	fields["caller"] = fmt.Sprintf("%s:%d", file, line)

	entry := l.logger.WithFields(logrus.Fields(fields))
	if len(args) > 0 {
		entry.Infof(format, args...)
	} else {
		entry.Info(format)
	}
}

// Warn logs a warning message with optional fields
func (l *Logger) Warn(format string, args ...interface{}) {
	file, line := getCallerInfo()
	entry := l.logger.WithField("caller", fmt.Sprintf("%s:%d", file, line))

	if len(args) > 0 {
		entry.Warnf(format, args...)
	} else {
		entry.Warn(format)
	}
}

// WarnWithFields logs a warning message with structured fields
func (l *Logger) WarnWithFields(fields Fields, format string, args ...interface{}) {
	file, line := getCallerInfo()
	if fields == nil {
		fields = make(Fields)
	}
	fields["caller"] = fmt.Sprintf("%s:%d", file, line)

	entry := l.logger.WithFields(logrus.Fields(fields))
	if len(args) > 0 {
		entry.Warnf(format, args...)
	} else {
		entry.Warn(format)
	}
}

// Error logs an error message with optional fields
func (l *Logger) Error(format string, args ...interface{}) {
	file, line := getCallerInfo()
	entry := l.logger.WithField("caller", fmt.Sprintf("%s:%d", file, line))

	if len(args) > 0 {
		entry.Errorf(format, args...)
	} else {
		entry.Error(format)
	}
}

// ErrorWithFields logs an error message with structured fields
func (l *Logger) ErrorWithFields(fields Fields, format string, args ...interface{}) {
	file, line := getCallerInfo()
	if fields == nil {
		fields = make(Fields)
	}
	fields["caller"] = fmt.Sprintf("%s:%d", file, line)

	entry := l.logger.WithFields(logrus.Fields(fields))
	if len(args) > 0 {
		entry.Errorf(format, args...)
	} else {
		entry.Error(format)
	}
}

// Fatal logs a fatal message and exits the program
func (l *Logger) Fatal(format string, args ...interface{}) {
	file, line := getCallerInfo()
	entry := l.logger.WithField("caller", fmt.Sprintf("%s:%d", file, line))

	if len(args) > 0 {
		entry.Fatalf(format, args...)
	} else {
		entry.Fatal(format)
	}
}

// FatalWithFields logs a fatal message with structured fields and exits the program
func (l *Logger) FatalWithFields(fields Fields, format string, args ...interface{}) {
	file, line := getCallerInfo()
	if fields == nil {
		fields = make(Fields)
	}
	fields["caller"] = fmt.Sprintf("%s:%d", file, line)

	entry := l.logger.WithFields(logrus.Fields(fields))
	if len(args) > 0 {
		entry.Fatalf(format, args...)
	} else {
		entry.Fatal(format)
	}
}

// Global convenience functions

// Debug logs a debug message using the default logger
func Debug(format string, args ...interface{}) {
	GetLogger().Debug(format, args...)
}

// DebugWithFields logs a debug message with structured fields using the default logger
func DebugWithFields(fields Fields, format string, args ...interface{}) {
	GetLogger().DebugWithFields(fields, format, args...)
}

// Info logs an info message using the default logger
func Info(format string, args ...interface{}) {
	GetLogger().Info(format, args...)
}

// InfoWithFields logs an info message with structured fields using the default logger
func InfoWithFields(fields Fields, format string, args ...interface{}) {
	GetLogger().InfoWithFields(fields, format, args...)
}

// Warn logs a warning message using the default logger
func Warn(format string, args ...interface{}) {
	GetLogger().Warn(format, args...)
}

// WarnWithFields logs a warning message with structured fields using the default logger
func WarnWithFields(fields Fields, format string, args ...interface{}) {
	GetLogger().WarnWithFields(fields, format, args...)
}

// Error logs an error message using the default logger
func Error(format string, args ...interface{}) {
	GetLogger().Error(format, args...)
}

// ErrorWithFields logs an error message with structured fields using the default logger
func ErrorWithFields(fields Fields, format string, args ...interface{}) {
	GetLogger().ErrorWithFields(fields, format, args...)
}

// Fatal logs a fatal message using the default logger and exits the program
func Fatal(format string, args ...interface{}) {
	GetLogger().Fatal(format, args...)
}

// FatalWithFields logs a fatal message with structured fields using the default logger and exits the program
func FatalWithFields(fields Fields, format string, args ...interface{}) {
	GetLogger().FatalWithFields(fields, format, args...)
}

// WithFields creates a log entry with structured fields using the default logger
func WithFields(fields Fields) *logrus.Entry {
	return GetLogger().WithFields(fields)
}

// WithField creates a log entry with a single structured field using the default logger
func WithField(key string, value interface{}) *logrus.Entry {
	return GetLogger().WithField(key, value)
}
