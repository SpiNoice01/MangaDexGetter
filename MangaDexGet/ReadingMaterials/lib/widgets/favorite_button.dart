import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:apites/services/favorite_service.dart';

class FavoriteButton extends StatefulWidget {
  final String mangaId;
  final Color defaultColor;
  final bool isBeatingAnimation;

  const FavoriteButton({
    super.key,
    required this.mangaId,
    this.defaultColor = Colors.white,
    this.isBeatingAnimation = false,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> with TickerProviderStateMixin {
  final FavoriteService favService = Get.find<FavoriteService>();
  
  late AnimationController _flyController;
  late Animation<double> _flyAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  
  late AnimationController _beatController;
  late Animation<double> _beatAnimation;
  
  bool _showFlyingHeart = false;
  
  @override
  void initState() {
    super.initState();
    _flyController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _flyAnimation = Tween<double>(begin: 0, end: -100).animate(CurvedAnimation(parent: _flyController, curve: Curves.easeOutCubic));
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _flyController, curve: Curves.easeIn));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 2.5).animate(CurvedAnimation(parent: _flyController, curve: Curves.easeOutBack));
    
    _flyController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _showFlyingHeart = false;
          });
        }
        _flyController.reset();
      }
    });
    
    _beatController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _beatAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _beatController, curve: Curves.easeInOut));
  }
  
  @override
  void dispose() {
    _flyController.dispose();
    _beatController.dispose();
    super.dispose();
  }
  
  void _onToggle() async {
    final isFavNow = await favService.toggleFavorite(widget.mangaId);
    if (isFavNow) {
      if (widget.isBeatingAnimation) {
        _beatController.forward(from: 0.0);
      } else {
        if (mounted) {
          setState(() {
            _showFlyingHeart = true;
          });
        }
        _flyController.forward(from: 0.0);
      }
    }
    
    Get.snackbar(
      isFavNow ? 'Added to Favorites' : 'Removed from Favorites',
      isFavNow
          ? 'Manga has been added to your favorites.'
          : 'Manga has been removed from your favorites.',
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF000000).withValues(alpha: 0.7),
      colorText: const Color(0xFFFFFFFF),
      duration: const Duration(milliseconds: 1200),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _beatController,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.isBeatingAnimation ? _beatAnimation.value : 1.0,
              child: child,
            );
          },
          child: Obx(() {
            final isFav = favService.isFavorite(widget.mangaId);
            return IconButton(
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.red : widget.defaultColor,
              ),
              onPressed: _onToggle,
            );
          }),
        ),
        if (_showFlyingHeart)
          AnimatedBuilder(
            animation: _flyController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _flyAnimation.value),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: const Icon(Icons.favorite, color: Colors.pinkAccent),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
