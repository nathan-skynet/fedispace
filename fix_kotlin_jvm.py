#!/usr/bin/env python3
"""
Script to add kotlinOptions with JVM 11 to all Android plugins
"""

import os
import re
from pathlib import Path

def has_kotlin_options(content):
    """Check if kotlinOptions already exists"""
    return 'kotlinOptions' in content

def add_kotlin_options(build_file):
    """Add kotlinOptions to build.gradle if missing"""
    with open(build_file, 'r') as f:
        content = f.read()
    
    if has_kotlin_options(content):
        return False
    
    # Find android { block
    lines = content.split('\n')
    new_lines = []
    in_android_block = False
    added = False
    brace_count = 0
    
    for i, line in enumerate(lines):
        new_lines.append(line)
        
        # Check for android {
        if re.match(r'^\s*android\s*\{', line):
            in_android_block = True
            brace_count = 1
            continue
        
        if in_android_block:
            # Track braces
            brace_count += line.count('{') - line.count('}')
            
            # Look for compileOptions block to insert after it
            if 'compileOptions' in line and not added:
                # Find the closing brace of compileOptions
                j = i
                sub_braces = 0
                while j < len(lines):
                    sub_braces += lines[j].count('{') - lines[j].count('}')
                    if sub_braces == 0 and '}' in lines[j]:
                        # Insert kotlinOptions after this closing brace
                        indent = '    '
                        kotlin_opts = f"\n{indent}kotlinOptions {{\n{indent}    jvmTarget = '11'\n{indent}}}\n"
                        new_lines.append(kotlin_opts)
                        added = True
                        break
                    j += 1
            
            if brace_count == 0:
                in_android_block = False
    
    if not added:
        print(f"  ⚠ Could not add kotlinOptions (no compileOptions found): {build_file}")
        return False
    
    # Write back
    with open(build_file, 'w') as f:
        f.write('\n'.join(new_lines))
    
    print(f"  ✓ Added kotlinOptions to: {build_file}")
    return True

def update_kotlin_version(build_file, min_version='1.7.22'):
    """Update Kotlin version to at least min_version"""
    with open(build_file, 'r') as f:
        content = f.read()
    
    # Find ext.kotlin_version = 'X.Y.Z'
    match = re.search(r"ext\.kotlin_version\s*=\s*'([^']+)'", content)
    if not match:
        return False
    
    current_version = match.group(1)
    current_parts = [int(x) for x in current_version.split('.')]
    min_parts = [int(x) for x in min_version.split('.')]
    
    # Compare versions
    if current_parts >= min_parts:
        return False
    
    # Update version
    new_content = re.sub(
        r"(ext\.kotlin_version\s*=\s*)'[^']+'",
        f"\\1'{min_version}'",
        content
    )
    
    with open(build_file, 'w') as f:
        f.write(new_content)
    
    print(f"  ✓ Updated Kotlin version {current_version} -> {min_version}: {build_file}")
    return True

def main():
    pub_cache = Path.home() / ".pub-cache" / "hosted" / "pub.dev"
    
    # Find all build.gradle files in Android plugins
    import subprocess
    result = subprocess.run(
        ["find", str(pub_cache), "-name", "build.gradle", "-path", "*/android/build.gradle"],
        capture_output=True,
        text=True
    )
    
    build_files = [f.strip() for f in result.stdout.split('\n') if f.strip()]
    
    print(f"Found {len(build_files)} Android plugin build files")
    print("=" * 60)
    
    kotlin_updated = 0
    kotlin_opts_added = 0
    
    for build_file in build_files:
        try:
            if update_kotlin_version(build_file):
                kotlin_updated += 1
            if add_kotlin_options(build_file):
                kotlin_opts_added += 1
        except Exception as e:
            print(f"  ✗ Error processing {build_file}: {e}")
    
    print("=" * 60)
    print(f"Summary: {kotlin_updated} Kotlin versions updated, {kotlin_opts_added} kotlinOptions added")

if __name__ == "__main__":
    main()
