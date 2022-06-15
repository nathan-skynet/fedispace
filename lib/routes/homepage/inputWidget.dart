import 'package:flutter/material.dart';

TextEditingController _name = TextEditingController();

Future<String> randomFun() async {
  return _name.text;
}

class InputWidget extends StatelessWidget {
  final double topRight;
  final double bottomRight;

  InputWidget(this.topRight, this.bottomRight, {Key? key}) : super(key: key);

  Future<String> randomFun() async {
    return _name.text;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 40, bottom: 30),
      child: SizedBox(
        width: MediaQuery.of(context).size.width - 40,
        child: Material(
          elevation: 10,
          color: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(bottomRight),
                  topRight: Radius.circular(topRight))),
          child: Padding(
            padding:
                const EdgeInsets.only(left: 40, right: 20, top: 10, bottom: 10),
            child: TextField(
              controller: _name,
              style: const TextStyle(color: Colors.black87),
              decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "pix.echelon4.space",
                  hintStyle: TextStyle(color: Color(0xFFE1E1E1), fontSize: 14)),
            ),
          ),
        ),
      ),
    );
  }
}
