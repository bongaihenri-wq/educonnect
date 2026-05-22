// lib/presentation/widgets/scrollable_list_section.dart
import 'package:flutter/material.dart';

class ScrollableListSection extends StatelessWidget {
  final List<Widget> children;
  final double maxHeight;
  final bool isSmall;

  const ScrollableListSection({
    super.key,
    required this.children,
    this.maxHeight = 280, // Hauteur pour ~5 éléments
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Indicateur visuel "scrollable"
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        
        // Zone scrollable
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: isSmall ? maxHeight * 0.8 : maxHeight,
          ),
          child: Scrollbar(
            thumbVisibility: true,
            radius: const Radius.circular(4),
            thickness: 4,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: children.length,
              itemBuilder: (context, index) => children[index],
            ),
          ),
        ),
        
        // Indicateur bas "plus de contenu"
        if (children.length > 5)
          Container(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Colors.grey[400],
            ),
          ),
      ],
    );
  }
}