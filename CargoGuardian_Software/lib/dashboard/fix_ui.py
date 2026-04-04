import os
import re

int_tab_path = r'c:\Users\Samarth\Downloads\CargoGuardian\CargoGuardian_Software\lib\dashboard\intelligence_tab.dart'
route_tab_path = r'c:\Users\Samarth\Downloads\CargoGuardian\CargoGuardian_Software\lib\dashboard\route_optimizer_tab.dart'

def fix_ui(path):
    with open(path, 'r', encoding='utf-8') as f:
        text = f.read()

    # Generic color replacements
    text = text.replace('Colors.grey.shade300', 'Colors.grey.shade700')
    text = text.replace('color: Colors.white', 'color: Colors.grey.shade800')
    text = text.replace('color: Colors.white54', 'color: Colors.grey.shade600')
    text = text.replace('Colors.grey.shade400', 'Colors.grey.shade600')
    text = text.replace('Colors.grey.shade500', 'Colors.grey.shade600')
    
    # Text styles
    text = text.replace('color: Colors.cyan.shade300', 'color: Colors.cyan.shade700')
    text = text.replace('color: Colors.red.shade300', 'color: Colors.red.shade700')
    text = text.replace('color: Colors.orange.shade300', 'color: Colors.orange.shade700')
    
    # Replace Card backgrounds (General)
    box_decor_dark1 = '''decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),'''
      
    box_decor_light1 = '''decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),'''
    text = text.replace(box_decor_dark1, box_decor_light1)

    box_decor_dark3 = '''decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800),
      ),'''
      
    box_decor_light3 = '''decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),'''
    text = text.replace(box_decor_dark3, box_decor_light3)

    # Station selector
    box_decor_dark4 = '''decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800),
      )'''
      
    box_decor_light4 = '''decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      )'''
    text = text.replace(box_decor_dark4, box_decor_light4)

    # Gradient replace for route result
    grad_dark1 = '''gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.cyan.shade900.withOpacity(0.4),
            Colors.teal.shade900.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyan.shade700.withOpacity(0.3)),'''
    
    grad_light1 = '''color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],'''
    text = text.replace(grad_dark1, grad_light1)

    # Gradient replace for intelligence tab
    grad_dark2 = '''gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.cyan.shade900.withOpacity(0.3),
                Colors.blue.shade900.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.cyan.shade800.withOpacity(0.3)),'''
    text = text.replace(grad_dark2, grad_light1)

    grad_dark3 = '''gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.red.shade900.withOpacity(0.3),
                Colors.orange.shade900.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade800.withOpacity(0.3)),'''
    text = text.replace(grad_dark3, grad_light1)

    grad_dark4 = '''gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.cyan.shade900.withOpacity(0.4),
                Colors.deepPurple.shade900.withOpacity(0.3),
                Colors.red.shade900.withOpacity(0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.cyan.shade700.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyan.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(-5, 0),
              ),
              BoxShadow(
                color: Colors.red.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(5, 0),
              ),
            ],'''
    
    grad_light4 = '''color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],'''
    text = text.replace(grad_dark4, grad_light4)

    # Some remaining dark colors
    text = text.replace('backgroundColor: Colors.grey.shade800,', 'backgroundColor: Colors.grey.shade200,')
    text = text.replace('color: color.withOpacity(0.08)', 'color: Colors.white')
    text = text.replace('border: Border.all(color: color.withOpacity(0.3))', 'boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]')
    text = text.replace('color: riskColor.withOpacity(0.08)', 'color: Colors.white')
    text = text.replace('border: Border.all(color: riskColor.withOpacity(0.3))', 'boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]')
    
    # dropdown background
    text = text.replace('color: Colors.grey.shade800.withOpacity(0.5)', 'color: Colors.grey.shade100')
    text = text.replace('border: Border.all(color: Colors.grey.shade700)', 'border: Border.all(color: Colors.grey.shade300)')
    text = text.replace('dropdownColor: Colors.grey.shade900', 'dropdownColor: Colors.white')
    
    # Icon white colors which should remain white:
    text = text.replace('icon(Icons.hub, color: Colors.grey.shade800, size: 24)', 'icon(Icons.hub, color: Colors.white, size: 24)')
    text = text.replace('Icon(Icons.hub, color: Colors.grey.shade800, size: 24)', 'Icon(Icons.hub, color: Colors.white, size: 24)')
    text = text.replace('Icon(Icons.route, color: Colors.grey.shade800, size: 24)', 'Icon(Icons.route, color: Colors.white, size: 24)')
    
    # Title in Intelligence Tab
    text = text.replace('''Text(
                'Graph Intelligence',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),''', '''Text(
                'Graph Intelligence',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),''')

    # Ensure white icons in header
    text = text.replace('color: Colors.grey.shade800, size: 24', 'color: Colors.white, size: 24')
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(text)

fix_ui(int_tab_path)
fix_ui(route_tab_path)
print("Done styling")
