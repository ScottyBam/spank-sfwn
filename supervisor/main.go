package main

import (
	"context"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"syscall"
	"time"
)

// Config mirrors ~/.config/spank/config.json
type Config struct {
	Enabled       bool    `json:"enabled"`
	Pack          string  `json:"pack"`
	Escalate      bool    `json:"escalate"`
	Fast          bool    `json:"fast"`
	VolumeScaling bool    `json:"volumeScaling"`
	Sensitivity   float64 `json:"sensitivity"`
	Speed         float64 `json:"speed"`
	Cooldown      int     `json:"cooldown"`
}

func defaultConfig() Config {
	return Config{
		Enabled:     true,
		Pack:        "pain",
		Sensitivity: 0.05,
		Speed:       1.0,
		Cooldown:    750,
	}
}

// buildFlags translates a Config into spank CLI arguments.
// homeDir must be the real user home (e.g. /Users/alice), not ~.
func buildFlags(cfg Config, homeDir string) []string {
	var flags []string

	switch cfg.Pack {
	case "sexy":
		flags = append(flags, "--sexy")
	case "halo":
		flags = append(flags, "--halo")
	case "pain", "":
		// default pack — no pack flag
	default:
		// nikke/<Name> or any custom path format
		flags = append(flags, "--custom",
			filepath.Join(homeDir, "spank-sounds", filepath.FromSlash(cfg.Pack)))
	}

	if cfg.Escalate {
		flags = append(flags, "--escalate")
	}
	if cfg.Fast {
		flags = append(flags, "--fast")
	}
	if cfg.VolumeScaling {
		flags = append(flags, "--volume-scaling")
	}

	flags = append(flags,
		"--min-amplitude", fmt.Sprintf("%.2f", cfg.Sensitivity),
		"--speed", fmt.Sprintf("%.2f", cfg.Speed),
		"--cooldown", fmt.Sprintf("%d", cfg.Cooldown),
	)

	return flags
}

// writeDefaultConfig writes the default config to path (creates parent dirs).
// Uses atomic write (temp file + rename).
func writeDefaultConfig(path string) error {
	if err := os.MkdirAll(filepath.Dir(path), 0755); err != nil {
		return err
	}
	data, err := json.MarshalIndent(defaultConfig(), "", "  ")
	if err != nil {
		return err
	}
	return atomicWrite(path, data)
}

func atomicWrite(path string, data []byte) error {
	dir := filepath.Dir(path)
	tmp, err := os.CreateTemp(dir, ".spank-config-*.tmp")
	if err != nil {
		return err
	}
	tmpName := tmp.Name()
	if _, err := tmp.Write(data); err != nil {
		tmp.Close()
		os.Remove(tmpName)
		return err
	}
	if err := tmp.Close(); err != nil {
		os.Remove(tmpName)
		return err
	}
	return os.Rename(tmpName, path)
}

func hashFile(path string) ([]byte, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()
	h := sha256.New()
	if _, err := io.Copy(h, f); err != nil {
		return nil, err
	}
	return h.Sum(nil), nil
}

func readConfig(path string) (Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return Config{}, err
	}
	var cfg Config
	if err := json.Unmarshal(data, &cfg); err != nil {
		return Config{}, err
	}
	return cfg, nil
}

func main() {
	homeDir := os.Getenv("SPANK_USER_HOME")
	if homeDir == "" {
		log.Fatal("spank-supervisor: SPANK_USER_HOME env var not set")
	}

	configPath := filepath.Join(homeDir, ".config", "spank", "config.json")
	spankBin := "/usr/local/bin/spank"

	// Create default config if absent
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		log.Printf("spank-supervisor: creating default config at %s", configPath)
		if err := writeDefaultConfig(configPath); err != nil {
			log.Fatalf("spank-supervisor: failed to write default config: %v", err)
		}
	}

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGTERM, syscall.SIGINT)
	defer stop()

	var (
		child    *exec.Cmd
		lastHash []byte
	)

	ticker := time.NewTicker(time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			if child != nil && child.Process != nil {
				child.Process.Signal(syscall.SIGTERM)
				child.Wait()
			}
			return
		case <-ticker.C:
		}

		hash, err := hashFile(configPath)
		if err != nil {
			log.Printf("spank-supervisor: reading config: %v", err)
			continue
		}

		changed := !hashesEqual(hash, lastHash)
		lastHash = hash

		cfg, err := readConfig(configPath)
		if err != nil {
			log.Printf("spank-supervisor: parsing config: %v", err)
			continue
		}

		// Kill child if config changed or it should not be running
		if child != nil && child.Process != nil && (changed || !cfg.Enabled) {
			child.Process.Signal(syscall.SIGTERM)
			child.Wait()
			child = nil
		}

		if !cfg.Enabled {
			continue // idle — don't launch spank
		}

		// Start child if not running (nil = never started, ProcessState != nil = exited)
		if child == nil || child.ProcessState != nil {
			flags := buildFlags(cfg, homeDir)
			child = exec.Command(spankBin, flags...)
			child.Stdout = os.Stdout
			child.Stderr = os.Stderr
			// Pass a clean environment — inheriting XPC_SERVICE_NAME from launchd
			// context interferes with IOKit HID device access.
			child.Env = []string{
				"HOME=" + homeDir,
				"PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin",
			}
			if err := child.Start(); err != nil {
				log.Printf("spank-supervisor: start failed: %v", err)
				child = nil
				time.Sleep(time.Second) // backoff before retry
			} else {
				log.Printf("spank-supervisor: started spank with flags %v", flags)
				// Watch for unexpected exit in background
				go func(c *exec.Cmd) { c.Wait() }(child)
			}
		}
	}
}

func hashesEqual(a, b []byte) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}
