import 'package:fedispace/core/api.dart';
import 'package:flutter/material.dart';

class HeaderStatusCard extends StatelessWidget {
  final postsAccount;
  final created_at;
  final ApiService apiService;
  final String statusId;

  const HeaderStatusCard(
      {Key? key,
      required this.postsAccount,
      required this.created_at,
      required this.apiService,
      required this.statusId})
      : super(key: key);

  String convertToAgo(DateTime input) {
    Duration diff = DateTime.now().difference(input);

    if (diff.inDays >= 1) {
      return '${diff.inDays} day(s) ago';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours} hour(s) ago';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes} minute(s) ago';
    } else if (diff.inSeconds > 1) {
      return '${diff.inSeconds} second(s) ago';
    } else {
      return 'just now';
    }
  }

  void onTap(context, id) {
    Navigator.of(context).pushNamed('/Profile', arguments: {'id': id});
  }

  @override
  Widget build(BuildContext context) {
    var domain = apiService.domainURL();
    return Container(
        height: 50,
        // color: Colors.grey,
        margin: const EdgeInsets.only(top: 0),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                onTap(context, postsAccount.id);
              },
              child: CircleAvatar(
                  foregroundImage: NetworkImage(
                      postsAccount!.avatarUrl.contains('://')
                          ? postsAccount!.avatarUrl!
                          : domain! + postsAccount!.avatarUrl)),
            ),
            const SizedBox(width: 10),
            Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
                //apply padding horizontal or vertical only
                child: Text(
                  postsAccount.displayName,
                ),
              ),
              Text(
                postsAccount.username,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ]),
            Expanded(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                ),
                Text(
                  convertToAgo(DateTime.parse(created_at.toString())),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade400),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  child: PopupMenuButton(
                      tooltip: "Menu",
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      onSelected: (int index) {
                        print('index is $index');
                        if (index == 1) {
                          // Voir la Publication - Navigate to status detail
                          Navigator.pushNamed(
                            context,
                            '/statusDetail',
                            arguments: {
                              'statusId': statusId,
                              'apiService': apiService,
                            },
                          );
                        } else if (index == 2) {
                          // Voir le profil - Navigate to profile
                          Navigator.of(context).pushNamed('/Profile', arguments: {'id': postsAccount.id});
                        } else if (index == 3) {
                          // Mute User
                          apiService.muteUser(postsAccount.id);
                        }
                        // Option 4 (Supprimer) needs implementation
                      },
                      itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 1,
                              child: Text("Voir la Publication"),
                            ),
                            const PopupMenuItem(
                              value: 2,
                              child: Text("Voir le profil"),
                            ),
                            const PopupMenuItem(
                              value: 3,
                              child: Text("Mute User"),
                            ),
                            const PopupMenuItem(
                              value: 4,
                              child: Text("Supprimer"),
                            )
                          ]),
                )
              ],
            )),
          ],
        ));
  }
}
