import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import '../widgets/widgets.dart';
import 'content_viewer_screen.dart';

/// Library tab – unstructured content browsing with tabs, search, and filters.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _tabScrollController = ScrollController();
  late PageController _pageController;
  final Map<int, GlobalKey> _tabKeys = {};

  /// Single source of truth for which tab/page is active (keeps tab bar in sync when swiping).
  int _currentPageIndex = 0;

  static const List<String> _tabLabels = [
    'For You',
    'All',
    'Popular',
    'Recent',
    'Career',
    'Motivation',
  ];

  // Filter state (from bottom sheet)
  Set<String> _selectedContentTypes = {};
  Set<String> _selectedDifficulties = {};
  Set<String> _selectedTags = {};

  void _onSearchChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    for (var i = 0; i < _tabLabels.length; i++) {
      _tabKeys[i] = GlobalKey();
    }
    _searchController.addListener(_onSearchChanged);
  }

  void _scrollTabIntoView(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _tabKeys[index];
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _pageController.dispose();
    _searchController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
  }

  void _openFilterBottomSheet() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final contentTypes = ['PDF', 'Video', 'Image', 'Article', 'Mindmap', 'PYQ'];
    final difficulties = ['Easy', 'Medium', 'Hard'];
    final tags = ['JEE', 'NEET', 'Motivation', 'Olympiad'];

    Set<String> tempTypes = Set.from(_selectedContentTypes);
    Set<String> tempDiffs = Set.from(_selectedDifficulties);
    Set<String> tempTags = Set.from(_selectedTags);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).padding.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionTitle('Filters'),
                  const SizedBox(height: 20),
                  BodySmall('Content type', style: TextStyle(color: colors.captionColor)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: contentTypes.map((t) {
                      final selected = tempTypes.contains(t);
                      return FilterChip(
                        label: BodySmall(t),
                        selected: selected,
                        onSelected: (v) {
                          if (v) {
                            tempTypes.add(t);
                          } else {
                            tempTypes.remove(t);
                          }
                          setModalState(() {});
                        },
                        selectedColor: colors.primaryContainer,
                        checkmarkColor: colors.primary,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  BodySmall('Difficulty', style: TextStyle(color: colors.captionColor)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: difficulties.map((d) {
                      final selected = tempDiffs.contains(d);
                      return FilterChip(
                        label: BodySmall(d),
                        selected: selected,
                        onSelected: (v) {
                          if (v) {
                            tempDiffs.add(d);
                          } else {
                            tempDiffs.remove(d);
                          }
                          setModalState(() {});
                        },
                        selectedColor: colors.primaryContainer,
                        checkmarkColor: colors.primary,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  BodySmall('Tags', style: TextStyle(color: colors.captionColor)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.map((tag) {
                      final selected = tempTags.contains(tag);
                      return FilterChip(
                        label: BodySmall(tag),
                        selected: selected,
                        onSelected: (v) {
                          if (v) {
                            tempTags.add(tag);
                          } else {
                            tempTags.remove(tag);
                          }
                          setModalState(() {});
                        },
                        selectedColor: colors.primaryContainer,
                        checkmarkColor: colors.primary,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          text: 'Reset',
                          onPressed: () {
                            tempTypes.clear();
                            tempDiffs.clear();
                            tempTags.clear();
                            setModalState(() {});
                          },
                          size: ButtonSize.medium,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: PrimaryButton(
                          text: 'Apply',
                          onPressed: () {
                            setState(() {
                              _selectedContentTypes = Set.from(tempTypes);
                              _selectedDifficulties = Set.from(tempDiffs);
                              _selectedTags = Set.from(tempTags);
                            });
                            Navigator.pop(ctx);
                          },
                          size: ButtonSize.medium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _filterItems(
    List<Map<String, dynamic>> items,
    int tabIndex,
    String query,
  ) {
    var list = List<Map<String, dynamic>>.from(items);

    switch (tabIndex) {
      case 0:
        list = list.take(14).toList();
        break;
      case 1:
        break;
      case 2:
        list.sort((a, b) => (b['sortOrder'] as int).compareTo(a['sortOrder'] as int));
        break;
      case 3:
        list.sort((a, b) => (b['sortOrder'] as int).compareTo(a['sortOrder'] as int));
        list = list.take(12).toList();
        break;
      case 4:
        list = list.where((e) => (e['tags'] as List).contains('Career')).toList();
        break;
      case 5:
        list = list.where((e) => (e['tags'] as List).contains('Motivation')).toList();
        break;
    }

    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((e) {
        final title = (e['title'] as String).toLowerCase();
        final subtitle = (e['subtitle'] as String?)?.toLowerCase() ?? '';
        return title.contains(q) || subtitle.contains(q);
      }).toList();
    }

    if (_selectedContentTypes.isNotEmpty) {
      list = list.where((e) {
        final type = (e['type'] as String).toLowerCase();
        if (type == 'pdf' || type == 'article') return _selectedContentTypes.contains('PDF') || _selectedContentTypes.contains('Article');
        if (type == 'video') return _selectedContentTypes.contains('Video');
        if (type == 'image' || type == 'mindmap') return _selectedContentTypes.contains('Image') || _selectedContentTypes.contains('Mindmap');
        return _selectedContentTypes.any((c) => c.toUpperCase() == type.toUpperCase());
      }).toList();
    }
    if (_selectedDifficulties.isNotEmpty) {
      list = list.where((e) => _selectedDifficulties.contains(e['difficulty'])).toList();
    }
    if (_selectedTags.isNotEmpty) {
      list = list.where((e) {
        final itemTags = e['tags'] as List;
        return itemTags.any((t) => _selectedTags.contains(t));
      }).toList();
    }

    return list;
  }

  void _onItemTap(Map<String, dynamic> item) {
    final type = item['type'] as String;
    final title = item['title'] as String;
    final url = item['url'] as String;
    final contentType = type == 'video' ? 'video' : 'pdf';
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ContentViewerScreen(
          contentType: contentType,
          title: title,
          url: url,
          thumbnailUrl: item['thumbnailUrl'] as String?,
          contentId: 'library_${title.hashCode}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final query = _searchController.text;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Library',
        actions: [
          IconButton(
            icon: Icon(Icons.tune_rounded, color: colors.onSurface),
            onPressed: _openFilterBottomSheet,
            tooltip: 'Filters',
          ),
        ],
      ),
      body: MySafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: CustomTextField(
                controller: _searchController,
                hint: 'Search topics, notes, videos...',
                prefixIcon: Icon(Icons.search_rounded, color: colors.captionColor, size: 22),
                suffixIcon: _searchController.text.trim().isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(Icons.close_rounded, color: colors.captionColor, size: 22),
                        onPressed: _clearSearch,
                        tooltip: 'Clear search',
                      ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.builder(
                controller: _tabScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _tabLabels.length,
                itemBuilder: (context, index) {
                  final isSelected = _currentPageIndex == index;
                  return Padding(
                    key: _tabKeys[index],
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _currentPageIndex = index);
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeInOut,
                        );
                        _scrollTabIntoView(index);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.primaryContainer
                              : colors.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        alignment: Alignment.center,
                        child: Subtitle(
                          _tabLabels[index],
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? colors.primary : colors.onSurface,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) {
                  setState(() => _currentPageIndex = i);
                  _scrollTabIntoView(i);
                },
                itemCount: _tabLabels.length,
                itemBuilder: (context, pageIndex) {
                  final items = _filterItems(
                    _dummyLibraryItems,
                    pageIndex,
                    query,
                  );
                  if (items.isEmpty) {
                    return EmptyState(
                      icon: Icons.library_books_rounded,
                      title: 'No content here',
                      subtitle: 'Try another tab or clear filters.',
                      buttonText: 'Clear filters',
                      onButtonPressed: () {
                        _clearSearch();
                        setState(() {
                          _selectedContentTypes.clear();
                          _selectedDifficulties.clear();
                          _selectedTags.clear();
                        });
                      },
                    );
                  }
                  final r = context;
                  return GridView.builder(
                    padding: EdgeInsets.fromLTRB(r.rW(16), 0, r.rW(16), r.rH(24)),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: r.rSp(12),
                      crossAxisSpacing: r.rSp(12),
                      childAspectRatio: r.gridChildAspectRatio(crossAxisCount: 2, minHeightFraction: 0.24),
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _LibraryCard(
                        item: item,
                        colors: colors,
                        onTap: () => _onItemTap(item),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryCard extends StatelessWidget {
  const _LibraryCard({
    required this.item,
    required this.colors,
    required this.onTap,
  });

  final Map<String, dynamic> item;
  final ColorScheme colors;
  final VoidCallback onTap;

  static IconData _iconForType(String type) {
    switch (type.toUpperCase()) {
      case 'PDF':
      case 'ARTICLE':
        return Icons.picture_as_pdf_rounded;
      case 'VIDEO':
        return Icons.play_circle_rounded;
      case 'IMAGE':
      case 'MINDMAP':
        return Icons.account_tree_rounded;
      default:
        return Icons.article_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = item['title'] as String;
    final subtitle = item['subtitle'] as String? ?? '';
    final type = item['type'] as String;
    final progress = item['progress'] as double?;
    final r = context;

    return ContentCard(
      title: title,
      subtitle: subtitle,
      progress: progress,
      thumbnailHeight: r.rH(72),
      thumbnail: Container(
        decoration: BoxDecoration(
          color: colors.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          _iconForType(type),
          size: 36,
          color: colors.primary,
        ),
      ),
      onTap: onTap,
    );
  }
}

final List<Map<String, dynamic>> _dummyLibraryItems = [
  {
    'title': 'How to Prepare for JEE 2027',
    'subtitle': 'Strategy guide • 12 min read',
    'type': 'pdf',
    'url': ContentViewerDummyUrls.pdf,
    'thumbnailUrl': null,
    'tags': ['JEE', 'Career'],
    'difficulty': 'Medium',
    'sortOrder': 10,
  },
  {
    'title': 'Motivational Story: APJ Abdul Kalam',
    'subtitle': 'Video • 8 min',
    'type': 'video',
    'url': ContentViewerDummyUrls.video,
    'thumbnailUrl': null,
    'tags': ['Motivation'],
    'difficulty': 'Easy',
    'sortOrder': 9,
  },
  {
    'title': 'Quick Mindmap: Periodic Table',
    'subtitle': 'Image • Class 10',
    'type': 'image',
    'url': ContentViewerDummyUrls.pdf,
    'thumbnailUrl': null,
    'tags': ['Olympiad'],
    'difficulty': 'Easy',
    'sortOrder': 8,
  },
  {
    'title': 'NEET Biology – Human Physiology',
    'subtitle': 'PDF notes • 24 pages',
    'type': 'pdf',
    'url': ContentViewerDummyUrls.pdf,
    'thumbnailUrl': null,
    'tags': ['NEET'],
    'difficulty': 'Hard',
    'sortOrder': 7,
  },
  {
    'title': '5-Minute Revision: Trigonometry',
    'subtitle': 'Video • 5 min',
    'type': 'video',
    'url': ContentViewerDummyUrls.video,
    'thumbnailUrl': null,
    'tags': ['JEE', 'Olympiad'],
    'difficulty': 'Medium',
    'sortOrder': 6,
  },
  {
    'title': 'Career Tips: Engineering vs Medicine',
    'subtitle': 'Article • 6 min read',
    'type': 'pdf',
    'url': ContentViewerDummyUrls.pdf,
    'thumbnailUrl': null,
    'tags': ['Career', 'JEE', 'NEET'],
    'difficulty': 'Easy',
    'sortOrder': 5,
  },
  {
    'title': 'Daily Motivation: Start Your Day',
    'subtitle': 'Quote & story',
    'type': 'pdf',
    'url': ContentViewerDummyUrls.pdf,
    'thumbnailUrl': null,
    'tags': ['Motivation'],
    'difficulty': 'Easy',
    'sortOrder': 4,
  },
  {
    'title': 'Organic Chemistry Mindmap',
    'subtitle': 'Image • JEE',
    'type': 'mindmap',
    'url': ContentViewerDummyUrls.pdf,
    'thumbnailUrl': null,
    'tags': ['JEE', 'Olympiad'],
    'difficulty': 'Hard',
    'sortOrder': 3,
  },
  {
    'title': 'Previous Year: Physics MCQ',
    'subtitle': 'PYQ • 15 questions',
    'type': 'pdf',
    'url': ContentViewerDummyUrls.pdf,
    'thumbnailUrl': null,
    'tags': ['JEE', 'NEET'],
    'difficulty': 'Medium',
    'sortOrder': 2,
  },
  {
    'title': 'Stress Buster: 2-Minute Breathing',
    'subtitle': 'Video • 2 min',
    'type': 'video',
    'url': ContentViewerDummyUrls.video,
    'thumbnailUrl': null,
    'tags': ['Motivation'],
    'difficulty': 'Easy',
    'sortOrder': 1,
  },
  {
    'title': 'Olympiad Maths – Number Theory',
    'subtitle': 'PDF • 18 pages',
    'type': 'pdf',
    'url': ContentViewerDummyUrls.pdf,
    'thumbnailUrl': null,
    'tags': ['Olympiad'],
    'difficulty': 'Hard',
    'sortOrder': 11,
  },
  {
    'title': 'Why Consistency Beats Intensity',
    'subtitle': 'Motivation • 4 min read',
    'type': 'pdf',
    'url': ContentViewerDummyUrls.pdf,
    'thumbnailUrl': null,
    'tags': ['Motivation', 'Career'],
    'difficulty': 'Easy',
    'sortOrder': 12,
  },
  {
    'title': 'Electrochemistry Explained',
    'subtitle': 'Video • 12 min',
    'type': 'video',
    'url': ContentViewerDummyUrls.video,
    'thumbnailUrl': null,
    'tags': ['JEE', 'NEET'],
    'difficulty': 'Medium',
    'sortOrder': 13,
  },
  {
    'title': 'Formula Sheet: Calculus',
    'subtitle': 'PDF • Quick ref',
    'type': 'pdf',
    'url': ContentViewerDummyUrls.pdf,
    'thumbnailUrl': null,
    'tags': ['JEE', 'Olympiad'],
    'difficulty': 'Medium',
    'sortOrder': 14,
  },
  {
    'title': 'Success Stories: Toppers Speak',
    'subtitle': 'Article • 8 min',
    'type': 'pdf',
    'url': ContentViewerDummyUrls.pdf,
    'thumbnailUrl': null,
    'tags': ['Career', 'Motivation'],
    'difficulty': 'Easy',
    'sortOrder': 15,
  },
];
