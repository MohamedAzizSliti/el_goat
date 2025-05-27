// lib/widgets/country_selector.dart

import 'package:flutter/material.dart';
import '../utils/countries.dart';

class CountrySelector extends StatefulWidget {
  final String? selectedCountry;
  final Function(String) onCountrySelected;
  final bool showFlags;
  final bool showPopularFirst;
  final String? hintText;

  const CountrySelector({
    Key? key,
    this.selectedCountry,
    required this.onCountrySelected,
    this.showFlags = true,
    this.showPopularFirst = true,
    this.hintText,
  }) : super(key: key);

  @override
  State<CountrySelector> createState() => _CountrySelectorState();
}

class _CountrySelectorState extends State<CountrySelector> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredCountries = [];
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeCountries();
  }

  void _initializeCountries() {
    if (widget.showPopularFirst) {
      _filteredCountries = [
        ...Countries.footballCountries,
        '---', // Separator
        ...Countries.all.where((country) => 
            !Countries.footballCountries.contains(country)),
      ];
    } else {
      _filteredCountries = Countries.all;
    }
  }

  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        _initializeCountries();
      } else {
        _filteredCountries = Countries.searchCountries(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected country display / dropdown trigger
        GestureDetector(
          onTap: () => _showCountryPicker(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                if (widget.showFlags && widget.selectedCountry != null)
                  Text(
                    Countries.getFlag(widget.selectedCountry!),
                    style: const TextStyle(fontSize: 20),
                  ),
                if (widget.showFlags && widget.selectedCountry != null)
                  const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.selectedCountry ?? 
                        widget.hintText ?? 
                        'Select Country',
                    style: TextStyle(
                      color: widget.selectedCountry != null 
                          ? Colors.white 
                          : Colors.white.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Color(0xFF1a1a2e),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Select Country',
                    style: TextStyle(
                      color: Colors.yellow[400],
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),
            
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search countries...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                  prefixIcon: Icon(Icons.search, color: Colors.yellow[400]),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _filterCountries,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Countries list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filteredCountries.length,
                itemBuilder: (context, index) {
                  final country = _filteredCountries[index];
                  
                  // Separator
                  if (country == '---') {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.3))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'All Countries',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.3))),
                        ],
                      ),
                    );
                  }
                  
                  final isSelected = country == widget.selectedCountry;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Colors.yellow[400]!.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected 
                          ? Border.all(color: Colors.yellow[400]!)
                          : null,
                    ),
                    child: ListTile(
                      leading: widget.showFlags 
                          ? Text(
                              Countries.getFlag(country),
                              style: const TextStyle(fontSize: 24),
                            )
                          : null,
                      title: Text(
                        country,
                        style: TextStyle(
                          color: isSelected ? Colors.yellow[400] : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected 
                          ? Icon(Icons.check, color: Colors.yellow[400])
                          : null,
                      onTap: () {
                        widget.onCountrySelected(country);
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
