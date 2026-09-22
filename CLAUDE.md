# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository contains **A Swift library** (`CourseDataSwift`) providing data models for golf courses — `Course`, `Hole`, `Feature`, `Coordinate`, and related types.

## Build & Test

```bash
swift build --disable-sandbox
swift test --disable-sandbox
```

The project targets macOS 14+ and iOS 17+ and uses CoreLocation.

## Directory Structure

### Swift Package

```
Sources/          # Library source files
Tests/            # Test target
Package.swift     # Swift package manifest
```
