import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/document_provider.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  bool _isLoading = false;
  Map<BookDocument, List<Highlight>> _groupedNotes = {};

  @override
  void initState() {
    super.initState();
    _loadGroupedNotes();
  }

  Future<void> _loadGroupedNotes() async {
    setState(() {
      _isLoading = true;
    });

    final docProvider = Provider.of<DocumentProvider>(context, listen: false);
    
    try {
      await docProvider.fetchDocuments();
      
      final Map<BookDocument, List<Highlight>> tempGroup = {};
      
      for (final doc in docProvider.documents) {
        final highlights = await docProvider.fetchHighlights(doc.id);
        if (highlights.isNotEmpty) {
          tempGroup[doc] = highlights;
        }
      }

      setState(() {
        _groupedNotes = tempGroup;
      });
    } catch (e) {
      debugPrint('Error loading notes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _deleteNote(int id) async {
    final docProvider = Provider.of<DocumentProvider>(context, listen: false);
    try {
      await docProvider.deleteHighlight(id);
      setState(() {
        for (final doc in _groupedNotes.keys) {
          _groupedNotes[doc]!.removeWhere((hl) => hl.id == id);
        }
        _groupedNotes.removeWhere((doc, list) => list.isEmpty);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus catatan: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _showTtsPronunciation(String text) async {
    final docProvider = Provider.of<DocumentProvider>(context, listen: false);
    try {
      await docProvider.speak(text, 'american');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('TTS Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final docProvider = Provider.of<DocumentProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Reading Notes',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22, color: const Color(0xFF0F172A)),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFB45309)))
          : RefreshIndicator(
              onRefresh: _loadGroupedNotes,
              color: const Color(0xFFB45309),
              child: _groupedNotes.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _groupedNotes.length,
                      itemBuilder: (context, index) {
                        final doc = _groupedNotes.keys.elementAt(index);
                        final highlights = _groupedNotes[doc]!;
                        return _buildBookGroup(doc, highlights, docProvider.isSpeaking);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE7E5E4)),
              ),
              child: const Text('📝', style: TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada catatan',
              style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Catatan kosa kata AI Anda akan muncul di sini\nsetelah Anda menandainya di PDF Reader.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF78716C), fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookGroup(BookDocument doc, List<Highlight> highlights, bool isSpeaking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: const Color(0xFFF1F5F9),
            child: Row(
              children: [
                const Icon(Icons.menu_book, color: Color(0xFFB45309), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    doc.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB45309).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${highlights.length} kosa kata',
                    style: const TextStyle(fontSize: 10, color: Color(0xFFB45309), fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: highlights.length,
            itemBuilder: (context, idx) {
              final hl = highlights[idx];
              return _buildHighlightTile(hl, isSpeaking);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightTile(Highlight hl, bool isSpeaking) {
    return ExpansionTile(
      backgroundColor: Colors.white,
      collapsedIconColor: const Color(0xFF78716C),
      iconColor: const Color(0xFFB45309),
      title: Text(
        hl.textContent,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0F172A),
          fontSize: 14.5,
        ),
      ),
      subtitle: Text(
        hl.aiTranslation ?? hl.note ?? 'Stabilo tanpa catatan AI',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Color(0xFF78716C), fontSize: 12),
      ),
      leading: IconButton(
        icon: const Icon(Icons.volume_up, color: Color(0xFF78716C), size: 20),
        onPressed: () => _showTtsPronunciation(hl.textContent),
        tooltip: 'Mainkan Pengucapan',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Hal. ${hl.pageNumber}',
              style: const TextStyle(fontSize: 9, color: Color(0xFF78716C)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
            onPressed: () => _deleteNote(hl.id),
            tooltip: 'Hapus Catatan',
          ),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hl.aiExplanation != null) ...[
                _buildSubSection('Definisi AI:', hl.aiExplanation!),
                const SizedBox(height: 10),
              ],
              if (hl.aiGrammar != null) ...[
                _buildSubSection('Struktur & Tata Bahasa:', hl.aiGrammar!),
                const SizedBox(height: 10),
              ],
              if (hl.aiIdiomNote != null && hl.aiIdiomNote != 'Bukan ungkapan/idiom') ...[
                _buildSubSection('Info Idiom:', hl.aiIdiomNote!),
                const SizedBox(height: 10),
              ],
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Disimpan pada: ${hl.createdAt.toLocal().toString().substring(0, 16)}',
                    style: const TextStyle(color: Color(0xFF78716C), fontSize: 10),
                  ),
                  TextButton.icon(
                    onPressed: () => _showTtsPronunciation(hl.textContent),
                    icon: const Icon(Icons.volume_up, size: 14, color: Color(0xFFB45309)),
                    label: const Text('Dengarkan', style: TextStyle(fontSize: 11, color: Color(0xFFB45309))),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  )
                ],
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildSubSection(String label, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFB45309),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: GoogleFonts.inter(
            color: const Color(0xFF1E293B),
            fontSize: 12.5,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
