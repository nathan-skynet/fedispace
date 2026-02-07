#!/usr/bin/env python3
"""
Script to patch Android plugin build.gradle files to add namespace declarations
Required for AGP 8.x compatibility
"""

import os
import re
import subprocess
from pathlib import Path

def find_android_manifest_package(plugin_dir):
    """Extract package name from AndroidManifest.xml"""
    manifest_path = Path(plugin_dir) / "src" / "main" / "AndroidManifest.xml"
    if manifest_path.exists():
        with open(manifest_path, 'r') as f:
            content = f.read()
            match = re.search(r'package="([^"]+)"', content)
            if match:
                return match.group(1)
    return None

def get_namespace_from_build_file(build_gradle_path):
    """Check if namespace already exists"""
    with open(build_gradle_path, 'r') as f:
        content = f.read()
        if 'namespace' in content:
            return True
    return False

def add_namespace_to_build_gradle(build_gradle_path):
    """Add namespace declaration to build.gradle"""
    plugin_dir = Path(build_gradle_path).parent
    
    # Check if already has namespace
    if get_namespace_from_build_file(build_gradle_path):
        print(f"✓ Already has namespace: {build_gradle_path}")
        return True
    
    # Get package name from AndroidManifest.xml
    package = find_android_manifest_package(plugin_dir)
    if not package:
        print(f"⚠ No package found in manifest: {build_gradle_path}")
        return False
    
    # Read current build.gradle
    with open(build_gradle_path, 'r') as f:
        lines = f.readlines()
    
    # Find android { block and add namespace
    new_lines = []
    android_block_found = False
    namespace_added = False
    
    for i, line in enumerate(lines):
        new_lines.append(line)
        
        # Look for "android {" line
        if re.match(r'^\s*android\s*\{', line) and not namespace_added:
            android_block_found = True
            # Add namespace on next line with proper indentation
            indent = "    "
            namespace_line = f"{indent}namespace '{package}'\n"
            new_lines.append(namespace_line)
            namespace_added = True
    
    if not android_block_found:
        print(f"⚠ No android block found: {build_gradle_path}")
        return False
    
    # Write back
    with open(build_gradle_path, 'w') as f:
        f.writelines(new_lines)
    
    print(f"✓ Added namespace '{package}' to: {build_gradle_path}")
    return True

def main():
    """Main function to patch all plugins"""
    pub_cache = Path.home() / ".pub-cache" / "hosted" / "pub.dev"
    
    if not pub_cache.exists():
        print(f"Error: pub cache not found at {pub_cache}")
        return
    
    # Find all Android library build.gradle files
    result = subprocess.run(
        ["grep", "-r", "apply plugin: 'com.android.library'", str(pub_cache),
         "--include=build.gradle", "-l"],
        capture_output=True,
        text=True
    )
    
    if result.returncode != 0:
        print("No Android library plugins found")
        return
    
    build_files = result.stdout.strip().split('\n')
    
    print(f"Found {len(build_files)} Android plugin build files")
    print("=" * 60)
    
    success = 0
    skipped = 0
    failed = 0
    
    for build_file in build_files:
        if not build_file:
            continue
        try:
            if add_namespace_to_build_gradle(build_file):
                success += 1
            else:
                skipped += 1
        except Exception as e:
            print(f"✗ Error processing {build_file}: {e}")
            failed += 1
    
    print("=" * 60)
    print(f"Summary: {success} patched, {skipped} skipped, {failed} failed")

if __name__ == "__main__":
    main()
