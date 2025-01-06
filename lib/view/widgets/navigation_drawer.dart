import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class NavDrawer extends StatefulWidget {
  final int selectedIndex;

  const NavDrawer({super.key, required this.selectedIndex});

  @override
  State<StatefulWidget> createState() => _NavDrawerState();
}

class _NavDrawerState extends State<NavDrawer> {
  final String navHeaderLogo = 'assets/icons/ic_nav_header_logo.png';

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 280.w,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      backgroundColor: const Color(0xFFFAFAFA),
      child: ScrollConfiguration(
        behavior: const ScrollBehavior(),
        child: ListView(
          children: <Widget>[
            DrawerHeader(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 80,
                    width: 80,
                    child: Image.asset(
                      navHeaderLogo,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text('Not Connected',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                        )),
                  ),
                ],
              ),
            ),
            ListTile(
              focusColor: Colors.grey[350],
              dense: true,
              leading: Icon(
                Icons.apps,
                color: widget.selectedIndex == 0 ? Colors.red : Colors.grey,
              ),
              title: Text(
                'Instruments',
                style: TextStyle(
                  color: widget.selectedIndex == 0 ? Colors.red : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                // Check if the HomeScreen is already in the navigation stack
                if (Navigator.canPop(context) &&
                    ModalRoute.of(context)?.settings.name == '/') {
                  // If it's already in the stack, pop to it
                  Navigator.popUntil(context, ModalRoute.withName('/'));
                } else {
                  // Otherwise, navigate to HomeScreen
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => route.isFirst,
                  );
                }
              },
            ),
            ListTile(
              focusColor: Colors.grey[350],
              dense: true,
              leading: Icon(
                Icons.wifi_tethering,
                color: widget.selectedIndex == 1 ? Colors.red : Colors.grey,
              ),
              title: Text(
                'Logged Data',
                style: TextStyle(
                  color: widget.selectedIndex == 1 ? Colors.red : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                /**/
              },
            ),
            const Divider(),
            ListTile(
              focusColor: Colors.grey[350],
              dense: true,
              leading: Icon(
                Icons.developer_board,
                color: widget.selectedIndex == 2 ? Colors.red : Colors.grey,
              ),
              title: Text(
                'Connect Device',
                style: TextStyle(
                  color: widget.selectedIndex == 2 ? Colors.red : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                /**/
              },
            ),
            ListTile(
              focusColor: Colors.grey[350],
              dense: true,
              leading: Icon(
                Icons.create_new_folder,
                color: widget.selectedIndex == 3 ? Colors.red : Colors.grey,
              ),
              title: Text(
                'Generate Config File',
                style: TextStyle(
                  color: widget.selectedIndex == 3 ? Colors.red : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                /**/
              },
            ),
            ListTile(
              focusColor: Colors.grey[350],
              dense: true,
              leading: Icon(
                Icons.settings,
                color: widget.selectedIndex == 4 ? Colors.red : Colors.grey,
              ),
              title: Text(
                'Settings',
                style: TextStyle(
                  color: widget.selectedIndex == 4 ? Colors.red : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                /**/
              },
            ),
            const Divider(),
            ListTile(
              focusColor: Colors.grey[350],
              dense: true,
              leading: Icon(
                Icons.info,
                color: widget.selectedIndex == 5 ? Colors.red : Colors.grey,
              ),
              title: Text(
                'About Us',
                style: TextStyle(
                  color: widget.selectedIndex == 5 ? Colors.red : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                /**/
              },
            ),
            ListTile(
              focusColor: Colors.grey[350],
              dense: true,
              leading: Icon(
                Icons.menu_book,
                color: widget.selectedIndex == 6 ? Colors.red : Colors.grey,
              ),
              title: Text(
                'Documentation',
                style: TextStyle(
                  color: widget.selectedIndex == 6 ? Colors.red : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                /**/
              },
            ),
            ListTile(
              focusColor: Colors.grey[350],
              dense: true,
              leading: Icon(
                Icons.star,
                color: widget.selectedIndex == 7 ? Colors.red : Colors.grey,
              ),
              title: Text(
                'Rate App',
                style: TextStyle(
                  color: widget.selectedIndex == 7 ? Colors.red : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                /**/
              },
            ),
            ListTile(
              focusColor: Colors.grey[350],
              dense: true,
              leading: Icon(
                Icons.shopping_cart,
                color: widget.selectedIndex == 8 ? Colors.red : Colors.grey,
              ),
              title: Text(
                'Buy PSLab',
                style: TextStyle(
                  color: widget.selectedIndex == 8 ? Colors.red : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                /**/
              },
            ),
            ListTile(
              focusColor: Colors.grey[350],
              dense: true,
              leading: Icon(
                Icons.feedback,
                color: widget.selectedIndex == 9 ? Colors.red : Colors.grey,
              ),
              title: Text(
                'FAQ',
                style: TextStyle(
                  color: widget.selectedIndex == 9 ? Colors.red : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                /**/
              },
            ),
            ListTile(
              focusColor: Colors.grey[350],
              dense: true,
              leading: Icon(
                Icons.share,
                color: widget.selectedIndex == 10 ? Colors.red : Colors.grey,
              ),
              title: Text(
                'Share App',
                style: TextStyle(
                  color: widget.selectedIndex == 10 ? Colors.red : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                /**/
              },
            ),
            ListTile(
              focusColor: Colors.grey[350],
              dense: true,
              leading: Icon(
                Icons.article,
                color: widget.selectedIndex == 11 ? Colors.red : Colors.grey,
              ),
              title: Text(
                'Privacy Policy',
                style: TextStyle(
                  color: widget.selectedIndex == 11 ? Colors.red : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                /**/
              },
            ),
            ListTile(
              focusColor: Colors.grey[350],
              dense: true,
              leading: Icon(
                Icons.attribution,
                color: widget.selectedIndex == 12 ? Colors.red : Colors.grey,
              ),
              title: Text(
                'Open Source Licenses',
                style: TextStyle(
                  color: widget.selectedIndex == 12 ? Colors.red : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                /**/
              },
            ),
          ],
        ),
      ),
    );
  }
}
