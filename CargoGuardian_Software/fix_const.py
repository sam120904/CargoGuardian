import os
int_tab_path = r'c:\Users\Samarth\Downloads\CargoGuardian\CargoGuardian_Software\lib\dashboard\intelligence_tab.dart'
route_tab_path = r'c:\Users\Samarth\Downloads\CargoGuardian\CargoGuardian_Software\lib\dashboard\route_optimizer_tab.dart'

def fix_const(path):
    with open(path, 'r', encoding='utf-8') as f:
        text = f.read()

    # Just remove const from those elements to fix the const evaluation errors
    text = text.replace('const TextStyle', 'TextStyle')
    text = text.replace('const Text', 'Text')
    text = text.replace('const Icon', 'Icon')
    text = text.replace('const Row', 'Row')
    text = text.replace('const Column', 'Column')
    text = text.replace('const Container', 'Container')
    text = text.replace('const EdgeInsets', 'EdgeInsets')
    text = text.replace('const Spacer', 'Spacer')

    with open(path, 'w', encoding='utf-8') as f:
        f.write(text)

fix_const(int_tab_path)
fix_const(route_tab_path)
