import 'package:auditory/CommunityProvider.dart';
import 'package:auditory/SelectedCommunitiesProvider.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SelectCommunities extends StatefulWidget {
  @override
  _SelectCommunitiesState createState() => _SelectCommunitiesState();
}

class _SelectCommunitiesState extends State<SelectCommunities> {
  List selectedCommunities = [];

  @override
  Widget build(BuildContext context) {
    var communities = Provider.of<CommunityProvider>(context);
    var selectCommunities = Provider.of<SelectedCommunityProvider>(context);
    SizeConfig().init(context);
    return Container(
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  for (var v in (communities.userCreatedCommunities +
                      communities.userCommunities))
                    InkWell(
                      onTap: () {
                        if (selectedCommunities.indexOf(v) == -1) {
                          if (selectedCommunities.length < 6) {
                            setState(() {
                              selectedCommunities.add(v);
                            });
                          }

                          print(selectedCommunities);
                        } else {
                          setState(() {
                            selectedCommunities.remove(v);
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: kSecondaryColor),
                            borderRadius: BorderRadius.circular(10),
                            color: selectedCommunities.indexOf(v) == -1
                                ? kPrimaryColor
                                : kSecondaryColor),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.transparent,
                              backgroundImage: v['profileImageUrl'] == null
                                  ? AssetImage('assets/images/Favicon.png')
                                  : NetworkImage(v['profileImageUrl']),
                              // backgroundImage: v['profileImageUrl'] ==
                              //     null
                              //     ? AssetImage(
                              //     'assets/images/Favicon.png')
                              //     : NetworkImage(v['profileImageUrl']),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(5),
                              child: Text(
                                "${v['name']}",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize:
                                        SizeConfig.safeBlockHorizontal * 3),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                selectCommunities.selectedCommunities =
                    selectedCommunities.toSet().toList();
              });

              Navigator.pop(context);

              print(selectCommunities.selectedCommunities);
            },
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xffE73B57), Color(0xff6048F6)])),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Text(
                    'Done',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: SizeConfig.safeBlockHorizontal * 4.5),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
