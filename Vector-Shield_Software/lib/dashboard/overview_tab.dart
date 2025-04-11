import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'connection_indicator.dart';

class OverviewTab extends StatelessWidget {
  final Size screenSize;
  final DashboardData data;
  final DashboardCallbacks callbacks;
  
  const OverviewTab({
    super.key,
    required this.screenSize,
    required this.data,
    required this.callbacks,
  });
  
  @override
  Widget build(BuildContext context) {
    // Calculate responsive grid columns based on screen width
    int crossAxisCount = screenSize.width < 600 ? 2 : 4;
    
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // Error message if any
              if (data.errorMessage.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          data.errorMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Status Cards - Now with real-time weight and alert switch
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                children: [
                  _buildCompactWeightCard(context),
                  _buildCompactClearanceCard(context),
                  _buildCompactAlertCard(context),
                  _buildCompactActionsCard(context),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Weight Limits Card
              _buildCompactWeightLimitsCard(context),
              
              const SizedBox(height: 16),
              
              // Quick Actions
              _buildQuickActionsRow(context),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCompactWeightCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.scale,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                'Current Weight',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: data.isLoadingWeight
                ? CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.blue.shade700,
                  )
                : Column(
                    children: [
                      Text(
                        data.currentWeight.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: data.connectionStatus == ConnectionStatus.disconnected
                            ? Colors.grey.shade500
                            : data.isOverweight 
                              ? Colors.red.shade700 
                              : data.isUnderweight 
                                ? Colors.amber.shade700 
                                : Colors.blue.shade700,
                        ),
                      ),
                      Text(
                        'tons',
                        style: TextStyle(
                          fontSize: 16,
                          color: data.connectionStatus == ConnectionStatus.disconnected
                            ? Colors.grey.shade500
                            : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
          ),
          const Spacer(),
          LinearProgressIndicator(
            value: data.connectionStatus == ConnectionStatus.disconnected
              ? 0.0
              : data.currentWeight / (data.maxWeightLimit * 1.2), // Scale for visual effect
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              data.connectionStatus == ConnectionStatus.disconnected
                ? Colors.grey.shade400
                : data.isOverweight 
                  ? Colors.red.shade500 
                  : data.isUnderweight 
                    ? Colors.amber.shade500 
                    : Colors.green.shade500,
            ),
            borderRadius: BorderRadius.circular(10),
            minHeight: 6,
          ),
        ],
      ),
    );
  }
  
  Widget _buildCompactClearanceCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                'Clearance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: data.connectionStatus == ConnectionStatus.disconnected
                  ? Colors.grey.shade200
                  : data.isClearanceGiven ? Colors.green.shade100 : Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  data.connectionStatus == ConnectionStatus.disconnected
                    ? Icons.sensors_off
                    : data.isClearanceGiven ? Icons.check_circle : Icons.cancel,
                  size: 36,
                  color: data.connectionStatus == ConnectionStatus.disconnected
                    ? Colors.grey.shade500
                    : data.isClearanceGiven ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (data.isOverweight || data.isUnderweight || data.connectionStatus == ConnectionStatus.disconnected) 
                ? null 
                : callbacks.toggleClearance,
              style: ElevatedButton.styleFrom(
                backgroundColor: data.connectionStatus == ConnectionStatus.disconnected
                  ? Colors.grey.shade200
                  : data.isClearanceGiven 
                    ? Colors.red.shade100 
                    : (data.isOverweight || data.isUnderweight) 
                      ? Colors.grey.shade200 
                      : Colors.green.shade100,
                foregroundColor: data.connectionStatus == ConnectionStatus.disconnected
                  ? Colors.grey.shade500
                  : data.isClearanceGiven 
                    ? Colors.red.shade700 
                    : (data.isOverweight || data.isUnderweight) 
                      ? Colors.grey.shade500 
                      : Colors.green.shade700,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                data.connectionStatus == ConnectionStatus.disconnected
                  ? 'Unavailable'
                  : (data.isOverweight || data.isUnderweight)
                    ? 'Not Available'
                    : (data.isClearanceGiven ? 'Revoke' : 'Give'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // New card for alert switch
  Widget _buildCompactAlertCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                'Alert Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: data.connectionStatus == ConnectionStatus.disconnected
                  ? Colors.grey.shade200
                  : data.sendAlertEnabled ? Colors.amber.shade100 : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  data.connectionStatus == ConnectionStatus.disconnected
                    ? Icons.sensors_off
                    : data.sendAlertEnabled ? Icons.notifications_active : Icons.notifications_off,
                  size: 36,
                  color: data.connectionStatus == ConnectionStatus.disconnected
                    ? Colors.grey.shade500
                    : data.sendAlertEnabled ? Colors.amber.shade700 : Colors.grey.shade700,
                ),
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: data.connectionStatus == ConnectionStatus.disconnected
                ? null
                : callbacks.toggleSendAlert,
              style: ElevatedButton.styleFrom(
                backgroundColor: data.connectionStatus == ConnectionStatus.disconnected
                  ? Colors.grey.shade200
                  : data.sendAlertEnabled 
                    ? Colors.grey.shade100 
                    : Colors.amber.shade100,
                foregroundColor: data.connectionStatus == ConnectionStatus.disconnected
                  ? Colors.grey.shade500
                  : data.sendAlertEnabled 
                    ? Colors.grey.shade700 
                    : Colors.amber.shade700,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                data.connectionStatus == ConnectionStatus.disconnected
                  ? 'Unavailable'
                  : data.sendAlertEnabled ? 'Disable' : 'Enable',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCompactActionsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildMiniActionButton(
            context: context,
            icon: Icons.refresh,
            label: 'Refresh',
            color: Colors.blue,
            onPressed: () {
              callbacks.fetchInitialData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Data refreshed'),
                  backgroundColor: Colors.blue.shade600,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildMiniActionButton(
            context: context,
            icon: Icons.report_problem,
            label: 'Report',
            color: Colors.orange,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    'Report an Issue',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: const Text('This feature is not available in the demo version.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildMiniActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required MaterialColor color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 15)),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.shade50,
          foregroundColor: color.shade700,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: color.shade200),
          ),
          elevation: 0,
        ),
      ),
    );
  }
  
  Widget _buildCompactWeightLimitsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                'Weight Limits',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Min:',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              Text(
                '${data.minWeightLimit.toStringAsFixed(1)} tons',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: data.minWeightLimit,
              min: 0,
              max: data.maxWeightLimit - 5, // Ensure min is always less than max
              divisions: 50,
              activeColor: Colors.amber.shade400,
              inactiveColor: Colors.grey.shade200,
              onChanged: data.connectionStatus == ConnectionStatus.disconnected
                ? null
                : callbacks.updateMinWeightLimit,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Max:',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              Text(
                '${data.maxWeightLimit.toStringAsFixed(1)} tons',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: data.maxWeightLimit,
              min: data.minWeightLimit + 5, // Ensure max is always greater than min
              max: 100,
              divisions: 50,
              activeColor: Colors.red.shade400,
              inactiveColor: Colors.grey.shade200,
              onChanged: data.connectionStatus == ConnectionStatus.disconnected
                ? null
                : callbacks.updateMaxWeightLimit,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActionsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionChip(
            context: context,
            icon: Icons.refresh,
            label: 'Refresh',
            color: Colors.blue,
            onPressed: () {
              callbacks.fetchInitialData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Data refreshed'),
                  backgroundColor: Colors.blue.shade600,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionChip(
            context: context,
            icon: Icons.report_problem,
            label: 'Report',
            color: Colors.orange,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    'Report an Issue',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: const Text('This feature is not available in the demo version.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionChip(
            context: context,
            icon: Icons.history,
            label: 'History',
            color: Colors.purple,
            onPressed: () {
              // This would be handled by the parent widget
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required MaterialColor color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: color.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
