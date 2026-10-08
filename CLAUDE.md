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

The package uses Swift tools version 6.0 and builds in Swift 6 language mode (strict concurrency). Every public value type is `Sendable`, because SpotGolf stores them inside its own `Sendable` types and passes them between actors. Keep new public types `Sendable`.

## Directory Structure

### Swift Package

```
Sources/          # Library source files
Tests/            # Test target
Package.swift     # Swift package manifest
```
