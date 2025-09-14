# Bio ID SDK Library

This directory should contain the Bio ID fingerprint SDK AAR file.

## Required Files

Based on the official QuickStart Guide, place the following AAR files in this directory:
- `Fingerprint_Driver.aar` - For device access (required)
- `Fingerprint_Api.aar` - For fingerprint algorithm (required)

Additional files you may have:
- `Fingerprint_Live.aar` - For live finger detection (optional)
- `AlgShankshake.aar` - For additional algorithms (optional)
- `bcprov-jdk15on-149.jar` - Cryptography support (optional)

## How to Obtain the SDK

The Bio ID SDK AAR file should be provided by Bio ID Technologies Limited along with your fingerprint hardware device. Contact Bio ID support to obtain:

1. The AAR library file (`bioid-fingerprint-sdk.aar`)
2. API documentation 
3. Hardware setup instructions
4. USB/UART driver requirements

## Installation

1. Copy the required AAR files to this directory
2. The build.gradle.kts already includes the dependencies:
   ```kotlin
   implementation(files("libs/Fingerprint_Driver.aar"))
   implementation(files("libs/Fingerprint_Api.aar"))
   implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))
   ```
3. Clean and rebuild the project

## Hardware Connection

Ensure your Bio ID fingerprint scanner is properly connected via:
- USB (recommended) - Will try USB first during device discovery
- UART/Serial - Fallback option if USB initialization fails

The plugin will automatically detect the connection type and initialize the appropriate hardware interface.