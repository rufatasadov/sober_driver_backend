import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';

class SmartAddressSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final Function(double lat, double lng)? onCoordinatesSelected;
  final Function(String address)? onAddressSelected;

  const SmartAddressSearchField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.validator,
    this.onChanged,
    this.onCoordinatesSelected,
    this.onAddressSelected,
  });

  @override
  State<SmartAddressSearchField> createState() =>
      _SmartAddressSearchFieldState();
}

class _SmartAddressSearchFieldState extends State<SmartAddressSearchField> {
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  String _lastSearchQuery = '';
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _showResults = _focusNode.hasFocus && _searchResults.isNotEmpty;
    });
  }

  void _onTextChanged() {
    final query = widget.controller.text.trim();

    if (query.length >= 2 && query != _lastSearchQuery) {
      _lastSearchQuery = query;
      _searchAddresses(query);
    } else if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
    }

    widget.onChanged?.call(query);
  }

  Future<void> _searchAddresses(String query) async {
    if (_isSearching) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            '${ApiEndpoints.baseUrl}/addresses/search?query=${Uri.encodeComponent(query)}&limit=8'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _searchResults =
                List<Map<String, dynamic>>.from(data['data']['results']);
            _showResults = _focusNode.hasFocus && _searchResults.isNotEmpty;
          });
        }
      } else {
        print('Address search failed: ${response.statusCode}');
        setState(() {
          _searchResults = [];
          _showResults = false;
        });
      }
    } catch (e) {
      print('Address search error: $e');
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _selectAddress(Map<String, dynamic> address) {
    widget.controller.text = address['address'];
    widget.onAddressSelected?.call(address['address']);

    if (address['latitude'] != null && address['longitude'] != null) {
      widget.onCoordinatesSelected?.call(
        address['latitude'].toDouble(),
        address['longitude'].toDouble(),
      );
    }

    setState(() {
      _showResults = false;
    });

    _focusNode.unfocus();
  }

  void _clearSearch() {
    widget.controller.clear();
    setState(() {
      _searchResults = [];
      _showResults = false;
    });
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Address input field
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radius),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radius),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.controller.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear, color: AppColors.textSecondary),
                    onPressed: _clearSearch,
                  ),
                if (_isSearching)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(Icons.search, color: AppColors.primary),
                  onPressed: () {
                    if (widget.controller.text.isNotEmpty) {
                      _searchAddresses(widget.controller.text);
                    }
                  },
                ),
              ],
            ),
            prefixIcon: Icon(Icons.location_on, color: AppColors.primary),
          ),
          validator: widget.validator,
          onChanged: (value) {
            // Text change is handled by the listener
          },
        ),

        // Search results dropdown
        if (_showResults && _searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radius),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingSmall,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppSizes.radius),
                      topRight: Radius.circular(AppSizes.radius),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Axtarış nəticələri (${_searchResults.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Results list
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: AppColors.divider,
                  ),
                  itemBuilder: (context, index) {
                    final address = _searchResults[index];
                    final isLocal = address['source'] == 'local';

                    return ListTile(
                      dense: true,
                      leading: Icon(
                        isLocal ? Icons.storage : Icons.public,
                        size: 20,
                        color: isLocal ? AppColors.success : AppColors.warning,
                      ),
                      title: Text(
                        address['address'] ?? address['addressText'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (address['city'] != null ||
                              address['district'] != null)
                            Text(
                              '${address['city'] ?? ''}${address['city'] != null && address['district'] != null ? ', ' : ''}${address['district'] ?? ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          Row(
                            children: [
                              Icon(
                                isLocal ? Icons.storage : Icons.public,
                                size: 12,
                                color: isLocal
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isLocal ? 'Yerli bazadan' : 'Google Maps',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isLocal
                                      ? AppColors.success
                                      : AppColors.warning,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (address['popularityScore'] != null &&
                                  address['popularityScore'] > 0) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.trending_up,
                                    size: 12, color: AppColors.success),
                                const SizedBox(width: 2),
                                Text(
                                  '${address['popularityScore']}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () => _selectAddress(address),
                    );
                  },
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingSmall,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppSizes.radius),
                      bottomRight: Radius.circular(AppSizes.radius),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Yerli bazadan axtarış edilir, tapılmazsa Google Maps istifadə olunur',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
