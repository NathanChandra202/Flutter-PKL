import re

with open('lib/screens/manage_rooms_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add dart:convert import if not present
if 'import \'dart:convert\';' not in content:
    content = content.replace('import \'dart:io\';', 'import \'dart:convert\';\nimport \'dart:io\';')

# Replace _showRoomForm state init
state_init_replacement = """    // imageController tidak lagi dipakai
    List<String> imageUrls = [];
    if (room?['image_url'] != null && room!['image_url'].toString().isNotEmpty) {
      imageUrls.add(room!['image_url']);
    }
    if (room?['additional_images'] != null && room!['additional_images'].toString().isNotEmpty) {
      try {
        final List<dynamic> decoded = json.decode(room!['additional_images']);
        imageUrls.addAll(decoded.map((e) => e.toString()));
      } catch (e) {
        // ignore
      }
    }
    
    final addImageController = TextEditingController();
    
    bool isAvailable = room?['is_available'] ?? true;
"""
content = re.sub(
    r'    // imageController tetap dipakai.*?bool isAvailable = room\?\[\'is_available\'\] \?\? true;',
    state_init_replacement,
    content,
    flags=re.DOTALL
)

# Remove pickedImage and isUploading
content = re.sub(r'    XFile\? pickedImage; // gambar yang dipilih dari galeri/kamera\n    bool isUploading = false;\n', '', content)

# Replace image picker UI
picker_ui_replacement = """                    const Text(
                      'Gambar Kamar (Utama & Tambahan)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (imageUrls.isNotEmpty)
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: imageUrls.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    imageUrls[idx],
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 120,
                                      height: 120,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.broken_image, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        imageUrls.removeAt(idx);
                                      });
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                                if (idx == 0)
                                  Positioned(
                                    bottom: 4,
                                    left: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('Utama', style: TextStyle(color: Colors.white, fontSize: 10)),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Center(child: Text('Belum ada gambar')),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: addImageController,
                            decoration: const InputDecoration(
                              labelText: 'URL Gambar',
                              hintText: 'https://...',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (addImageController.text.isNotEmpty) {
                              setModalState(() {
                                imageUrls.add(addImageController.text);
                                addImageController.clear();
                              });
                            }
                          },
                          child: const Text('Tambah'),
                        ),
                      ],
                    ),"""

content = re.sub(
    r'                    const Text\(\s*\'Gambar Kamar\',[\s\S]*?isDense: true,\n\s*\),\n\s*\),',
    picker_ui_replacement,
    content
)

# Replace data build logic
data_build_replacement = """                          'image_url': imageUrls.isNotEmpty ? imageUrls.first : '',
                          'additional_images': imageUrls.length > 1 ? json.encode(imageUrls.sublist(1)) : '',"""

content = content.replace(
    "'image_url': imageController.text,",
    data_build_replacement
)

with open('lib/screens/manage_rooms_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated successfully")
