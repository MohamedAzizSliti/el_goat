// lib/screens/countries_list_page.dart

import 'package:flutter/material.dart';
import '../utils/countries.dart';
import '../widgets/navbar/bottom_navbar.dart';

class CountriesListPage extends StatefulWidget {
  const CountriesListPage({Key? key}) : super(key: key);

  @override
  State<CountriesListPage> createState() => _CountriesListPageState();
}

class _CountriesListPageState extends State<CountriesListPage> 
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredCountries = Countries.all;
  bool _showPopularFirst = true;
  int _selectedIndex = 1; // Assuming this is accessed from search
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeCountries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeCountries() {
    setState(() {
      if (_showPopularFirst) {
        _filteredCountries = [
          ...Countries.footballCountries,
          ...Countries.all.where((country) => 
              !Countries.footballCountries.contains(country)),
        ];
      } else {
        _filteredCountries = Countries.all;
      }
    });
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

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/');
        break;
      case 1:
        Navigator.pushNamed(context, '/search');
        break;
      case 2:
        Navigator.pushNamed(context, '/news_home');
        break;
      case 3:
        Navigator.pushNamed(context, '/footballer_profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Colors.yellow[400]!, Colors.orange[400]!],
          ).createShader(bounds),
          child: const Text(
            'Countries',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.yellow[400],
          labelColor: Colors.yellow[400],
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.star), text: 'Popular'),
            Tab(icon: Icon(Icons.public), text: 'All Countries'),
          ],
          onTap: (index) {
            setState(() {
              _showPopularFirst = index == 0;
              _initializeCountries();
            });
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0f0f23),
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f0f23),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Search bar
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search countries...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                  prefixIcon: Icon(Icons.search, color: Colors.yellow[400]),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: () {
                            _searchController.clear();
                            _filterCountries('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onChanged: _filterCountries,
              ),
            ),

            // Statistics
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.yellow[400]!.withValues(alpha: 0.1),
                    Colors.orange[400]!.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.yellow[400]!.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Total Countries', '${Countries.all.length}', Icons.public),
                  _buildStatItem('Football Nations', '${Countries.footballCountries.length}', Icons.sports_soccer),
                  _buildStatItem('Showing', '${_filteredCountries.length}', Icons.visibility),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Countries list
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCountriesList(Countries.footballCountries),
                  _buildCountriesList(_filteredCountries),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavbar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.yellow[400], size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCountriesList(List<String> countries) {
    if (countries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            Text(
              'No countries found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: countries.length,
      itemBuilder: (context, index) {
        final country = countries[index];
        final flag = Countries.getFlag(country);
        final isPopular = Countries.footballCountries.contains(country);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isPopular 
                      ? [Colors.yellow[400]!, Colors.orange[400]!]
                      : [Colors.blue[400]!, Colors.purple[400]!],
                ),
              ),
              child: Center(
                child: Text(
                  flag,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            title: Text(
              country,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: isPopular 
                ? Text(
                    'Popular Football Nation',
                    style: TextStyle(
                      color: Colors.yellow[400],
                      fontSize: 12,
                    ),
                  )
                : null,
            trailing: isPopular 
                ? Icon(Icons.star, color: Colors.yellow[400], size: 20)
                : Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.5), size: 16),
            onTap: () {
              // Handle country selection
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Selected: $country $flag'),
                  backgroundColor: Colors.green[600],
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
