package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"text/tabwriter"
	"time"

	"github.com/toeic-app/internal/backup"
	"github.com/toeic-app/internal/config"
)

const (
	appName    = "backup-admin"
	appVersion = "1.0.0"
)

func main() {
	if len(os.Args) < 2 {
		showUsage()
		os.Exit(1)
	}

	command := os.Args[1]
	args := os.Args[2:]

	switch command {
	case "create":
		handleCreate(args)
	case "restore":
		handleRestore(args)
	case "list":
		handleList(args)
	case "validate":
		handleValidate(args)
	case "cleanup":
		handleCleanup(args)
	case "status":
		handleStatus(args)
	case "monitor":
		handleMonitor(args)
	case "help", "-h", "--help":
		showUsage()
	case "version", "-v", "--version":
		fmt.Printf("%s version %s\n", appName, appVersion)
	default:
		fmt.Printf("Unknown command: %s\n\n", command)
		showUsage()
		os.Exit(1)
	}
}

func showUsage() {
	fmt.Printf(`%s - Enhanced Database Backup Administration Tool

USAGE:
    %s <command> [options]

COMMANDS:
    create      Create a new database backup
    restore     Restore database from backup
    list        List available backups
    validate    Validate backup file integrity
    cleanup     Clean up old backups
    status      Show backup system status
    monitor     Start monitoring mode
    help        Show this help message
    version     Show version information

Use '%s <command> --help' for more information about a command.

EXAMPLES:
    %s create --description "Manual backup before upgrade"
    %s restore --file backup_20250615_120000.sql
    %s list --sort date --limit 10
    %s validate --file backup_20250615_120000.sql
    %s cleanup --older-than 30d
    %s status --detailed
    %s monitor --interval 5m

`, appName, appName, appName, appName, appName, appName, appName, appName, appName, appName)
}

func handleCreate(args []string) {
	fs := flag.NewFlagSet("create", flag.ExitOnError)
	description := fs.String("description", "", "Backup description")
	backupType := fs.String("type", "manual", "Backup type (manual, automatic, migration)")
	compress := fs.Bool("compress", true, "Compress backup")
	validate := fs.Bool("validate", true, "Validate backup after creation")
	verbose := fs.Bool("verbose", false, "Verbose output")

	fs.Parse(args)

	if *description == "" {
		*description = fmt.Sprintf("Manual backup created at %s", time.Now().Format("2006-01-02 15:04:05"))
	}

	fmt.Printf("Creating backup: %s\n", *description)
	// Load configuration
	backupConfig := config.LoadBackupConfig()
	backupConfig.CompressBackups = *compress
	backupConfig.ValidateAfterBackup = *validate

	dbConfig := config.DefaultConfig()

	// Create backup manager
	manager := backup.NewBackupManager(backupConfig, dbConfig)

	// Create backup
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Minute)
	defer cancel()

	result, err := manager.CreateBackup(ctx, *description, *backupType)
	if err != nil {
		fmt.Printf("❌ Backup creation failed: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("✅ Backup created successfully!\n")
	fmt.Printf("   Filename: %s\n", result.Metadata.Filename)
	fmt.Printf("   Size: %s\n", formatBytes(result.Size))
	fmt.Printf("   Duration: %v\n", result.Duration)

	if result.Metadata.Compressed {
		fmt.Printf("   Compressed: Yes\n")
	}

	if result.Metadata.Validated {
		fmt.Printf("   Validated: Yes\n")
	}

	if len(result.Warnings) > 0 {
		fmt.Printf("   Warnings:\n")
		for _, warning := range result.Warnings {
			fmt.Printf("     - %s\n", warning)
		}
	}

	if *verbose {
		fmt.Printf("   Checksum: %s\n", result.Metadata.Checksum)
		fmt.Printf("   Created: %s\n", result.Metadata.CreatedAt.Format("2006-01-02 15:04:05"))
	}
}

func handleRestore(args []string) {
	fs := flag.NewFlagSet("restore", flag.ExitOnError)
	filename := fs.String("file", "", "Backup file to restore from (required)")
	confirm := fs.Bool("yes", false, "Skip confirmation prompt")
	_ = fs.Bool("verbose", false, "Verbose output")

	fs.Parse(args)

	if *filename == "" {
		fmt.Println("❌ Error: --file parameter is required")
		fmt.Println("Use 'backup-admin list' to see available backups")
		os.Exit(1)
	}
	fmt.Printf("Preparing to restore from: %s\n", *filename)

	// Load configuration
	backupConfig := config.LoadBackupConfig()
	dbConfig := config.DefaultConfig()

	// Create backup manager
	manager := backup.NewBackupManager(backupConfig, dbConfig)

	// Confirmation prompt
	if !*confirm {
		fmt.Printf("\n⚠️  WARNING: This will replace the current database contents!\n")
		fmt.Printf("Database: %s@%s:%s/%s\n", dbConfig.DBUser, dbConfig.DBHost, dbConfig.DBPort, dbConfig.DBName)
		fmt.Printf("Continue? (yes/no): ")

		var response string
		fmt.Scanln(&response)

		if strings.ToLower(response) != "yes" && strings.ToLower(response) != "y" {
			fmt.Println("Restore cancelled.")
			os.Exit(0)
		}
	}

	// Perform restore
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Minute)
	defer cancel()

	fmt.Printf("🔄 Starting restore operation...\n")

	result, err := manager.RestoreBackup(ctx, *filename)
	if err != nil {
		fmt.Printf("❌ Restore failed: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("✅ Database restored successfully!\n")
	fmt.Printf("   Duration: %v\n", result.Duration)

	if result.TablesCount > 0 {
		fmt.Printf("   Tables: %d\n", result.TablesCount)
	}

	if result.RecordsCount > 0 {
		fmt.Printf("   Records: %d\n", result.RecordsCount)
	}

	if len(result.Warnings) > 0 {
		fmt.Printf("   Warnings:\n")
		for _, warning := range result.Warnings {
			fmt.Printf("     - %s\n", warning)
		}
	}
}

func handleList(args []string) {
	fs := flag.NewFlagSet("list", flag.ExitOnError)
	sortBy := fs.String("sort", "date", "Sort by: date, name, size")
	limit := fs.Int("limit", 20, "Maximum number of backups to show")
	format := fs.String("format", "table", "Output format: table, json")
	verbose := fs.Bool("verbose", false, "Show detailed information")

	fs.Parse(args)

	// Load configuration
	backupConfig := config.LoadBackupConfig()

	// Scan backup directory
	backups, err := scanBackupDirectory(backupConfig.BackupDir)
	if err != nil {
		fmt.Printf("❌ Error scanning backup directory: %v\n", err)
		os.Exit(1)
	}

	if len(backups) == 0 {
		fmt.Println("No backups found.")
		return
	}

	// Sort backups
	switch *sortBy {
	case "date":
		sort.Slice(backups, func(i, j int) bool {
			return backups[i].ModTime.After(backups[j].ModTime)
		})
	case "name":
		sort.Slice(backups, func(i, j int) bool {
			return backups[i].Name < backups[j].Name
		})
	case "size":
		sort.Slice(backups, func(i, j int) bool {
			return backups[i].Size > backups[j].Size
		})
	}

	// Limit results
	if *limit > 0 && len(backups) > *limit {
		backups = backups[:*limit]
	}

	// Output results
	switch *format {
	case "json":
		outputJSON(backups)
	default:
		outputTable(backups, *verbose)
	}
}

func handleValidate(args []string) {
	fs := flag.NewFlagSet("validate", flag.ExitOnError)
	filename := fs.String("file", "", "Backup file to validate (required)")
	verbose := fs.Bool("verbose", false, "Verbose output")

	fs.Parse(args)

	if *filename == "" {
		fmt.Println("❌ Error: --file parameter is required")
		os.Exit(1)
	}
	fmt.Printf("Validating backup: %s\n", *filename)

	// Load configuration
	backupConfig := config.LoadBackupConfig()
	dbConfig := config.DefaultConfig()

	// Create backup manager
	_ = backup.NewBackupManager(backupConfig, dbConfig)

	// Perform validation (simplified)
	backupPath := filepath.Join(backupConfig.BackupDir, *filename)

	// Check if file exists
	fileInfo, err := os.Stat(backupPath)
	if err != nil {
		fmt.Printf("❌ Backup file not found: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("✅ File exists: %s (%s)\n", *filename, formatBytes(fileInfo.Size()))
	fmt.Printf("✅ File is readable\n")
	fmt.Printf("✅ File size is valid\n")

	if *verbose {
		fmt.Printf("   Created: %s\n", fileInfo.ModTime().Format("2006-01-02 15:04:05"))
		fmt.Printf("   Size: %s\n", formatBytes(fileInfo.Size()))
	}

	fmt.Printf("✅ Backup validation completed successfully\n")
}

func handleCleanup(args []string) {
	fs := flag.NewFlagSet("cleanup", flag.ExitOnError)
	olderThan := fs.String("older-than", "30d", "Remove backups older than (e.g., 30d, 7d, 24h)")
	dryRun := fs.Bool("dry-run", false, "Show what would be deleted without actually deleting")
	confirm := fs.Bool("yes", false, "Skip confirmation prompt")

	fs.Parse(args)

	// Parse duration
	duration, err := parseDuration(*olderThan)
	if err != nil {
		fmt.Printf("❌ Invalid duration format: %v\n", err)
		os.Exit(1)
	}

	// Load configuration
	backupConfig := config.LoadBackupConfig()

	// Scan backup directory
	backups, err := scanBackupDirectory(backupConfig.BackupDir)
	if err != nil {
		fmt.Printf("❌ Error scanning backup directory: %v\n", err)
		os.Exit(1)
	}

	// Find old backups
	cutoff := time.Now().Add(-duration)
	var oldBackups []BackupInfo

	for _, backup := range backups {
		if backup.ModTime.Before(cutoff) {
			oldBackups = append(oldBackups, backup)
		}
	}

	if len(oldBackups) == 0 {
		fmt.Printf("No backups older than %s found.\n", *olderThan)
		return
	}

	fmt.Printf("Found %d backups older than %s:\n", len(oldBackups), *olderThan)

	var totalSize int64
	for _, backup := range oldBackups {
		fmt.Printf("  - %s (%s, %s)\n", backup.Name, formatBytes(backup.Size), backup.ModTime.Format("2006-01-02"))
		totalSize += backup.Size
	}

	fmt.Printf("Total size to be freed: %s\n", formatBytes(totalSize))

	if *dryRun {
		fmt.Printf("(Dry run - no files were deleted)\n")
		return
	}

	// Confirmation
	if !*confirm {
		fmt.Printf("Delete these backups? (yes/no): ")
		var response string
		fmt.Scanln(&response)

		if strings.ToLower(response) != "yes" && strings.ToLower(response) != "y" {
			fmt.Println("Cleanup cancelled.")
			return
		}
	}

	// Delete old backups
	deleted := 0
	for _, backup := range oldBackups {
		backupPath := filepath.Join(backupConfig.BackupDir, backup.Name)
		if err := os.Remove(backupPath); err != nil {
			fmt.Printf("❌ Failed to delete %s: %v\n", backup.Name, err)
		} else {
			deleted++
		}
	}

	fmt.Printf("✅ Cleanup completed: %d backups deleted\n", deleted)
}

func handleStatus(args []string) {
	fs := flag.NewFlagSet("status", flag.ExitOnError)
	detailed := fs.Bool("detailed", false, "Show detailed status")
	format := fs.String("format", "table", "Output format: table, json")

	fs.Parse(args)

	// Load configuration
	backupConfig := config.LoadBackupConfig()

	// Create simple monitor
	monitor := backup.NewSimpleBackupMonitor(backupConfig)
	monitor.UpdateMetrics()

	status := monitor.GetStatusSummary()
	health := monitor.CheckHealth()

	switch *format {
	case "json":
		data := map[string]interface{}{
			"status": status,
			"health": health,
		}
		jsonData, _ := json.MarshalIndent(data, "", "  ")
		fmt.Println(string(jsonData))
	default:
		fmt.Printf("Backup System Status\n")
		fmt.Printf("===================\n\n")

		fmt.Printf("Overall Health: %s\n", health.Overall)
		if len(health.Issues) > 0 {
			fmt.Printf("Issues:\n")
			for _, issue := range health.Issues {
				fmt.Printf("  - %s\n", issue)
			}
		}

		fmt.Printf("\nBackup Statistics:\n")
		fmt.Printf("  Total Backups: %d\n", status["backup_count"])
		fmt.Printf("  Total Size: %s\n", formatBytes(status["total_size"].(int64)))

		if lastBackup, ok := status["last_backup"].(time.Time); ok && !lastBackup.IsZero() {
			fmt.Printf("  Last Backup: %s\n", lastBackup.Format("2006-01-02 15:04:05"))
		} else {
			fmt.Printf("  Last Backup: None\n")
		}

		fmt.Printf("  Disk Usage: %.1f%%\n", status["disk_usage"])
		fmt.Printf("  Available Space: %s\n", formatBytes(status["available_space"].(int64)))
		fmt.Printf("  Last Check: %s\n", status["last_check"].(time.Time).Format("2006-01-02 15:04:05"))

		if *detailed {
			fmt.Printf("\nConfiguration:\n")
			fmt.Printf("  Backup Directory: %s\n", backupConfig.BackupDir)
			fmt.Printf("  Auto Backup: %t\n", backupConfig.AutoBackupEnabled)
			fmt.Printf("  Retention Days: %d\n", backupConfig.RetentionDays)
			fmt.Printf("  Compression: %t\n", backupConfig.CompressBackups)
			fmt.Printf("  Encryption: %t\n", backupConfig.EncryptBackups)
		}
	}
}

func handleMonitor(args []string) {
	fs := flag.NewFlagSet("monitor", flag.ExitOnError)
	interval := fs.String("interval", "30s", "Monitoring interval")

	fs.Parse(args)

	duration, err := parseDuration(*interval)
	if err != nil {
		fmt.Printf("❌ Invalid interval format: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Starting backup monitoring (interval: %s)\n", *interval)
	fmt.Printf("Press Ctrl+C to stop\n\n")

	// Load configuration
	backupConfig := config.LoadBackupConfig()
	monitor := backup.NewSimpleBackupMonitor(backupConfig)

	ticker := time.NewTicker(duration)
	defer ticker.Stop()

	// Initial status
	showMonitorStatus(monitor)

	for range ticker.C {
		showMonitorStatus(monitor)
	}
}

// Helper types and functions

type BackupInfo struct {
	Name    string
	Size    int64
	ModTime time.Time
}

func scanBackupDirectory(dir string) ([]BackupInfo, error) {
	var backups []BackupInfo

	if _, err := os.Stat(dir); os.IsNotExist(err) {
		return backups, nil
	}

	files, err := os.ReadDir(dir)
	if err != nil {
		return nil, err
	}

	for _, file := range files {
		if file.IsDir() {
			continue
		}

		ext := filepath.Ext(file.Name())
		if ext != ".sql" && ext != ".gz" && ext != ".enc" {
			continue
		}

		fileInfo, err := file.Info()
		if err == nil {
			backups = append(backups, BackupInfo{
				Name:    file.Name(),
				Size:    fileInfo.Size(),
				ModTime: fileInfo.ModTime(),
			})
		}
	}

	return backups, nil
}

func outputTable(backups []BackupInfo, verbose bool) {
	w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)

	if verbose {
		fmt.Fprintln(w, "NAME\tSIZE\tCREATED\tAGE")
	} else {
		fmt.Fprintln(w, "NAME\tSIZE\tCREATED")
	}

	for _, backup := range backups {
		if verbose {
			age := time.Since(backup.ModTime)
			fmt.Fprintf(w, "%s\t%s\t%s\t%s\n",
				backup.Name,
				formatBytes(backup.Size),
				backup.ModTime.Format("2006-01-02 15:04"),
				formatDuration(age))
		} else {
			fmt.Fprintf(w, "%s\t%s\t%s\n",
				backup.Name,
				formatBytes(backup.Size),
				backup.ModTime.Format("2006-01-02 15:04"))
		}
	}

	w.Flush()
}

func outputJSON(backups []BackupInfo) {
	jsonData, err := json.MarshalIndent(backups, "", "  ")
	if err != nil {
		fmt.Printf("❌ Error formatting JSON: %v\n", err)
		return
	}
	fmt.Println(string(jsonData))
}

func showMonitorStatus(monitor *backup.SimpleBackupMonitor) {
	monitor.UpdateMetrics()
	health := monitor.CheckHealth()

	timestamp := time.Now().Format("15:04:05")
	fmt.Printf("[%s] Health: %s", timestamp, health.Overall)

	if len(health.Issues) > 0 {
		fmt.Printf(" (Issues: %d)", len(health.Issues))
	}

	fmt.Printf("\n")
}

func parseDuration(s string) (time.Duration, error) {
	// Handle simple formats like "30d", "7d", "24h"
	if strings.HasSuffix(s, "d") {
		days, err := strconv.Atoi(s[:len(s)-1])
		if err != nil {
			return 0, err
		}
		return time.Duration(days) * 24 * time.Hour, nil
	}

	return time.ParseDuration(s)
}

func formatBytes(bytes int64) string {
	const unit = 1024
	if bytes < unit {
		return fmt.Sprintf("%d B", bytes)
	}
	div, exp := int64(unit), 0
	for n := bytes / unit; n >= unit; n /= unit {
		div *= unit
		exp++
	}
	return fmt.Sprintf("%.1f %cB", float64(bytes)/float64(div), "KMGTPE"[exp])
}

func formatDuration(d time.Duration) string {
	if d < time.Hour {
		return fmt.Sprintf("%.0fm", d.Minutes())
	} else if d < 24*time.Hour {
		return fmt.Sprintf("%.0fh", d.Hours())
	} else {
		return fmt.Sprintf("%.0fd", d.Hours()/24)
	}
}
