import 'package:flutter/material.dart';
import 'package:flux_virtual/Theme.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {

  
  @override
  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? AppColors.darkSurface : AppColors.white;
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.05);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),

          
          // Container(
          //   padding: const EdgeInsets.all(16),
          //   decoration: BoxDecoration(
          //     color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
          //     borderRadius: BorderRadius.circular(16),
          //   ),
          //   child: Row(
          //     children: [
          //       Expanded(
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             Text(
          //               'Profile picture',
          //               style: TextStyle(
                         
          //                 fontWeight: FontWeight.w600,
          //                 fontSize: 16,
          //               ),
          //             ),
          //             const SizedBox(height: 6),
          //             Text(
          //               'Update picture by clicking on it.\n(cannot exceed 20MB)',
          //               style: TextStyle(
                         
          //                 fontSize: 13,
          //                 height: 1.5,
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //       const SizedBox(width: 16),
          //       GestureDetector(
          //         onTap: () {
                    
          //         },
          //         child: CircleAvatar(
          //           radius: 36,
        
          //           child: Icon(
          //             Icons.image_outlined,
          //             color: Theme.of(context).scaffoldBackgroundColor,
          //             size: 28,
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          const SizedBox(height: 16),

          
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _SettingsTile(
                  label: 'Change Profile name',
                  onTap: () {},
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.08),
                ),
                _SettingsTile(
                  label: 'Change E-mail',
                  onTap: () {},
                ),
                // Divider(
                //   height: 1,
                //   indent: 16,
                //   color: Theme.of(context)
                //             .colorScheme
                //             .onSurface
                //             .withOpacity(0.08),
                // ),
                // _SettingsTile(
                //   label: 'Change Phone number',
                //   onTap: () {},
                // ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              onTap: () {
                _showDeleteDialog(context);
              },
              title: const Text(
                'Permanently delete account',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.darkBrown),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}


class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: 22,
      ),
    );
  }
}