import 'package:fedispace/services/api.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class bottomWidget extends StatefulWidget {
  final ApiService apiService;
  int page;
  bottomWidget({Key? key, required this.apiService, required this.page})
      : super(key: key);

  @override
  State<bottomWidget> createState() => _bottomWidget();
}

class _bottomWidget extends State<bottomWidget> {
  late int _setIndex;
  void _getIndex(int pos) {
    switch (pos) {
      case 0:
        Navigator.pushNamed(context, '/TimeLine');
        break;

      case 1:
        Navigator.pushNamed(context, '/Local');
        break;

      case 2:
        break;

      case 3:
        break;
      case 4:
        Navigator.pushNamed(context, '/Desc');
        break;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _setIndex = index;
      _getIndex(_setIndex);
    });
  }

  @override
  void initState() {
    _setIndex = widget.page;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _setIndex = widget.page;
    return Container(
       clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(40), topLeft: Radius.circular(40)),
          boxShadow: [
            BoxShadow(color: Colors.black38, spreadRadius: 5, blurRadius: 15),
          ],
        ),
        child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(40),
              topLeft: Radius.circular(40),
            ),
            child: BottomNavigationBar(
              selectedItemColor: Colors.lightBlue,
              unselectedItemColor: Colors.blueGrey,
              type: BottomNavigationBarType.fixed,
              currentIndex: _setIndex,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              enableFeedback: true,
              onTap: (int index) {
                _onItemTapped(index);
              },
              items:   const [
                 BottomNavigationBarItem(
                icon : Icon(FontAwesomeIcons.house) , label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(FontAwesomeIcons.barsStaggered), label: 'Local'),
                BottomNavigationBarItem(
                    icon: Icon(FontAwesomeIcons.circlePlus, size : 34, color: Colors.red,), label: 'add'),
                BottomNavigationBarItem(
                     icon : Icon(FontAwesomeIcons.circleUser), label: 'Bookmark'),
                BottomNavigationBarItem(
                    icon: Icon(FontAwesomeIcons.photoFilm), label: 'Profile'),
              ],
            )));
  }
}
