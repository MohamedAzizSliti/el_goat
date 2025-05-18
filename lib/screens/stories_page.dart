import 'package:flutter/material.dart';
import '../widgets/navbar/bottom_navbar.dart';

class StoriesPage extends StatefulWidget {
  const StoriesPage({super.key});

  @override
  State<StoriesPage> createState() => _StoriesPageState();
}

class _StoriesPageState extends State<StoriesPage> {
  int _selectedIndex = 1;

  List storiesArr = [
    {
      "name": "Story 1",
      "image": "assets/images/1.jpg",
      "title": "Story",
      "subtitle": "This is the first story"
    },
    {
      "name": "Story 2",
      "image": "assets/images/2.jpg",
      "title": "Story",
      "subtitle": "This is the second story"
    },
    {
      "name": "Story 3",
      "image": "assets/images/5.jpeg",
      "title": "Story",
      "subtitle": "This is the third story"
    },
    {
      "name": "Story 4",
      "image": "assets/images/3.jpg",
      "title": "Story",
      "subtitle": "This is the fourth story"
    },
    {
      "name": "Story 5",
      "image": "assets/images/mb.jpeg",
      "title": "Story",
      "subtitle": "This is the fifth story"
    },
    {
      "name": "Story 6",
      "image": "assets/images/cr7.jpeg",
      "title": "Story",
      "subtitle": "This is the sixth story"
    },
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/');
        break;
      case 1:
        // Stay on StoriesPage
        break;
      case 2:
        Navigator.pushNamed(context, '/news');
        break;
      case 3:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(220, 12, 9, 0),
              Color.fromARGB(255, 136, 98, 49)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          itemCount: storiesArr.length,
          itemBuilder: (context, index) {
            var sObj = storiesArr[index] as Map? ?? {};
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              height: MediaQuery.of(context).size.width * 0.5,
              decoration: BoxDecoration(
                  color: Colors.grey, borderRadius: BorderRadius.circular(10)),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Image.asset(
                    sObj["image"].toString(),
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width * 0.5,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width * 0.5,
                    decoration: BoxDecoration(
                      color: index % 2 == 0
                          ? Colors.black.withOpacity(0.7)
                          : Colors.grey.withOpacity(0.35),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 25, horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sObj["title"],
                          style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                        ),
                        Text(
                          sObj["name"],
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700),
                        ),
                        Text(
                          sObj["subtitle"],
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 25,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Navigate to the detail view
                                },
                                child: const Text(
                                  "see more",
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavbar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
