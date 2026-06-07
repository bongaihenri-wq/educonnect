// lib/presentation/widgets/scrollable_list_section.dart
import 'package:flutter/material.dart';

class ScrollableListSection extends StatefulWidget {  // ✅ CHANGÉ : Stateless → Stateful
  final List<Widget> children;
  final double maxHeight;
  final bool isSmall;

  const ScrollableListSection({
    super.key,
    required this.children,
    this.maxHeight = 280,
    this.isSmall = false,
  });

  @override
  State<ScrollableListSection> createState() => _ScrollableListSectionState();  // ✅ AJOUTÉ
}

class _ScrollableListSectionState extends State<ScrollableListSection> {  // ✅ AJOUTÉ
  final ScrollController _scrollController = ScrollController();  // ✅ DÉFINI ICI

  @override
  void dispose() {
    _scrollController.dispose();  // ✅ DISPOSE
    super.dispose();
  }

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
            maxHeight: widget.isSmall ? widget.maxHeight * 0.8 : widget.maxHeight,  // ✅ widget.
          ),
          child: Scrollbar(
            controller: _scrollController,  // ✅ FONCTIONNE MAINTENANT
            thumbVisibility: true,
            radius: const Radius.circular(4),
            thickness: 4,
            child: ListView.builder(
              controller: _scrollController,  // ✅ FONCTIONNE MAINTENANT
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.children.length,  // ✅ widget.
              itemBuilder: (context, index) => widget.children[index],  // ✅ widget.
            ),
          ),
        ),
        
        // Indicateur bas "plus de contenu"
        if (widget.children.length > 5)  // ✅ widget.
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