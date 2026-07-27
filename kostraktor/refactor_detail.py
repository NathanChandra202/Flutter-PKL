import re

with open('lib/screens/detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

if 'import \'dart:convert\';' not in content:
    content = content.replace('import \'package:flutter/material.dart\';', 'import \'package:flutter/material.dart\';\nimport \'dart:convert\';')

# Replace final imageUrl = ... with list parsing
image_list_logic = """    final price = formatRupiah(rawPrice);
    
    List<String> images = [];
    if (unitData?['image'] != null && unitData!['image'].toString().isNotEmpty) {
      images.add(unitData!['image']);
    } else {
      images.add('https://tesmohamadasep.sirv.com/duaenam-grp-source/assets/kostraktor/kamar1.png');
    }
    
    if (unitData?['additional_images'] != null && unitData!['additional_images'].toString().isNotEmpty) {
      try {
        final List<dynamic> decoded = json.decode(unitData!['additional_images']);
        images.addAll(decoded.map((e) => e.toString()));
      } catch (e) {}
    }

    final features ="""

content = re.sub(
    r'    final price = formatRupiah\(rawPrice\);\n    final imageUrl =[\s\S]*?;\n    final features =',
    image_list_logic,
    content
)

# Replace SliverAppBar flexibleSpace background
flexible_space_replacement = """            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  StatefulBuilder(
                    builder: (context, setState) {
                      int currentIndex = 0;
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          PageView.builder(
                            itemCount: images.length,
                            onPageChanged: (index) {
                              setState(() {
                                currentIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return Image.network(
                                images[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(color: Colors.grey.shade200),
                              );
                            },
                          ),
                          if (images.length > 1)
                            Positioned(
                              bottom: 120, // above the gradient
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  images.length,
                                  (index) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: currentIndex == index ? 16 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: currentIndex == index
                                          ? AppTheme.accentGold
                                          : Colors.white.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    }
                  ),
                  // Bottom gradient so title is legible"""

content = re.sub(
    r'            flexibleSpace: FlexibleSpaceBar\(\n              background: Stack\(\n                fit: StackFit.expand,\n                children: \[\n                  Image.network\([\s\S]*?\),\n                  // Bottom gradient so title is legible',
    flexible_space_replacement,
    content
)

with open('lib/screens/detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("detail_screen updated")
