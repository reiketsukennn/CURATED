import os
import glob

directory = "/Users/reiketsukennn/Cursor/CURATED/"
swift_files = glob.glob(os.path.join(directory, "*.swift"))

replacements = {
    'Color(hex: "0f2c59")': 'Color.black',
    'Color(hex: "FBFCFE")': 'Color(hex: "FDFBF7")',
    'Color(hex: "b5becc")': 'Color(hex: "EFEBE0")',
    'Color(hex: "FAFAFA")': 'Color(hex: "FDFBF7")',
    'Color(hex: "0F2C59")': 'Color.black', # just in case uppercase
}

files_changed = 0

for file_path in swift_files:
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    original_content = content
    
    for old, new in replacements.items():
        content = content.replace(old, new)
        
    if content != original_content:
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(content)
        files_changed += 1
        print(f"Updated {os.path.basename(file_path)}")

print(f"Successfully applied black, white, and cream theme to {files_changed} files.")
