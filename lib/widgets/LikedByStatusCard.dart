// ignore_for_file: camel_case_types, must_be_immutable, prefer_typing_uninitialized_variables

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../services/api.dart';


class likedByStatusCard extends StatelessWidget {
  final ApiService apiService; var posts; var likedby;
  likedByStatusCard({Key? key, required this.posts, required this.apiService,  required this.likedby}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
 var domain = apiService.domainURL();

    if (likedby.length == 0 && posts.favourites_count == 1){
      return  Container(
          margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
          child : Row(
              children: [
                  const Divider(),
                  RichText(
                    text: TextSpan(
                      text: 'Liked By ',
                      style: DefaultTextStyle.of(context).style,
                      children:  [
                         TextSpan(
                          text: "You",
                          style:  const TextStyle(fontWeight: FontWeight.w600),
                           recognizer: TapGestureRecognizer()
                             ..onTap = () {
                               debugPrint('The button is clicked!');
                             },
                        ),
                      ],
                    ),
                  )
              ]
          )
      );
    }
    return Container(
       margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
        child : Row(
            children: [
              const Divider(),
              if (posts.favourites_count >= 2) ...[
                CircleAvatar(
                    radius: 10,
                    foregroundImage:
                    NetworkImage(likedby[0].avatar.contains('://')  ?   likedby[0].avatar! : domain! + likedby[0].avatar )
                ),
                Container(width: 10,),
                RichText(
                  text: TextSpan(
                    text: 'Liked By ',
                    style: DefaultTextStyle
                        .of(context)
                        .style,
                    children: [
                      TextSpan(
                        text: likedby[0].username,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: '${(posts.favourites_count - 1)
                            .toString()} other persons',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600
                        ),
                      ),
                    ],
                  ),
                )
              ] else if(posts.favourites_count == 1)...[
                CircleAvatar(
                    radius: 10,
                    foregroundImage:
                    NetworkImage(likedby[0].avatar.contains('://')  ?   likedby[0].avatar! : domain! + likedby[0].avatar )
                ),
                Container(width: 10,),
                  RichText(
                    text: TextSpan(
                      text: 'Liked By ',
                      style: DefaultTextStyle
                          .of(context)
                          .style,
                      children:  [
                        TextSpan(
                          text: likedby[0].username,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                ]
            ]
        )
    );
  }
}

