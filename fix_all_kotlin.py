#!/usr/bin/env python3
"""
Comprehensive fix for all Kotlin Android plugins to support AGP 8.x
"""

import os
import re
from pathlib import Path

def fix_plugin(build_file):
    """Fix a single plugin build.gradle file"""
    with open(build_file, 'r') as f:
        content = f.read()
    
    # Check if it's a Kotlin plugin
    if 'kotlin-android' not in content:
        return False
    
    modified = False
    
    # 1. Update Kotlin version if too old
    kotlin_match = re.search(r"ext\.kotlin_version\s*=\s*'([^']+)'", content)
    if kotlin_match:
        current_version = kotlin_match.group(1)
        parts = [int(x) for x in current_version.split('.')]
        if parts[0] < 1 or (parts[0] == 1 and parts[1] < 7):
            content = re.sub(
                r"(ext\.kotlin_version\s*=\s*)'[^']+'",
                r"\1'1.7.22'",
                content
            )
            modified =True
            print(f"  ✓ Updated Kotlin {current_version} -> 1.7.22")
    
    # 2. Fix compileOptions if using project.sourceCompatibility
    if 'project.sourceCompatibility' in content:
        content = re.sub(
            r'sourceCompatibility\s+project\.sourceCompatibility',
            'sourceCompatibility JavaVersion.VERSION_11',
            content
        )
        content = re.sub(
            r'targetCompatibility\s+project\.targetCompatibility',
            'targetCompatibility JavaVersion.VERSION_11',
            content
        )
        modified = True
        print("  ✓ Fixed project.sourceCompatibility")
    
    # 3. Fix dynamic agpJavaVersion
    if 'agpJavaVersion' in content:
        # Replace the entire block
        pattern = r'def\s+androidPlugin\s*=\s*project\.extensions\.findByName\([\'"]android[\'"]\).*?compileOptions\s*\{[^}]+\}'
        replacement = '''// Fixed for Gradle 8.x compatibility
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_11
        targetCompatibility JavaVersion.VERSION_11
    }'''
        content = re.sub(pattern, replacement, content, flags=re.DOTALL)
        modified = True
        print("  ✓ Fixed agpJavaVersion")
    
    # 4. Add kotlinOptions if missing
    if 'kotlinOptions' not in content:
        # Find android block and add kotlinOptions after compileOptions
        lines = content.split('\n')
        new_lines = []
        in_android = False
        in_compile_opts = False
        brace_count = 0
        added = False
        
        for i, line in enumerate(lines):
            new_lines.append(line)
            
            # Track android block
            if re.match(r'^\s*android\s*\{', line):
                in_android = True
                brace_count = 1
                continue
            
            if in_android:
                brace_count += line.count('{') - line.count('}')
                
                # Look for compileOptions closing
                if 'compileOptions' in line:
                    in_compile_opts = True
                
                if in_compile_opts and '}' in line and not added:
                    # Check if this is the closing of compileOptions
                    indent = len(line) - len(line.lstrip())
                    if indent <= 4:  # Top level of android block
                        # Add kotlinOptions after this line
                        new_lines.append('')
                        new_lines.append('    kotlinOptions {')
                        new_lines.append("        jvmTarget = '11'")
                        new_lines.append('    }')
                        added = True
                        modified = True
                        print("  ✓ Added kotlinOptions")
                        in_compile_opts = False
                
                if brace_count == 0:
                    break
        
        if modified:
            content = '\n'.join(new_lines)
    
    # Write back if modified
    if modified:
        with open(build_file, 'w') as f:
            f.write(content)
        return True
    
    return False

def main():
    pub_cache = Path.home() / ".pub-cache" / "hosted" / "pub.dev"
    
    # Find all Kotlin Android plugins
    import subprocess
    result = subprocess.run(
        ["find", str(pub_cache), "-name", "build.gradle", "-path", "*/android/build.gradle"],
        capture_output=True,
        text=True
    )
    
    build_files = [f.strip() for f in result.stdout.split('\n') if f.strip()]
    
    print(f"Scanning {len(build_files)} Android plugins...")
    print("=" * 60)
    
    fixed = 0
    
    for build_file in build_files:
        try:
            if fix_plugin(build_file):
                print(f"Fixed: {build_file.split('/pub.dev/')[1]}")
                fixed += 1
        except Exception as e:
            print(f"Error: {build_file}: {e}")
    
    print("=" * 60)
    print(f"Fixed {fixed} Kotlin plugins")

if __name__ == "__main__":
    main()
