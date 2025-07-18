import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:skedule3/signup.dart'; // SignUpPage
import 'package:skedule3/login.dart'; // If needed for back navigation

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final controller = PageController();
  bool isLastPage = false;
  double pageOffset = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget buildPage({
    required int index,
    required double pageOffset,
    required Color color,
    required String urlImage,
    required String title,
    required String subtitle,
  }) {
    final double delta = index - pageOffset;

    return Container(
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.translate(
            offset: Offset(delta * 100, 0),
            child: Image.asset(urlImage, height: 200),
          ),
          const SizedBox(height: 32),
          Transform.translate(
            offset: Offset(delta * 60, 0),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Transform.translate(
            offset: Offset(delta * 30, 0),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      {
        'image': 'assets/skedule1.png',
        'title': 'Welcome to Skedule',
        'subtitle': 'Your ultimate academic planner.',
      },
      {
        'image': 'assets/skedule2.png',
        'title': 'Never Miss a Class.',
        'subtitle': 'Your full weekly schedule, at a glance.',
      },
      {
        'image': 'assets/skedule3.png',
        'title': 'Conquer Every Deadline.',
        'subtitle': 'Track assignments, set priorities, and check off tasks.',
      },
      {
        'image': 'assets/skedule4.png',
        'title': 'Ready to Be Ahead?',
        'subtitle': '',
      },
    ];

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification.metrics is PageMetrics) {
            setState(() {
              pageOffset =
                  scrollNotification.metrics.pixels / MediaQuery.of(context).size.width;
            });
          }
          return false;
        },
        child: Container(
          padding: const EdgeInsets.only(bottom: 80),
          child: PageView.builder(
            controller: controller,
            itemCount: pages.length,
            onPageChanged: (index) {
              setState(() => isLastPage = index == pages.length - 1);
            },
            itemBuilder: (context, index) {
              return buildPage(
                index: index,
                pageOffset: pageOffset,
                color: const Color.fromARGB(173, 231, 221, 255),
                urlImage: pages[index]['image']!,
                title: pages[index]['title']!,
                subtitle: pages[index]['subtitle']!,
              );
            },
          ),
        ),
      ),
      bottomSheet: isLastPage
          ? TextButton(
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                foregroundColor: Colors.white,
                backgroundColor: const Color.fromARGB(255, 141, 74, 255),
                minimumSize: const Size.fromHeight(80),
              ),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const SignUpPage()),
                );
              },
              child: const Text(
                'Sign Up',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              height: 80,
              color: const Color.fromARGB(255, 141, 93, 217),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => controller.jumpToPage(pages.length - 1),
                    child: const Text('SKIP', style: TextStyle(color: Colors.white)),
                  ),
                  SmoothPageIndicator(
                    controller: controller,
                    count: pages.length,
                    effect: const ExpandingDotsEffect(
                      dotWidth: 10,
                      dotHeight: 10,
                      activeDotColor: Colors.white,
                      dotColor: Colors.white24,
                    ),
                  ),
                  TextButton(
                    onPressed: () => controller.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    ),
                    child: const Text('NEXT', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
    );
  }
}
