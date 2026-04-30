import os
import re

def replace_with_opacity(directory):
    pattern = re.compile(r'\.withOpacity\((.*?)\)')
    replacement = r'.withValues(alpha: \1)'
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                with open(path, 'r') as f:
                    content = f.read()
                
                new_content = pattern.sub(replacement, content)
                
                if new_content != content:
                    with open(path, 'w') as f:
                        f.write(new_content)
                    print(f"Updated {path}")

if __name__ == "__main__":
    replace_with_opacity('lib')
