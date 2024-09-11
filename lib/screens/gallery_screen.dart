import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gallery_provider.dart';
import 'full_image_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<GalleryProvider>(context, listen: false);
      provider.fetchImages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GalleryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pixabay Image Gallery'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: provider.onSearchChanged,
            ),
          ),
        ),
      ),
      body: provider.isLoading && provider.images.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (scrollInfo.metrics.pixels ==
                    scrollInfo.metrics.maxScrollExtent) {
                  provider.fetchMoreImages();
                }
                return true;
              },
              child: GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _getCrossAxisCount(context),
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 0.8,
                ),
                itemCount:
                    provider.images.length + (provider.isFetchingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == provider.images.length) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final image = provider.images[index];
                  return GestureDetector(
                    onTap: () => _openFullScreenImage(context, image),
                    child: Column(
                      children: [
                        Expanded(
                          child: FadeInImage.assetNetwork(
                            placeholder: 'assets/images/place_holder.png',
                            image: image['webformatURL'],
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('${image['likes']} Likes'),
                        Text('${image['views']} Views'),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 5;
    if (width > 800) return 4;
    if (width > 600) return 3;
    return 2;
  }

  void _openFullScreenImage(BuildContext context, dynamic image) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FullScreenImage(imageUrl: image['largeImageURL']);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
            ),
            child: child,
          );
        },
      ),
    );
  }
}
