import os
int_tab_path = r'c:\Users\Samarth\Downloads\CargoGuardian\CargoGuardian_Software\lib\dashboard\intelligence_tab.dart'
route_tab_path = r'c:\Users\Samarth\Downloads\CargoGuardian\CargoGuardian_Software\lib\dashboard\route_optimizer_tab.dart'

def fix_ui(path):
    with open(path, 'r', encoding='utf-8') as f:
        text = f.read()
    
    text = text.replace('Colors.grey.shade80054', 'Colors.grey.shade500')
    text = text.replace('Colors.grey.shade800, size', 'Colors.white, size') # Fix up icons if any
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(text)

fix_ui(int_tab_path)
fix_ui(route_tab_path)
