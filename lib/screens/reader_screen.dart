import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/document_provider.dart';

class ReaderScreen extends StatefulWidget {
  final BookDocument document;

  const ReaderScreen({super.key, required this.document});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  Uint8List? _pdfBytes;
  bool _isLoadingPdfBytes = true;
  String? _pdfLoadError;

  PdfDocument? _pdfDocument;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isDocumentLoaded = false;
  bool _isExtractingText = false;

  List<String> _currentParagraphs = [];
  final Map<int, List<String>> _pageTextCache = {};

  List<Highlight> _savedHighlights = [];
  bool _hideHighlights = false;

  String? _selectedText;
  bool _showFloatingToolbar = false;

  final TextEditingController _pageInputController = TextEditingController();

  int _colorIndex = 0;
  final List<String> _neonColorStrings = [
    'rgba(255, 255, 0, 0.7)', 
    'rgba(0, 255, 0, 0.5)', 
    'rgba(0, 255, 255, 0.6)', 
    'rgba(255, 0, 255, 0.5)', 
    'rgba(255, 153, 0, 0.7)', 
    'rgba(186, 85, 211, 0.6)',
  ];

  String? _tempHighlightText;
  String? _tempHighlightColor;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.document.lastPage;
    _pageInputController.text = _currentPage.toString();
    _loadHighlights();
    _loadPdfBytes();
  }

  @override
  void dispose() {
    _pageInputController.dispose();
    _pdfDocument?.dispose();
    super.dispose();
  }

  Future<void> _loadPdfBytes() async {
    if (!mounted) return;
    setState(() {
      _isLoadingPdfBytes = true;
      _pdfLoadError = null;
    });
    try {
      final docProvider = Provider.of<DocumentProvider>(context, listen: false);
      final bytes = await docProvider.loadDocumentBytes(
        widget.document.fileUrl,
      );
      if (mounted) {
        setState(() {
          _pdfBytes = bytes;
          _isLoadingPdfBytes = false;
        });
        await _initializePdf();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pdfLoadError = e.toString().replaceAll('Exception: ', '');
          _isLoadingPdfBytes = false;
        });
      }
    }
  }

  Future<void> _initializePdf() async {
    if (_pdfBytes == null) return;
    try {
      _pdfDocument = PdfDocument(inputBytes: _pdfBytes);
      _totalPages = _pdfDocument!.pages.count;

      final docProvider = Provider.of<DocumentProvider>(context, listen: false);
      docProvider.updateTotalPages(widget.document.id, _totalPages);

      await _loadPageText(_currentPage);
    } catch (e) {
      setState(() {
        _pdfLoadError = 'Gagal memproses file PDF';
      });
    }
  }

  Future<void> _loadPageText(int pageNum) async {
    if (_pdfDocument == null) return;
    setState(() {
      _isExtractingText = true;
    });

    try {
      final pageIndex = pageNum - 1;
      if (pageIndex < 0 || pageIndex >= _totalPages) return;

      if (_pageTextCache.containsKey(pageNum)) {
        setState(() {
          _currentParagraphs = _pageTextCache[pageNum]!;
          _isExtractingText = false;
          _isDocumentLoaded = true;
        });
        _syncPageProgress(pageNum);
        return;
      }

      final extractor = PdfTextExtractor(_pdfDocument!);
      final List<TextLine> textLines = extractor.extractTextLines(
        startPageIndex: pageIndex,
        endPageIndex: pageIndex,
      );

      List<String> paragraphs = [];
      String currentParagraph = '';
      double? lastY;

      for (final line in textLines) {
        final text = line.text.trim();
        if (text.isEmpty) continue;

        final y = line.bounds.top;

        if (lastY != null && (lastY - y).abs() > 22) {
          if (currentParagraph.isNotEmpty) {
            paragraphs.add(currentParagraph);
            currentParagraph = '';
          }
        } else if (currentParagraph.isNotEmpty &&
            lastY != null &&
            (lastY - y).abs() > 5) {
          currentParagraph += ' ';
        } else if (currentParagraph.isNotEmpty) {
          currentParagraph += ' ';
        }
        currentParagraph += text;
        lastY = y;
      }
      if (currentParagraph.isNotEmpty) {
        paragraphs.add(currentParagraph);
      }

      if (paragraphs.isEmpty) {
        final text = extractor.extractText(
          startPageIndex: pageIndex,
          endPageIndex: pageIndex,
        );
        if (text.trim().isNotEmpty) {
          paragraphs = text
              .split('\n')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }
      }

      _pageTextCache[pageNum] = paragraphs;

      setState(() {
        _currentParagraphs = paragraphs;
        _isExtractingText = false;
        _isDocumentLoaded = true;
      });

      _syncPageProgress(pageNum);
    } catch (e) {
      debugPrint('Error extracting text: $e');
      setState(() {
        _isExtractingText = false;
      });
    }
  }

  void _syncPageProgress(int pageNum) {
    final docProvider = Provider.of<DocumentProvider>(context, listen: false);
    docProvider.updateProgress(widget.document.id, pageNum);
  }

  Future<void> _loadHighlights() async {
    final docProvider = Provider.of<DocumentProvider>(context, listen: false);
    final highlights = await docProvider.fetchHighlights(widget.document.id);
    if (mounted) {
      setState(() {
        _savedHighlights = highlights;
      });
    }
  }

  int _getWordCount(String text) {
    return text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  void _triggerAiExplanation() {
    if (_selectedText == null || _selectedText!.trim().isEmpty) return;

    final wordToExplain = _selectedText!.trim();
    final chosenColor = _neonColorStrings[_colorIndex];

    setState(() {
      _tempHighlightText = wordToExplain;
      _tempHighlightColor = chosenColor;
      _showFloatingToolbar = false;
      _colorIndex = (_colorIndex + 1) % _neonColorStrings.length;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AiExplanationSheet(
        documentId: widget.document.id,
        pageNumber: _currentPage,
        text: wordToExplain,
        highlightColor: chosenColor,
        onNoteSaved: () {
          _loadHighlights();
          setState(() {
            _tempHighlightText = null;
            _tempHighlightColor = null;
          });
        },
      ),
    ).then((_) {
      setState(() {
        _tempHighlightText = null;
        _tempHighlightColor = null;
      });
    });
  }

  void _showHighlightDetailsSheet(Highlight highlight) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AiExplanationSheet(
        documentId: widget.document.id,
        pageNumber: highlight.pageNumber,
        text: highlight.textContent,
        highlightColor: highlight.color,
        highlight: highlight,
        onNoteSaved: () {
          _loadHighlights();
        },
      ),
    );
  }

  Color _parseHighlightColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        final hex = colorStr.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      }
      if (colorStr.contains('rgb')) {
        final matches = RegExp(
          r'\d+',
        ).allMatches(colorStr).map((m) => int.parse(m.group(0)!)).toList();
        if (matches.length >= 3) {
          double opacity = 1.0;
          final opacityMatch = RegExp(r'0?\.\d+|1(\.0)?').firstMatch(colorStr);
          if (opacityMatch != null) {
            opacity = double.tryParse(opacityMatch.group(0)!) ?? 1.0;
          }
          return Color.fromRGBO(matches[0], matches[1], matches[2], opacity);
        }
      }
      if (colorStr.contains('yellow')) return Colors.yellow;
      if (colorStr.contains('green')) return Colors.green;
      if (colorStr.contains('blue')) return Colors.blue;
      if (colorStr.contains('magenta') || colorStr.contains('pink'))
        return Colors.purpleAccent;
      if (colorStr.contains('orange')) return Colors.orange;
      if (colorStr.contains('purple')) return Colors.purple;
    } catch (e) {
      debugPrint('Error parsing color $colorStr: $e');
    }
    return Colors.amber;
  }

  List<TextSpan> _buildParagraphSpans(
    String paragraphText,
    List<Highlight> pageHighlights,
  ) {
    if (_hideHighlights) {
      return [TextSpan(text: paragraphText)];
    }

    final List<Highlight> activeHighlights = List.from(pageHighlights);
    if (_tempHighlightText != null && _tempHighlightColor != null) {
      activeHighlights.add(
        Highlight(
          id: -1,
          documentId: widget.document.id,
          pageNumber: _currentPage,
          textContent: _tempHighlightText!,
          x: 0,
          y: 0,
          width: 0,
          height: 0,
          color: _tempHighlightColor!,
          createdAt: DateTime.now(),
        ),
      );
    }

    final List<_HighlightMatch> matches = [];

    for (final hl in activeHighlights) {
      final phrase = hl.textContent.trim();
      if (phrase.length < 2) continue;

      int startIndex = 0;
      final lowerText = paragraphText.toLowerCase();
      final lowerPhrase = phrase.toLowerCase();

      while (true) {
        final index = lowerText.indexOf(lowerPhrase, startIndex);
        if (index == -1) break;

        matches.add(
          _HighlightMatch(
            start: index,
            end: index + phrase.length,
            highlight: hl,
          ),
        );
        startIndex = index + phrase.length;
      }
    }

    matches.sort((a, b) {
      int cmp = a.start.compareTo(b.start);
      if (cmp != 0) return cmp;
      return (b.end - b.start).compareTo(a.end - a.start);
    });

    final List<_HighlightMatch> nonOverlappingMatches = [];
    int currentEnd = 0;

    for (final match in matches) {
      if (match.start >= currentEnd) {
        nonOverlappingMatches.add(match);
        currentEnd = match.end;
      }
    }

    final List<TextSpan> spans = [];
    int lastIdx = 0;

    for (final match in nonOverlappingMatches) {
      if (match.start > lastIdx) {
        spans.add(
          TextSpan(text: paragraphText.substring(lastIdx, match.start)),
        );
      }

      final matchedText = paragraphText.substring(match.start, match.end);
      final hlColor = _parseHighlightColor(match.highlight.color);

      spans.add(
        TextSpan(
          text: matchedText,
          style: TextStyle(
            backgroundColor: hlColor.withOpacity(0.4),
            fontWeight: FontWeight.bold,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (match.highlight.id != -1) {
                _showHighlightDetailsSheet(match.highlight);
              }
            },
        ),
      );

      lastIdx = match.end;
    }

    if (lastIdx < paragraphText.length) {
      spans.add(TextSpan(text: paragraphText.substring(lastIdx)));
    }

    return spans;
  }

  void _showSavedHighlightsDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF8F5EF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final docProvider = Provider.of<DocumentProvider>(context);
            return Container(
              padding: const EdgeInsets.all(24),
              height: MediaQuery.of(context).size.height * 0.72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reading Notes (${_savedHighlights.length})',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF78716C)),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _savedHighlights.isEmpty
                        ? Center(
                            child: Text(
                              'Belum ada catatan.',
                              style: TextStyle(color: const Color(0xFF78716C)),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _savedHighlights.length,
                            separatorBuilder: (_, __) =>
                                const Divider(color: Color(0xFFE2E8F0)),
                            itemBuilder: (context, idx) {
                              final hl = _savedHighlights[idx];
                              final hlColor = _parseHighlightColor(hl.color);
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 5,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: hlColor,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: hlColor.withOpacity(0.25),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '"${hl.textContent}"',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5,
                                          color: const Color(0xFF0F172A),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                ),
                                subtitle: Text(
                                  hl.aiTranslation ?? 'Tidak ada terjemahan.',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF78716C),
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildSpeechButtons(
                                      hl.textContent,
                                      docProvider,
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Hal. ${hl.pageNumber}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF78716C),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        _showDeleteConfirmation(
                                          context,
                                          hl,
                                          setModalState,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  setState(() {
                                    _currentPage = hl.pageNumber;
                                    _pageInputController.text = _currentPage
                                        .toString();
                                  });
                                  _loadPageText(hl.pageNumber);
                                  Future.delayed(
                                    const Duration(milliseconds: 100),
                                    () {
                                      _showHighlightDetailsSheet(hl);
                                    },
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Highlight hl,
    StateSetter setModalState,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF8F5EF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Catatan',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus catatan dan stabilo ini? Tindakan ini tidak dapat dibatalkan.',
          style: GoogleFonts.inter(color: const Color(0xFF0F172A)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final docProvider = Provider.of<DocumentProvider>(
                context,
                listen: false,
              );
              await docProvider.deleteHighlight(hl.id);
              await _loadHighlights();
              setModalState(() {});
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechButtons(String text, DocumentProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => provider.speak(text, 'american'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('🇺🇸', style: TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => provider.speak(text, 'british'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('🇬🇧', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  void _onPrevPage() {
    if (_currentPage > 1) {
      final prev = _currentPage - 1;
      setState(() {
        _currentPage = prev;
        _pageInputController.text = prev.toString();
      });
      _loadPageText(prev);
    }
  }

  void _onNextPage() {
    if (_currentPage < _totalPages) {
      final next = _currentPage + 1;
      setState(() {
        _currentPage = next;
        _pageInputController.text = next.toString();
      });
      _loadPageText(next);
    }
  }

  void _onPageInputSubmitted(String val) {
    final page = int.tryParse(val);
    if (page != null && page >= 1 && page <= _totalPages) {
      setState(() {
        _currentPage = page;
      });
      _loadPageText(page);
    } else {
      _pageInputController.text = _currentPage.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageHighlights = _savedHighlights
        .where((hl) => hl.pageNumber == _currentPage)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EF),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.document.title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: const Color(0xFF0F172A),
              ),
            ),
            if (_isDocumentLoaded)
              Text(
                'Halaman $_currentPage dari $_totalPages',
                style: const TextStyle(fontSize: 11, color: Color(0xFF78716C)),
              ),
          ],
        ),
        backgroundColor: const Color(0xFFF8F5EF),
        actions: [
          IconButton(
            icon: Icon(
              _hideHighlights
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: const Color(0xFF0F172A),
            ),
            onPressed: () {
              setState(() {
                _hideHighlights = !_hideHighlights;
              });
            },
            tooltip: _hideHighlights
                ? 'Tampilkan Stabilo'
                : 'Sembunyikan Stabilo',
          ),
          IconButton(
            icon: const Icon(
              Icons.description_outlined,
              color: Color(0xFF0F172A),
            ),
            onPressed: _showSavedHighlightsDrawer,
            tooltip: 'Reading Notes',
          ),
        ],
      ),
      bottomNavigationBar: _isDocumentLoaded
          ? Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    onPressed: _currentPage > 1 ? _onPrevPage : null,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 50,
                    height: 36,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _pageInputController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical(y: 0.8),
                      onSubmitted: _onPageInputSubmitted,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '/  $_totalPages',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF78716C),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 28),
                    onPressed: _currentPage < _totalPages ? _onNextPage : null,
                  ),
                ],
              ),
            )
          : null,
      body: _isLoadingPdfBytes
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFB45309)),
                  SizedBox(height: 16),
                  Text(
                    'Mengunduh dokumen...',
                    style: TextStyle(color: Color(0xFF78716C)),
                  ),
                ],
              ),
            )
          : _pdfLoadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal mengunduh dokumen:\n$_pdfLoadError',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0F172A),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadPdfBytes,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: Text(
                        'Coba Lagi',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB45309),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _isExtractingText
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFB45309)),
                  SizedBox(height: 16),
                  Text(
                    'Mengekstrak teks halaman...',
                    style: TextStyle(color: Color(0xFF78716C)),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: SelectionArea(
                    onSelectionChanged: (SelectedContent? content) {
                      if (content != null) {
                        final selectedText = content.plainText.trim();
                        if (selectedText.isNotEmpty) {
                          final words = _getWordCount(selectedText);
                          if (words > 7) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Terlalu panjang ($words kata). AI khusus untuk frasa pendek / vocab (Maks: 7 kata).',
                                ),
                                backgroundColor: Colors.amber[800],
                                duration: const Duration(seconds: 3),
                              ),
                            );
                            setState(() {
                              _selectedText = null;
                              _showFloatingToolbar = false;
                            });
                          } else {
                            setState(() {
                              _selectedText = selectedText;
                              _showFloatingToolbar = true;
                            });
                          }
                        } else {
                          setState(() {
                            _showFloatingToolbar = false;
                          });
                        }
                      } else {
                        setState(() {
                          _showFloatingToolbar = false;
                        });
                      }
                    },
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_currentParagraphs.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 40,
                                ),
                                child: Text(
                                  'Halaman ini kosong.',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF78716C),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            )
                          else
                            ..._currentParagraphs.map((paragraphText) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 18.0),
                                child: Text.rich(
                                  TextSpan(
                                    children: _buildParagraphSpans(
                                      paragraphText,
                                      pageHighlights,
                                    ),
                                  ),
                                  style: GoogleFonts.inter(
                                    fontSize: 15.5,
                                    height: 1.65,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  textAlign: TextAlign.justify,
                                ),
                              );
                            }),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),

                if (_showFloatingToolbar && _selectedText != null)
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: SafeArea(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.96),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pilihan Teks:',
                                    style: TextStyle(
                                      color: Color(0xFF78716C),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '"$_selectedText"',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF0F172A),
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _triggerAiExplanation,
                              icon: const Text(
                                '✨',
                                style: TextStyle(fontSize: 14),
                              ),
                              label: Text(
                                'Tanya AI',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB45309),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _HighlightMatch {
  final int start;
  final int end;
  final Highlight highlight;

  _HighlightMatch({
    required this.start,
    required this.end,
    required this.highlight,
  });
}

class AiExplanationSheet extends StatefulWidget {
  final int documentId;
  final int pageNumber;
  final String text;
  final String highlightColor;
  final VoidCallback onNoteSaved;
  final Highlight? highlight;

  const AiExplanationSheet({
    super.key,
    required this.documentId,
    required this.pageNumber,
    required this.text,
    required this.highlightColor,
    required this.onNoteSaved,
    this.highlight,
  });

  @override
  State<AiExplanationSheet> createState() => _AiExplanationSheetState();
}

class _AiExplanationSheetState extends State<AiExplanationSheet> {
  bool _isLoading = true;
  String? _error;

  String _translation = '';
  String _explanation = '';
  String _grammar = '';
  List<String> _collocations = [];
  String _nuance = '';
  String _tenseInfo = '';
  String _idiomNote = '';
  String _tip = '';

  bool _isSaved = false;
  bool _isUnlocked = false;
  bool _isLoadingSave = false;

  @override
  void initState() {
    super.initState();
    if (widget.highlight != null) {
      final hl = widget.highlight!;
      _translation = hl.aiTranslation ?? '';
      _explanation = hl.aiExplanation ?? '';
      _grammar = hl.aiGrammar ?? '';
      _collocations = List<String>.from(hl.collocations);
      _nuance = hl.nuance ?? '';
      _tenseInfo = hl.tenseInfo ?? '';
      _idiomNote = hl.aiIdiomNote ?? '';
      _tip = hl.tip ?? '';
      _isSaved = true;
      _isUnlocked = true;
      _isLoading = false;
    } else {
      _loadExplanation();
    }
  }

  void _loadExplanation() async {
    final docProvider = Provider.of<DocumentProvider>(context, listen: false);
    try {
      final data = await docProvider.explainText(widget.text, widget.text);
      if (mounted) {
        setState(() {
          _translation = data['translation'] ?? '';
          _explanation = data['explanation'] ?? '';
          _grammar = data['grammar'] ?? '';
          _collocations = List<String>.from(data['collocations'] ?? []);
          _nuance = data['nuance'] ?? '';
          _tenseInfo = data['tense_info'] ?? '';
          _idiomNote = data['idiom_note'] ?? '';
          _tip = data['tip'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _saveToNotes() async {
    if (_isSaved) return;

    final docProvider = Provider.of<DocumentProvider>(context, listen: false);
    setState(() {
      _isLoadingSave = true;
    });

    try {
      final details = {
        'grammar': _grammar,
        'collocations': _collocations,
        'idiom_note': _idiomNote,
        'tip': _tip,
        'nuance': _nuance,
        'tense_info': _tenseInfo,
        'vocabulary': _collocations
            .map((e) => {'word': e, 'meaning': ''})
            .toList(),
      };

      await docProvider.createAiNote(
        documentId: widget.documentId,
        pageNumber: widget.pageNumber,
        textContent: widget.text,
        explanation: _explanation,
        translation: _translation,
        color: widget.highlightColor,
        details: details,
      );

      setState(() {
        _isSaved = true;
      });
      widget.onNoteSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Catatan berhasil disimpan.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingSave = false;
      });
    }
  }

  void _deleteNote() async {
    if (widget.highlight == null) return;
    setState(() {
      _isLoadingSave = true;
    });
    try {
      final docProvider = Provider.of<DocumentProvider>(context, listen: false);
      await docProvider.deleteHighlight(widget.highlight!.id);
      widget.onNoteSaved();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Catatan berhasil dihapus.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingSave = false;
      });
    }
  }

  Future<void> _launchYouGlish() async {
    final url = Uri.parse(
      'https://youglish.com/pronounce/${Uri.encodeComponent(widget.text)}/english',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka link YouGlish.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final docProvider = Provider.of<DocumentProvider>(context);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F5EF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.84,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 14),
                  width: 40,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.highlight != null
                          ? 'Detail Catatan'
                          : '🤖 AI Analysis',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF78716C)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Expanded(
                child: _isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Color(0xFFB45309)),
                            SizedBox(height: 16),
                            Text(
                              'Menganalisis teks dengan AI...',
                              style: TextStyle(color: Color(0xFF78716C)),
                            ),
                          ],
                        ),
                      )
                    : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Selected Text Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'TEKS TERPILIH:',
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF78716C),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      _buildSpeechRow(widget.text, docProvider),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '"${widget.text}"',
                                    style: GoogleFonts.inter(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '🧠 ENGLISH EXPLANATION',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFB45309),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      _buildSpeechRow(
                                        _explanation,
                                        docProvider,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _explanation,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      height: 1.5,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (!_isUnlocked)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFECEC),
                                  border: Border.all(
                                    color: Colors.redAccent.withOpacity(0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '🔒 Baca dan pahami penjelasan di atas terlebih dahulu.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red[800],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _isUnlocked = true;
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFB45309,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Saya Sudah Paham — Buka Terjemahan',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6F4EA),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Terbuka',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            IgnorePointer(
                              ignoring: !_isUnlocked,
                              child: Opacity(
                                opacity: _isUnlocked ? 1.0 : 0.3,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildInfoCard(
                                      '🇮🇩 INDONESIAN TRANSLATION',
                                      _translation,
                                      isAccent: true,
                                    ),

                                    Container(
                                      margin: const EdgeInsets.only(bottom: 18),
                                      child: ElevatedButton.icon(
                                        onPressed: _launchYouGlish,
                                        icon: const Text(
                                          '🗣️',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        label: Text(
                                          'Cari di YouGlish',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFED4245,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),

                                    if (_grammar.isNotEmpty)
                                      _buildInfoCard(
                                        '⚙️ GRAMMAR CONTEXT',
                                        _grammar,
                                      ),

                                    if (_collocations.isNotEmpty) ...[
                                      _buildHeader('🔗 COMMON COLLOCATIONS'),
                                      Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 18,
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: _collocations
                                              .map(
                                                (c) => Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFF8F5EF,
                                                    ),
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFFE2E8F0,
                                                      ),
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    c,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: const Color(
                                                        0xFF0F172A,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                    ],

                                    if (_nuance.isNotEmpty &&
                                        _nuance.toLowerCase() !=
                                            'konteks umum' &&
                                        _nuance.toLowerCase() !=
                                            'tidak ada nuansa khusus')
                                      _buildInfoCard(
                                        '🎭 WORD NUANCE & CONNOTATION',
                                        _nuance,
                                      ),

                                    if (_tenseInfo.isNotEmpty &&
                                        !_tenseInfo.toLowerCase().contains(
                                          'bukan kata kerja',
                                        ) &&
                                        _tenseInfo.toLowerCase() !=
                                            'tidak relevan')
                                      _buildInfoCard(
                                        '🕐 TENSE / VERB FORMS',
                                        _tenseInfo,
                                      ),

                                    if (_idiomNote.isNotEmpty &&
                                        !_idiomNote.toLowerCase().contains(
                                          'bukan merupakan ungkapan',
                                        ))
                                      _buildInfoCard(
                                        '🗣️ IDIOMS / PHRASES',
                                        _idiomNote,
                                      ),

                                    if (_tip.isNotEmpty &&
                                        _tip.toLowerCase() !=
                                            'tidak ada tips tambahan')
                                      _buildInfoCard(
                                        '💡 PRO TIP',
                                        _tip,
                                        isTip: true,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
              ),

              if (!_isLoading && _error == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingSave
                        ? null
                        : (widget.highlight != null
                              ? _deleteNote
                              : _saveToNotes),
                    icon: _isLoadingSave
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            widget.highlight != null
                                ? Icons.delete_outline
                                : (_isSaved
                                      ? Icons.check
                                      : Icons.bookmark_add_outlined),
                            color: Colors.white,
                          ),
                    label: Text(
                      widget.highlight != null
                          ? 'Hapus Catatan'
                          : (_isSaved
                                ? 'Tersimpan di Catatan'
                                : 'Simpan ke Catatan'),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 15.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: widget.highlight != null
                          ? Colors.redAccent
                          : (_isSaved ? Colors.green : const Color(0xFFB45309)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeechRow(String text, DocumentProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Text('🇺🇸', style: TextStyle(fontSize: 14)),
          onPressed: () => provider.speak(text, 'american'),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Text('🇬🇧', style: TextStyle(fontSize: 14)),
          onPressed: () => provider.speak(text, 'british'),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFB45309),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String content, {
    bool isAccent = false,
    bool isTip = false,
  }) {
    Color cardBg = Colors.white;
    Color borderBg = const Color(0xFFE2E8F0);
    if (isAccent) {
      cardBg = const Color(0xFFB45309).withOpacity(0.05);
      borderBg = const Color(0xFFB45309).withOpacity(0.15);
    } else if (isTip) {
      cardBg = const Color(0xFF10B981).withOpacity(0.05);
      borderBg = const Color(0xFF10B981).withOpacity(0.15);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(title),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderBg),
          ),
          child: Text(
            content,
            style: GoogleFonts.inter(
              color: const Color(0xFF0F172A),
              fontSize: 13.5,
              height: 1.5,
              fontWeight: isAccent ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
