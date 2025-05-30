library para_search;

import 'package:flutter/material.dart';

class ParaSearch extends StatefulWidget {
  final String paragraph;
  final TextStyle? paragraphStyle;
  final TextStyle? highlightStyle;
  final TextStyle? activeHighlightStyle;

  const ParaSearch({
    super.key,
    required this.paragraph,
    this.paragraphStyle,
    this.highlightStyle,
    this.activeHighlightStyle,
  });

  @override
  State<ParaSearch> createState() => _ParaSearchState();
}

class _ParaSearchState extends State<ParaSearch> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  int _currentMatchIndex = 0;
  List<int> _matchPositions = [];

  List<TextSpan> _highlightOccurrences(String source, String query) {
    if (query.isEmpty) {
      return [TextSpan(text: source, style: widget.paragraphStyle)];
    }

    List<TextSpan> spans = [];
    int start = 0;
    String sourceLower = source.toLowerCase();
    String queryLower = query.toLowerCase();

    _matchPositions = [];

    while (true) {
      final int index = sourceLower.indexOf(queryLower, start);
      if (index == -1) {
        if (start < source.length) {
          spans.add(TextSpan(
              text: source.substring(start), style: widget.paragraphStyle));
        }
        break;
      }

      if (start != index) {
        spans.add(TextSpan(
            text: source.substring(start, index), style: widget.paragraphStyle));
      }

      _matchPositions.add(index);

      spans.add(
        TextSpan(
          text: source.substring(index, index + query.length),
          style: _currentMatchIndex == _matchPositions.length - 1
              ? widget.activeHighlightStyle ??
                  const TextStyle(
                      backgroundColor: Colors.orange,
                      fontWeight: FontWeight.bold)
              : widget.highlightStyle ??
                  const TextStyle(
                      backgroundColor: Colors.yellow,
                      fontWeight: FontWeight.bold),
        ),
      );

      start = index + query.length;
    }

    return spans;
  }

  void _scrollToMatch(int index) {
    if (_matchPositions.isEmpty || index < 0 || index >= _matchPositions.length) return;

    final double estimatedPosition = _matchPositions[index] /
        widget.paragraph.length *
        _scrollController.position.maxScrollExtent;

    _scrollController.animateTo(
      estimatedPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _nextMatch() {
    if (_matchPositions.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matchPositions.length;
      _scrollToMatch(_currentMatchIndex);
    });
  }

  void _previousMatch() {
    if (_matchPositions.isEmpty) return;
    setState(() {
      _currentMatchIndex = _currentMatchIndex > 0
          ? _currentMatchIndex - 1
          : _matchPositions.length - 1;
      _scrollToMatch(_currentMatchIndex);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Enter search term',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _currentMatchIndex = 0;
                          _matchPositions = [];
                        });
                      },
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _currentMatchIndex = 0;
                      if (value.isNotEmpty) {
                        _scrollToMatch(0);
                      }
                    });
                  },
                ),
              ),
              if (_matchPositions.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  '${_currentMatchIndex + 1}/${_matchPositions.length}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: _previousMatch,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward),
                  onPressed: _nextMatch,
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            child: RichText(
              text: TextSpan(
                style: widget.paragraphStyle ??
                    const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      height: 1.5,
                    ),
                children: _highlightOccurrences(
                  widget.paragraph,
                  _searchController.text,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
