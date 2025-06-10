// lib/features/search/presentation/pages/search_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/footballer_profile.dart';
import '../models/scout_profile.dart';
import '../models/club_profile.dart';
import '../widgets/country_selector.dart';
import '../services/user_profile_navigator.dart';

enum UserType { footballer, scout, club }

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Nested PageControllers: one per tab
  late Map<int, PageController> _innerControllers;

  // Results
  List<FootballerProfile> _footballers = [];
  List<ScoutProfile> _scouts = [];
  List<ClubProfile> _clubs = [];

  // Loading & state
  bool _isLoading = false;
  bool _hasSearched = false;

  // Filters per tab
  final Map<String, dynamic> _footballerFilters = {};
  final Map<String, dynamic> _scoutFilters = {};
  final Map<String, dynamic> _clubFilters = {};

  // Persistent controllers for filter text fields
  late final TextEditingController _scoutCityController;
  late final TextEditingController _clubLocationController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _innerControllers = {
      0: PageController(),
      1: PageController(),
      2: PageController(),
    };
    // Initialize controllers with current filter values
    _scoutCityController = TextEditingController(
      text: _scoutFilters['city'] ?? '',
    );
    _clubLocationController = TextEditingController(
      text: _clubFilters['location'] ?? '',
    );
    // Add listeners to update filters
    _scoutCityController.addListener(() {
      _scoutFilters['city'] = _scoutCityController.text;
    });
    _clubLocationController.addListener(() {
      _clubFilters['location'] = _clubLocationController.text;
    });
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scoutCityController.dispose();
    _clubLocationController.dispose();
    _innerControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // fill initial lists (first 10)
      _footballers =
          (await Supabase.instance.client
              .from('footballer_profiles')
              .select()
              .limit(10))!.map((j) => FootballerProfile.fromJson(j)).toList();
      _scouts =
          (await Supabase.instance.client
              .from('scout_profiles')
              .select()
              .limit(10))!.map((j) => ScoutProfile.fromJson(j)).toList();
      _clubs =
          (await Supabase.instance.client
              .from('club_profiles')
              .select()
              .limit(10))!.map((j) => ClubProfile.fromJson(j)).toList();
      _hasSearched = true;
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _performSearch() async {
    final q = _searchController.text.trim();
    setState(() => _isLoading = true);

    try {
      switch (_tabController.index) {
        case 0: // Footballers
          var qb0 = Supabase.instance.client
              .from('footballer_profiles')
              .select()
              .or(
                'full_name.ilike.%$q%,position.ilike.%$q%,current_club.ilike.%$q%',
              );
          if (_footballerFilters['position'] != null &&
              (_footballerFilters['position'] as String).isNotEmpty) {
            qb0 = qb0.eq('position', _footballerFilters['position']);
          }
          if (_footballerFilters['experience_level'] != null &&
              (_footballerFilters['experience_level'] as String).isNotEmpty) {
            qb0 = qb0.eq(
              'experience_level',
              _footballerFilters['experience_level'],
            );
          }
          // Remove age filter from SQL, filter in Dart below
          if (_footballerFilters['country'] != null &&
              (_footballerFilters['country'] as String).isNotEmpty) {
            qb0 = qb0.eq('country', _footballerFilters['country']);
          }
          final res0 = await qb0.limit(
            100,
          ); // fetch more for client-side filtering
          var allFootballers =
              (res0 as List).map((j) => FootballerProfile.fromJson(j)).toList();
          // Age filtering in Dart
          int? minAge = _footballerFilters['min_age'];
          int? maxAge = _footballerFilters['max_age'];
          if (minAge != null || maxAge != null) {
            allFootballers =
                allFootballers.where((f) {
                  final age = f.age;
                  if (age == null) return false;
                  if (minAge != null && age < minAge) return false;
                  if (maxAge != null && age > maxAge) return false;
                  return true;
                }).toList();
          }
          _footballers = allFootballers;
          debugPrint(
            '[FILTER] Footballer filters: ${_footballerFilters.toString()}',
          );
          break;

        case 1: // Scouts
          var qb1 = Supabase.instance.client
              .from('scout_profiles')
              .select()
              .or(
                'full_name.ilike.%$q%,country.ilike.%$q%,city.ilike.%$q%,scouting_level.ilike.%$q%',
              );
          if (_scoutFilters['scouting_level'] != null &&
              (_scoutFilters['scouting_level'] as String).isNotEmpty) {
            qb1 = qb1.eq('scouting_level', _scoutFilters['scouting_level']);
          }
          if (_scoutFilters['country'] != null &&
              (_scoutFilters['country'] as String).isNotEmpty) {
            qb1 = qb1.eq('country', _scoutFilters['country']);
          }
          final res1 = await qb1.limit(50);
          _scouts =
              (res1 as List).map((j) => ScoutProfile.fromJson(j)).toList();
          debugPrint('[FILTER] Scout filters: ${_scoutFilters.toString()}');
          break;

        case 2: // Clubs
          var qb2 = Supabase.instance.client
              .from('club_profiles')
              .select()
              .or('club_name.ilike.%$q%,location.ilike.%$q%,league.ilike.%$q%');
          if (_clubFilters['league'] != null &&
              (_clubFilters['league'] as String).isNotEmpty) {
            qb2 = qb2.eq('league', _clubFilters['league']);
          }
          if (_clubFilters['division'] != null &&
              (_clubFilters['division'] as String).isNotEmpty) {
            qb2 = qb2.eq('division', _clubFilters['division']);
          }
          if (_clubFilters['location'] != null &&
              (_clubFilters['location'] as String).isNotEmpty) {
            qb2 = qb2.ilike('location', '%${_clubFilters['location']}%');
          }
          final res2 = await qb2.limit(50);
          _clubs = (res2 as List).map((j) => ClubProfile.fromJson(j)).toList();
          debugPrint('[FILTER] Club filters: ${_clubFilters.toString()}');
          break;
      }
      setState(() => _hasSearched = true);
    } catch (e) {
      debugPrint('Error performing search: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _goToFilterPage() {
    final idx = _tabController.index;
    _innerControllers[idx]!.jumpToPage(1);
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search ${_getSearchHint()}…',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          prefixIcon: const Icon(Icons.search, color: Colors.yellow),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                      _performSearch();
                    },
                  )
                  : IconButton(
                    icon: const Icon(Icons.tune, color: Colors.yellow),
                    onPressed: _goToFilterPage,
                  ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        onChanged: (_) => _performSearch(),
      ),
    );
  }

  String _getSearchHint() {
    switch (_tabController.index) {
      case 0:
        return 'footballers by name, position, club';
      case 1:
        return 'scouts by name, country, organization';
      case 2:
        return 'clubs by name, location, league';
      default:
        return 'users';
    }
  }

  ///—— Result & Filter pages for Footballers ——
  Widget _buildFootballersTab() {
    final pc = _innerControllers[0]!;
    return PageView(
      controller: pc,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // —— Page 0: Search Results ——
        if (_isLoading)
          const Center(child: CircularProgressIndicator(color: Colors.yellow))
        else if (!_hasSearched)
          _emptyState('Search for footballers', Icons.sports_soccer)
        else if (_footballers.isEmpty)
          _emptyState('No footballers found', Icons.search_off)
        else
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _footballers.length,
            itemBuilder: (ctx, i) => _buildFootballerCard(_footballers[i]),
          ),

        // —— Page 1: Filters ——
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildFootballerFilters(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _footballerFilters.clear();
                        pc.jumpToPage(0);
                        _performSearch();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        pc.jumpToPage(0);
                        _performSearch();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  ///—— Result & Filter pages for Scouts ——
  Widget _buildScoutsTab() {
    final pc = _innerControllers[1]!;
    return PageView(
      controller: pc,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        if (_isLoading)
          const Center(child: CircularProgressIndicator(color: Colors.yellow))
        else if (!_hasSearched)
          _emptyState('Search for scouts', Icons.search)
        else if (_scouts.isEmpty)
          _emptyState('No scouts found', Icons.search_off)
        else
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _scouts.length,
            itemBuilder: (ctx, i) => _buildScoutCard(_scouts[i]),
          ),

        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildScoutFilters(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _scoutFilters.clear();
                        pc.jumpToPage(0);
                        _performSearch();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        pc.jumpToPage(0);
                        _performSearch();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  ///—— Result & Filter pages for Clubs ——
  Widget _buildClubsTab() {
    final pc = _innerControllers[2]!;
    return PageView(
      controller: pc,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        if (_isLoading)
          const Center(child: CircularProgressIndicator(color: Colors.yellow))
        else if (!_hasSearched)
          _emptyState('Search for clubs', Icons.business)
        else if (_clubs.isEmpty)
          _emptyState('No clubs found', Icons.search_off)
        else
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _clubs.length,
            itemBuilder: (ctx, i) => _buildClubCard(_clubs[i]),
          ),

        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildClubFilters(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _clubFilters.clear();
                        pc.jumpToPage(0);
                        _performSearch();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        pc.jumpToPage(0);
                        _performSearch();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 60, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.white.withOpacity(0.7))),
        ],
      ),
    );
  }

  // … (all your existing _buildFootballerCard, _buildScoutCard, _buildClubCard,
  //      plus _buildFootballerFilters, _buildScoutFilters, _buildClubFilters here) …

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Search',
          style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.yellow,
          labelColor: Colors.yellow,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.sports_soccer), text: 'Footballers'),
            Tab(icon: Icon(Icons.search), text: 'Scouts'),
            Tab(icon: Icon(Icons.business), text: 'Clubs'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFootballersTab(),
                _buildScoutsTab(),
                _buildClubsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/countries'),
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.public),
        label: const Text('Countries'),
      ),
    );
  }

  Widget _buildFilterSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1a1a2e),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Filters',
            style: TextStyle(
              color: Colors.yellow[400],
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildCurrentTabFilters(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _clearFilters();
                    _performSearch(); // re‐run without any filters

                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _applyFilters();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[400],
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTabFilters() {
    switch (_tabController.index) {
      case 0:
        return _buildFootballerFilters();
      case 1:
        return _buildScoutFilters();
      case 2:
        return _buildClubFilters();
      default:
        return const SizedBox();
    }
  }

  Widget _buildFootballerFilters() {
    return Column(
      children: [
        _buildFilterDropdown(
          'Position',
          _footballerFilters['position'],
          ['Goalkeeper', 'Defender', 'Midfielder', 'Forward'],
          (value) => setState(() => _footballerFilters['position'] = value),
        ),
        const SizedBox(height: 16),
        _buildFilterDropdown(
          'Experience Level',
          _footballerFilters['experience_level'],
          ['Beginner', 'Intermediate', 'Advanced', 'Professional'],
          (value) =>
              setState(() => _footballerFilters['experience_level'] = value),
        ),
        const SizedBox(height: 16),
        _buildAgeRangeFilter(),
      ],
    );
  }

  Widget _buildScoutFilters() {
    return Column(
      children: [
        _buildFilterDropdown(
          'Scouting Level',
          _scoutFilters['scouting_level'],
          [
            'Local',
            'National',
            'International',
          ], // Example values, update as needed
          (value) => setState(() => _scoutFilters['scouting_level'] = value),
        ),
        const SizedBox(height: 16),
        // Country
        _buildFilterDropdown(
          'Country',
          _scoutFilters['country'],
          [
            'Tunisia',
            'Algeria',
            'Morocco',
            'Egypt',
            'France',
            'Spain',
            'Italy', // ...add more or use a country list
          ],
          (value) => setState(() => _scoutFilters['country'] = value),
        ),
        const SizedBox(height: 16),
        // City (as text input for partial match)
        TextField(
          controller: _scoutCityController,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(
            labelText: 'City',
            labelStyle: TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Color(0xFF23234b),
            border: OutlineInputBorder(),
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildClubFilters() {
    return Column(
      children: [
        // Location (text input for city/country substring)
        TextField(
          controller: _clubLocationController,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(
            labelText: 'Location (city or country)',
            labelStyle: TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Color(0xFF23234b),
            border: OutlineInputBorder(),
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String? currentValue,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: DropdownButtonFormField<String>(
            value: currentValue,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            dropdownColor: const Color(0xFF1a1a2e),
            style: const TextStyle(color: Colors.white),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Any', style: TextStyle(color: Colors.white70)),
              ),
              ...options.map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    option,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildAgeRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Age Range',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildFilterDropdown(
                'Min Age',
                _footballerFilters['min_age']?.toString(),
                List.generate(30, (i) => (16 + i).toString()),
                (value) => setState(
                  () =>
                      _footballerFilters['min_age'] =
                          value != null ? int.tryParse(value) : null,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFilterDropdown(
                'Max Age',
                _footballerFilters['max_age']?.toString(),
                List.generate(30, (i) => (16 + i).toString()),
                (value) => setState(
                  () =>
                      _footballerFilters['max_age'] =
                          value != null ? int.tryParse(value) : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _clearFilters() {
    setState(() {
      _footballerFilters.clear();
      _scoutFilters.clear();
      _clubFilters.clear();
    });
  }

  void _applyFilters() {
    _performSearch();
  }

  Widget _buildCountryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Country',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/countries'),
              child: Text(
                'View All Countries',
                style: TextStyle(color: Colors.yellow[400], fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CountrySelector(
          selectedCountry: _scoutFilters['country'],
          onCountrySelected: (country) {
            setState(() => _scoutFilters['country'] = country);
          },
          showFlags: true,
          showPopularFirst: true,
          hintText: 'Select Country',
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 20),
          Text(
            message,
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

  Widget _buildFootballerCard(FootballerProfile footballer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: Colors.yellow[400],
          backgroundImage:
              footballer.avatarUrl != null
                  ? NetworkImage(footballer.avatarUrl!)
                  : null,
          child:
              footballer.avatarUrl == null
                  ? Text(
                    footballer.fullName.isNotEmpty
                        ? footballer.fullName[0]
                        : '?',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  : null,
        ),
        title: Text(
          footballer.fullName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${footballer.positionDisplay} • ${footballer.age} years',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            if (footballer.currentClub != null)
              Text(
                footballer.currentClub!,
                style: TextStyle(color: Colors.yellow[400]),
              ),
          ],
        ),
        trailing:
            footballer.isVerified
                ? Icon(Icons.verified, color: Colors.blue[400])
                : null,
        onTap: () {
          UserProfileNavigator.navigateFromSearchResult(context, {
            'user_id': footballer.userId,
            'role': 'footballer',
            'name': footballer.fullName,
            'position': footballer.position,
            'age': footballer.age,
          });
        },
      ),
    );
  }

  Widget _buildScoutCard(ScoutProfile scout) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: Colors.green[400],
          backgroundImage:
              scout.avatarUrl != null ? NetworkImage(scout.avatarUrl!) : null,
          child:
              scout.avatarUrl == null
                  ? Text(
                    scout.fullName.isNotEmpty ? scout.fullName[0] : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  : null,
        ),
        title: Text(
          scout.fullName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${scout.levelDisplay} • ${scout.experienceDisplay}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            if (scout.country != null)
              Text(
                scout.locationDisplay,
                style: TextStyle(color: Colors.green[400]),
              ),
          ],
        ),
        trailing:
            scout.isVerified
                ? Icon(Icons.verified, color: Colors.blue[400])
                : null,
        onTap: () {
          UserProfileNavigator.navigateFromSearchResult(context, {
            'user_id': scout.userId,
            'role': 'scout',
            'name': scout.fullName,
            'level': scout.scoutingLevel,
            'country': scout.country,
          });
        },
      ),
    );
  }

  Widget _buildClubCard(ClubProfile club) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: Colors.purple[400],
          backgroundImage:
              club.logoUrl != null ? NetworkImage(club.logoUrl!) : null,
          child:
              club.logoUrl == null
                  ? Text(
                    club.clubName.isNotEmpty ? club.clubName[0] : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  : null,
        ),
        title: Text(
          club.clubName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${club.leagueDisplay} • ${club.foundedDisplay}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            if (club.location != null)
              Text(club.location!, style: TextStyle(color: Colors.purple[400])),
          ],
        ),
        trailing:
            club.isVerified
                ? Icon(Icons.verified, color: Colors.blue[400])
                : null,
        onTap: () {
          UserProfileNavigator.navigateFromSearchResult(context, {
            'user_id': club.userId,
            'role': 'club',
            'name': club.clubName,
            'league': club.leagueDisplay,
            'location': club.location,
          });
        },
      ),
    );
  }
}
