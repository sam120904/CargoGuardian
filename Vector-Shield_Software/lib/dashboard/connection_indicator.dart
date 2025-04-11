import 'package:flutter/material.dart';

// Enum for connection status
enum ConnectionStatus {
  checking,
  connecting,
  connected,
  disconnected,
}

class ConnectionIndicator extends StatelessWidget {
  final ConnectionStatus status;
  final bool blinking;
  
  const ConnectionIndicator({
    super.key,
    required this.status,
    required this.blinking,
  });
  
  @override
  Widget build(BuildContext context) {
    // Determine color based on status
    Color color;
    String label;
    IconData icon;
    
    switch (status) {
      case ConnectionStatus.checking:
        color = blinking ? Colors.grey.shade400 : Colors.grey.shade600;
        label = 'Checking';
        icon = Icons.sensors;
        break;
      case ConnectionStatus.connecting:
        color = blinking ? Colors.amber.shade300 : Colors.amber.shade600;
        label = 'Connecting';
        icon = Icons.sensors;
        break;
      case ConnectionStatus.connected:
        color = Colors.green.shade600;
        label = 'Connected';
        icon = Icons.sensors;
        break;
      case ConnectionStatus.disconnected:
        color = blinking ? Colors.red.shade300 : Colors.red.shade600;
        label = 'Disconnected';
        icon = Icons.sensors_off;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
