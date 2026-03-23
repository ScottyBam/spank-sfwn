package main

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
)

func TestBuildFlags_Pain(t *testing.T) {
	cfg := Config{Pack: "pain", Escalate: false, Fast: false, VolumeScaling: false,
		Sensitivity: 0.05, Speed: 1.0, Cooldown: 750}
	flags := buildFlags(cfg, "/Users/scott")
	// pain pack adds no pack flag, but numeric flags are always included
	for _, f := range []string{"--sexy", "--halo", "--custom"} {
		if contains(flags, f) {
			t.Errorf("unexpected flag %s for pain pack, got %v", f, flags)
		}
	}
	if !contains(flags, "--min-amplitude") || !contains(flags, "0.05") {
		t.Errorf("expected --min-amplitude 0.05 in %v", flags)
	}
	if !contains(flags, "--speed") || !contains(flags, "1.00") {
		t.Errorf("expected --speed 1.00 in %v", flags)
	}
	if !contains(flags, "--cooldown") || !contains(flags, "750") {
		t.Errorf("expected --cooldown 750 in %v", flags)
	}
}

func TestBuildFlags_Sexy(t *testing.T) {
	cfg := Config{Pack: "sexy", Sensitivity: 0.05, Speed: 1.0, Cooldown: 750}
	flags := buildFlags(cfg, "/Users/scott")
	if !contains(flags, "--sexy") {
		t.Errorf("expected --sexy flag, got %v", flags)
	}
}

func TestBuildFlags_Halo(t *testing.T) {
	cfg := Config{Pack: "halo", Sensitivity: 0.05, Speed: 1.0, Cooldown: 750}
	flags := buildFlags(cfg, "/Users/scott")
	if !contains(flags, "--halo") {
		t.Errorf("expected --halo flag, got %v", flags)
	}
}

func TestBuildFlags_Nikke(t *testing.T) {
	cfg := Config{Pack: "nikke/Privaty", Sensitivity: 0.05, Speed: 1.0, Cooldown: 750}
	flags := buildFlags(cfg, "/Users/scott")
	if !contains(flags, "--custom") {
		t.Errorf("expected --custom flag, got %v", flags)
	}
	if !contains(flags, "/Users/scott/spank-sounds/nikke/Privaty") {
		t.Errorf("expected expanded nikke path, got %v", flags)
	}
}

func TestBuildFlags_AllOptions(t *testing.T) {
	cfg := Config{
		Pack: "pain", Escalate: true, Fast: true, VolumeScaling: true,
		Sensitivity: 0.10, Speed: 1.5, Cooldown: 500,
	}
	flags := buildFlags(cfg, "/Users/scott")
	for _, f := range []string{"--escalate", "--fast", "--volume-scaling"} {
		if !contains(flags, f) {
			t.Errorf("expected flag %s, got %v", f, flags)
		}
	}
	if !contains(flags, "--min-amplitude") || !contains(flags, "0.10") {
		t.Errorf("expected --min-amplitude 0.10 in %v", flags)
	}
	if !contains(flags, "--speed") || !contains(flags, "1.50") {
		t.Errorf("expected --speed 1.50 in %v", flags)
	}
	if !contains(flags, "--cooldown") || !contains(flags, "500") {
		t.Errorf("expected --cooldown 500 in %v", flags)
	}
}

func TestDefaultConfig(t *testing.T) {
	cfg := defaultConfig()
	if cfg.Sensitivity != 0.05 {
		t.Errorf("expected sensitivity 0.05, got %f", cfg.Sensitivity)
	}
	if cfg.Cooldown != 750 {
		t.Errorf("expected cooldown 750, got %d", cfg.Cooldown)
	}
	if cfg.Speed != 1.0 {
		t.Errorf("expected speed 1.0, got %f", cfg.Speed)
	}
	if !cfg.Enabled {
		t.Errorf("expected enabled=true in default config")
	}
}

func TestParseConfig(t *testing.T) {
	raw := `{"enabled":true,"pack":"nikke/Rapi","escalate":true,"fast":false,"volumeScaling":false,"sensitivity":0.15,"speed":1.0,"cooldown":750}`
	var cfg Config
	if err := json.Unmarshal([]byte(raw), &cfg); err != nil {
		t.Fatal(err)
	}
	if cfg.Pack != "nikke/Rapi" {
		t.Errorf("expected pack nikke/Rapi, got %s", cfg.Pack)
	}
	if !cfg.Escalate {
		t.Errorf("expected escalate=true")
	}
}

func TestWriteDefaultConfig(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "config.json")
	if err := writeDefaultConfig(path); err != nil {
		t.Fatal(err)
	}
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	var cfg Config
	if err := json.Unmarshal(data, &cfg); err != nil {
		t.Fatalf("written config is not valid JSON: %v", err)
	}
	if cfg.Sensitivity != 0.05 {
		t.Errorf("expected default sensitivity 0.05")
	}
}

func contains(flags []string, s string) bool {
	for _, f := range flags {
		if f == s {
			return true
		}
	}
	return false
}
