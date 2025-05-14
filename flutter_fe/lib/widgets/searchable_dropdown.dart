import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchableDropdown<T> extends StatefulWidget {
  final List<T> items;
  final List<T> selectedItems;
  final String hintText;
  final bool isMultiSelect;
  final Function(List<T>) onItemsSelected;
  final Function(T) displayItemName;
  final IconData? prefixIcon;
  final Function(String)? onSearchChanged;
  final bool isLoading;

  const SearchableDropdown({
    super.key,
    required this.items,
    required this.selectedItems,
    required this.hintText,
    required this.onItemsSelected,
    required this.displayItemName,
    this.isMultiSelect = false,
    this.prefixIcon,
    this.onSearchChanged,
    this.isLoading = false,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  bool _isDropdownOpen = false;
  OverlayEntry? _overlayEntry;
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
    _focusNode.addListener(_onFocusChange);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(SearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _filteredItems = List.from(widget.items);
      _filterItems(_searchController.text);
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      Future.microtask(() {
        if (mounted) {
          _showOverlay();
        }
      });
    } else {
      _removeOverlay();
    }
  }

  void _onTap() {
    debugPrint('SearchableDropdown: onTap called');
    if (!_isDropdownOpen) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _onSearchChanged() {
    if (widget.onSearchChanged != null) {
      widget.onSearchChanged!(_searchController.text);
    } else {
      _filterItems(_searchController.text);
    }
  }

  void _filterItems(String query) {
    if (!mounted) return;

    if (query.isEmpty) {
      setState(() {
        _filteredItems = List.from(widget.items);
      });
    } else {
      setState(() {
        _filteredItems = widget.items.where((item) {
          final String itemName = widget.displayItemName(item).toLowerCase();
          return itemName.contains(query.toLowerCase());
        }).toList();
      });
    }

    if (_isDropdownOpen && mounted) {
      Future.microtask(() {
        _removeOverlay();
        _showOverlay();
      });
    }
  }

  void _showOverlay() {
    if (!mounted) return;

    _isDropdownOpen = true;
    _overlayEntry = _createOverlayEntry();

    if (_overlayEntry != null) {
      try {
        debugPrint(
            'SearchableDropdown: Attempting to show overlay with ${_filteredItems.length} items');
        Overlay.of(context).insert(_overlayEntry!);
        setState(() {});
        debugPrint('SearchableDropdown: Successfully showed overlay');
      } catch (e) {
        debugPrint('SearchableDropdown: Error showing overlay: $e');
        _isDropdownOpen = false;
        _overlayEntry = null;
      }
    }
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      try {
        debugPrint('SearchableDropdown: Removing overlay');
        _overlayEntry!.remove();
        setState(() {
          _isDropdownOpen = false;
        });
        debugPrint('SearchableDropdown: Successfully removed overlay');
      } catch (e) {
        debugPrint('SearchableDropdown: Error removing overlay: $e');
      } finally {
        _overlayEntry = null;
        _isDropdownOpen = false;
      }
    }
  }

  void _toggleItem(T item) {
    if (!mounted) return;

    debugPrint(
        'SearchableDropdown: Toggling item: ${widget.displayItemName(item)}');

    List<T> newSelectedItems = List.from(widget.selectedItems);

    if (widget.isMultiSelect) {
      if (newSelectedItems.contains(item)) {
        newSelectedItems.remove(item);
      } else {
        newSelectedItems.add(item);
      }
    } else {
      newSelectedItems = [item];
      _searchController.text = widget.displayItemName(item);
      _focusNode.unfocus();
    }

    widget.onItemsSelected(newSelectedItems);
    debugPrint(
        'SearchableDropdown: Selected items updated, count: ${newSelectedItems.length}');
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final Offset offset = renderBox.localToGlobal(Offset.zero);

    debugPrint('SearchableDropdown: Creating overlay entry');
    debugPrint('SearchableDropdown: Render box size: $size');
    debugPrint('SearchableDropdown: Offset: $offset');
    debugPrint('SearchableDropdown: Items count: ${_filteredItems.length}');

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        left: offset.dx,
        top: offset.dy + size.height,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 200,
            ),
            child: widget.isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _filteredItems.isEmpty
                    ? ListTile(
                        title: Text(
                          'No items found',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final T item = _filteredItems[index];
                          final bool isSelected =
                              widget.selectedItems.contains(item);

                          return ListTile(
                            dense: true,
                            title: Text(
                              widget.displayItemName(item),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check,
                                    color: Color(0xFF0272B1))
                                : null,
                            onTap: () => _toggleItem(item),
                            tileColor: isSelected
                                ? const Color(0xFF0272B1).withOpacity(0.1)
                                : null,
                          );
                        },
                      ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug what's being rendered
    debugPrint(
        'SearchableDropdown: Building with ${widget.items.length} items, ${widget.selectedItems.length} selected items');
    if (widget.items.isNotEmpty) {
      debugPrint(
          'SearchableDropdown: First item: ${widget.displayItemName(widget.items.first)}');
    }
    if (widget.selectedItems.isNotEmpty) {
      debugPrint(
          'SearchableDropdown: First selected item: ${widget.displayItemName(widget.selectedItems.first)}');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isDropdownOpen
                    ? const Color(0xFF0272B1)
                    : Colors.grey[300]!,
                width: _isDropdownOpen ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                if (widget.prefixIcon != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Icon(widget.prefixIcon, color: Colors.grey[600]),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 14.0),
                    child: Text(
                      widget.selectedItems.isNotEmpty
                          ? widget.displayItemName(widget.selectedItems.first)
                          : widget.hintText,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: widget.selectedItems.isNotEmpty
                            ? Colors.black87
                            : Colors.grey[500],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.selectedItems.isNotEmpty &&
                        !widget.isMultiSelect)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          widget.onItemsSelected([]);
                        },
                      ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Icon(
                        _isDropdownOpen
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (widget.isMultiSelect && widget.selectedItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.selectedItems.map((item) {
                return Chip(
                  label: Text(
                    widget.displayItemName(item),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: const Color(0xFF0272B1),
                  deleteIconColor: Colors.white,
                  onDeleted: () {
                    _toggleItem(item);
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
