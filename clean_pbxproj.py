import sys

filepath = '/Users/reiketsukennn/xcode/CURATED/CURATED/CURATED.xcodeproj/project.pbxproj'

try:
    with open(filepath, 'r') as f:
        lines = f.readlines()
        
    new_lines = [line for line in lines if 'OnboardingView 2.swift' not in line]
    
    if len(lines) != len(new_lines):
        with open(filepath, 'w') as f:
            f.writelines(new_lines)
        print("Successfully removed OnboardingView 2.swift from pbxproj")
    else:
        print("OnboardingView 2.swift not found in pbxproj")
except Exception as e:
    print(f"Error: {e}")
