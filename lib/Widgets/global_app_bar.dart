import 'package:flutter/material.dart';

class GlobalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isSearching;
  final TextEditingController? searchController;
  final VoidCallback? onCloseSearch;
  final ValueChanged<String>? onSearchChanged;
  
  // Specific callbacks for your right-side icons
  final VoidCallback? onSearchTap;
  final VoidCallback? onFilterTap;
  final VoidCallback? onSortTap;

  const GlobalAppBar({
    super.key,
    this.isSearching = false,
    this.searchController,
    this.onCloseSearch,
    this.onSearchChanged,
    this.onSearchTap,
    this.onFilterTap,
    this.onSortTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color goldColor = const Color(0xFFD4AF37); // Unwaver gold
    // Using a dark color since the app bar is transparent and your app background is white
    final Color iconColor = Colors.black87; 

    return AppBar(
      // --- THE BLEND EFFECT ---
      backgroundColor: Colors.transparent,
      elevation: 0,
      // Critical for Material 3: Prevents the transparent bar from turning grey when scrolling
      scrolledUnderElevation: 0, 
      iconTheme: IconThemeData(color: iconColor),

      // Automatically shows the hamburger menu if not searching (when Scaffold has a Drawer)
      leading: isSearching
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: onCloseSearch,
            )
          : null, 

      // --- NO LOGO, ONLY SEARCH FIELD ---
      title: isSearching
          ? TextField(
              controller: searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.black), 
              cursorColor: goldColor,
              decoration: InputDecoration(
                hintText: "Search...",
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: onSearchChanged,
            )
          : const SizedBox.shrink(), // Leaves the middle completely empty

      // --- FIXED TOP RIGHT ICONS ---
      actions: isSearching
          ? null // Hides icons to give the search bar full width
          : [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: onSearchTap,
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: onFilterTap,
              ),
              IconButton(
                icon: const Icon(Icons.sort_by_alpha),
                onPressed: onSortTap,
              ),
              const SizedBox(width: 8), // A little breathing room on the edge
            ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}