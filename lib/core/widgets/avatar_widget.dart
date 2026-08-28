import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import 'solarium_glass_container.dart';

class AvatarWidget extends StatefulWidget {
  final double size;
  const AvatarWidget({super.key, this.size = 40.0});

  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget> {
  static const String _avatarKey = 'selected_user_avatar_idx';
  int _selectedAvatarIdx = 0;

  // 5 أفاتارات افتراضية بتدرجات لونية عصرية ونصوص مميزة
  final List<Map<String, dynamic>> _avatars = [
    {
      'icon': '🧠',
      'colors': [Colors.purpleAccent, Colors.deepPurple],
    },
    {
      'icon': '✨',
      'colors': [Colors.amber, Colors.orange],
    },
    {
      'icon': '🌊',
      'colors': [Colors.cyanAccent, Colors.blue],
    },
    {
      'icon': '🦁',
      'colors': [Colors.orangeAccent, Colors.red],
    },
    {
      'icon': '🦉',
      'colors': [Colors.lightGreenAccent, Colors.green],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedAvatar();
  }

  Future<void> _loadSelectedAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedAvatarIdx = prefs.getInt(_avatarKey) ?? 0;
    });
  }

  Future<void> _saveSelectedAvatar(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_avatarKey, index);
    setState(() {
      _selectedAvatarIdx = index;
    });
  }

  void _showAvatarPicker() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: SolariumGlassContainer(
            padding: const EdgeInsets.all(24),
            borderRadius: 28,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'اختر صورتك الرمزية',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _avatars.length,
                  itemBuilder: (context, index) {
                    final avatar = _avatars[index];
                    final isSelected = index == _selectedAvatarIdx;
                    return GestureDetector(
                      onTap: () {
                        _saveSelectedAvatar(index);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: isDark ? Colors.cyanAccent : SiyaqColors.accentGold,
                                  width: 3,
                                )
                              : null,
                          gradient: LinearGradient(
                            colors: List<Color>.from(avatar['colors']),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            avatar['icon'],
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'إلغاء',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _avatars[_selectedAvatarIdx];
    return GestureDetector(
      onTap: _showAvatarPicker,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
          gradient: LinearGradient(
            colors: List<Color>.from(avatar['colors']),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            avatar['icon'],
            style: TextStyle(fontSize: widget.size * 0.5),
          ),
        ),
      ),
    );
  }
}
