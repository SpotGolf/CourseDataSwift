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

## SwiftData

SpotGolf stores these types as properties of its SwiftData models, so every public type must work with SwiftData with no extra code in the app. SwiftData stores a struct property by encoding it, and it crashes when:

- An encoded key differs from the property name. Don't rename keys in `CodingKeys`.
- A type encodes as a JSON array (`unkeyedContainer`).

Prefer the synthesized `Codable`. Lists of coordinates use `CoordinatePath`, which stores points compactly. `Tests/SwiftDataTests.swift` saves and reloads each type; add new public types there.

## Directory Structure

### Swift Package

```
Sources/          # Library source files
Tests/            # Test target
Package.swift     # Swift package manifest
```
