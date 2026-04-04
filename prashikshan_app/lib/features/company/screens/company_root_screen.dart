import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_palette.dart';
import 'students_tab.dart';
import 'company_profile_tab.dart';
import 'post_chooser_sheet.dart';
import 'notifications_tab.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyRootScreen extends StatefulWidget {
  const CompanyRootScreen({super.key, required this.uid});
  final String uid;

  @override
  State<CompanyRootScreen> createState() => _CompanyRootScreenState();
}

class _CompanyRootScreenState extends State<CompanyRootScreen> {
  // 0 -> StudentsTab
  // 1 -> NotificationsTab
  // 2 -> CompanyProfileTab
  int _currentIndex = 0;

  String _getAppBarTitle() {
    if (_currentIndex == 0) return 'Prashikshan';
    if (_currentIndex == 1) return 'Notifications';
    return 'Company Profile';
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      // Show Post Sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => PostChooserSheet(uid: widget.uid),
      );
      return; 
    }
    setState(() {
      if (index == 0) _currentIndex = 0;
      if (index == 2) _currentIndex = 1;
      if (index == 3) _currentIndex = 2;
    });
  }

  int _getNavSelectedIndex() {
    if (_currentIndex == 0) return 0;
    if (_currentIndex == 1) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        backgroundColor: AppPalette.background,
        elevation: 0,
        centerTitle: false,
        title: Text(
          _getAppBarTitle(),
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppPalette.pureWhite,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppPalette.textSecondary),
            tooltip: 'Sign Out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      // IndexedStack preserves state across tab switches
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const StudentsTab(),
          NotificationsTab(companyUid: widget.uid),
          CompanyProfileTab(uid: widget.uid),
        ],
      ),
      bottomNavigationBar: Container(
        height: 85,
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border(
            top: BorderSide(
              color: AppPalette.pureWhite.withOpacity(0.05),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.people_outline, Icons.people),
            _buildNavItem(1, Icons.add_circle_outline, Icons.add_circle),
            _buildNavItem(2, Icons.notifications_none, Icons.notifications, isNotification: true),
            _buildNavItem(3, Icons.business_outlined, Icons.business),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, {bool isNotification = false}) {
    final isSelected = _getNavSelectedIndex() == index;
    final displayIcon = isSelected ? filledIcon : outlineIcon;
    
    Widget iconWidget = isNotification 
        ? _buildNotificationIcon(selected: isSelected)
        : Icon(
            displayIcon,
            color: isSelected 
              ? AppPalette.pureWhite 
              : AppPalette.pureWhite.withOpacity(0.4),
            size: 26,
          );

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: isSelected ? 1.2 : 1.0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                iconWidget,
                if (isSelected) 
                  const SizedBox(height: 4),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppPalette.pureWhite,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationIcon({bool selected = false}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('company_uid', isEqualTo: widget.uid)
          .where('is_read', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
        final icon = Icon(
          selected ? Icons.notifications : Icons.notifications_none,
          color: selected ? AppPalette.pureWhite : AppPalette.textSecondary,
        );

        if (unreadCount == 0) {
          return icon;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            icon,
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

