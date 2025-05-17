package logger

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"runtime"
	"sync"
	"time"
)

// Log levels
const (
	LevelDebug = iota
	LevelInfo
	LevelWarn
	LevelError
	LevelFatal
)

var levelNames = map[int]string{
	LevelDebug: "DEBUG",
	LevelInfo:  "INFO",
	LevelWarn:  "WARN",
	LevelError: "ERROR",
	LevelFatal: "FATAL",
}

var levelColors = map[int]string{
	LevelDebug: "\033[37m", // White
	LevelInfo:  "\033[32m", // Green
	LevelWarn:  "\033[33m", // Yellow
	LevelError: "\033[31m", // Red
	LevelFatal: "\033[35m", // Purple
}

// Logger represents a logger instance
type Logger struct {
	level      int
	out        io.Writer
	file       *os.File
	mu         sync.Mutex
	useConsole bool
	useFile    bool
}

var defaultLogger *Logger
var once sync.Once

// GetLogger returns the default logger instance
func GetLogger() *Logger {
	once.Do(func() {
		defaultLogger = &Logger{
			level:      LevelInfo,
			out:        os.Stdout,
			useConsole: true,
			useFile:    false,
		}
	})
	return defaultLogger
}

// InitFileLogger initializes the logger to write to a file
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

	// Close existing file if any
	if logger.file != nil {
		logger.file.Close()
	}

	// Set new file and writer
	logger.file = file
	logger.out = io.MultiWriter(os.Stdout, file)
	logger.level = level
	logger.useFile = true

	return nil
}

// SetLevel sets the logging level
func (l *Logger) SetLevel(level int) {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.level = level
}

// formatMessage formats the log message with timestamp, level, and caller info
func (l *Logger) formatMessage(level int, message string) string {
	// Get caller information
	_, file, line, ok := runtime.Caller(3) // Skip 3 frames to get the actual caller
	callerInfo := "unknown"
	if ok {
		// Extract just the file name without the full path
		file = filepath.Base(file)
		callerInfo = fmt.Sprintf("%s:%d", file, line)
	}

	timestamp := time.Now().Format("2006/01/02 15:04:05.000")
	levelName := levelNames[level]

	// Format the message
	formattedMsg := fmt.Sprintf("[%s] [%s] [%s] %s", timestamp, levelName, callerInfo, message)

	// Add color if using console
	if l.useConsole && !l.useFile {
		return fmt.Sprintf("%s%s\033[0m", levelColors[level], formattedMsg)
	}

	return formattedMsg
}

// log logs a message at the specified level
func (l *Logger) log(level int, format string, args ...interface{}) {
	if level < l.level {
		return
	}

	l.mu.Lock()
	defer l.mu.Unlock()

	message := format
	if len(args) > 0 {
		message = fmt.Sprintf(format, args...)
	}

	formattedMessage := l.formatMessage(level, message)
	fmt.Fprintln(l.out, formattedMessage)

	// If it's a fatal message, exit the program
	if level == LevelFatal {
		os.Exit(1)
	}
}

// Debug logs a debug message
func (l *Logger) Debug(format string, args ...interface{}) {
	l.log(LevelDebug, format, args...)
}

// Info logs an info message
func (l *Logger) Info(format string, args ...interface{}) {
	l.log(LevelInfo, format, args...)
}

// Warn logs a warning message
func (l *Logger) Warn(format string, args ...interface{}) {
	l.log(LevelWarn, format, args...)
}

// Error logs an error message
func (l *Logger) Error(format string, args ...interface{}) {
	l.log(LevelError, format, args...)
}

// Fatal logs a fatal message and exits the program
func (l *Logger) Fatal(format string, args ...interface{}) {
	l.log(LevelFatal, format, args...)
}

// Global convenience functions

// Debug logs a debug message using the default logger
func Debug(format string, args ...interface{}) {
	GetLogger().Debug(format, args...)
}

// Info logs an info message using the default logger
func Info(format string, args ...interface{}) {
	GetLogger().Info(format, args...)
}

// Warn logs a warning message using the default logger
func Warn(format string, args ...interface{}) {
	GetLogger().Warn(format, args...)
}

// Error logs an error message using the default logger
func Error(format string, args ...interface{}) {
	GetLogger().Error(format, args...)
}

// Fatal logs a fatal message using the default logger and exits the program
func Fatal(format string, args ...interface{}) {
	GetLogger().Fatal(format, args...)
}
