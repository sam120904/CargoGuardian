import os
route_tab_path = r'c:\Users\Samarth\Downloads\CargoGuardian\CargoGuardian_Software\lib\dashboard\route_optimizer_tab.dart'

def fix_const2(path):
    with open(path, 'r', encoding='utf-8') as f:
        text = f.read()

    text = text.replace('const Expanded(', 'Expanded(')
    text = text.replace('const SizedBox(', 'SizedBox(')
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(text)

fix_const2(route_tab_path)
