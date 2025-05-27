import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/footballer_profile.dart';
import '../models/scout_profile.dart';
import '../models/club_profile.dart';
import '../services/profile_service.dart';
import '../widgets/navbar/bottom_navbar.dart';
import '../widgets/country_selector.dart';
import '../screens/profile_view_page.dart';
import '../utils/countries.dart';

enum UserType { footballer, scout, club }

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Search results
  List<FootballerProfile> _footballers = [];
  List<ScoutProfile> _scouts = [];
  List<ClubProfile> _clubs = [];

  // Loading states
  bool _isLoading = false;
  bool _hasSearched = false;

  // Current filters
  Map<String, dynamic> _footballerFilters = {};
  Map<String, dynamic> _scoutFilters = {};
  Map<String, dynamic> _clubFilters = {};

  int _selectedIndex = 1; // Search tab index

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // Load some initial data for each type
      final footballers = await ProfileService.searchFootballers();
      final scouts = await ProfileService.searchScouts();
      final clubs = await _searchClubs();

      setState(() {
        _footballers = footballers.take(10).toList();
        _scouts = scouts.take(10).toList();
        _clubs = clubs.take(10).toList();
        _hasSearched = true;
      });
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<List<ClubProfile>> _searchClubs({
    String? league,
    String? location,
    String? division,
  }) async {
    try {
      var query = Supabase.instance.client.from('club_profiles').select();

      if (league != null && league.isNotEmpty) {
        query = query.eq('league', league);
      }
      if (location != null && location.isNotEmpty) {
        query = query.ilike('location', '%$location%');
      }
      if (division != null && division.isNotEmpty) {
        query = query.eq('division', division);
      }

      final response = await query.limit(50);
      return (response as List)
          .map((json) => ClubProfile.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error searching clubs: $e');
      return [];
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/');
        break;
      case 1:
        // Stay on search page
        break;
      case 2:
        Navigator.pushNamed(context, '/news_home');
        break;
      case 3:
        Navigator.pushNamed(context, '/footballer_profile');
        break;
    }
  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final query = _searchController.text.trim();

      // Search all types based on current tab
      switch (_tabController.index) {
        case 0: // Footballers
          final results = await _searchFootballersWithQuery(query);
          setState(() => _footballers = results);
          break;
        case 1: // Scouts
          final results = await _searchScoutsWithQuery(query);
          setState(() => _scouts = results);
          break;
        case 2: // Clubs
          final results = await _searchClubsWithQuery(query);
          setState(() => _clubs = results);
          break;
      }

      setState(() => _hasSearched = true);
    } catch (e) {
      debugPrint('Error performing search: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<List<FootballerProfile>> _searchFootballersWithQuery(
    String query,
  ) async {
    try {
      final response = await Supabase.instance.client
          .from('footballer_profiles')
          .select()
          .or(
            'full_name.ilike.%$query%,position.ilike.%$query%,current_club.ilike.%$query%',
          )
          .limit(50);

      return (response as List)
          .map((json) => FootballerProfile.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error searching footballers: $e');
      return [];
    }
  }

  Future<List<ScoutProfile>> _searchScoutsWithQuery(String query) async {
    try {
      final response = await Supabase.instance.client
          .from('scout_profiles')
          .select()
          .or(
            'full_name.ilike.%$query%,country.ilike.%$query%,organization.ilike.%$query%',
          )
          .limit(50);

      return (response as List)
          .map((json) => ScoutProfile.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error searching scouts: $e');
      return [];
    }
  }

  Future<List<ClubProfile>> _searchClubsWithQuery(String query) async {
    try {
      final response = await Supabase.instance.client
          .from('club_profiles')
          .select()
          .or(
            'club_name.ilike.%$query%,location.ilike.%$query%,league.ilike.%$query%',
          )
          .limit(50);

      return (response as List)
          .map((json) => ClubProfile.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error searching clubs: $e');
      return [];
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
          shaderCallback:
              (bounds) => LinearGradient(
                colors: [Colors.yellow[400]!, Colors.orange[400]!],
              ).createShader(bounds),
          child: const Text(
            'Search',
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
            Tab(icon: Icon(Icons.sports_soccer), text: 'Footballers'),
            Tab(icon: Icon(Icons.search), text: 'Scouts'),
            Tab(icon: Icon(Icons.business), text: 'Clubs'),
          ],
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/countries'),
        backgroundColor: Colors.yellow[400],
        foregroundColor: Colors.black,
        icon: const Icon(Icons.public),
        label: const Text('Countries'),
      ),
      bottomNavigationBar: BottomNavbar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
          hintText: 'Search ${_getSearchHint()}...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          prefixIcon: Icon(Icons.search, color: Colors.yellow[400]),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                  : IconButton(
                    icon: Icon(Icons.tune, color: Colors.yellow[400]),
                    onPressed: _showFilters,
                  ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        onSubmitted: (_) => _performSearch(),
        onChanged: (value) => setState(() {}),
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

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterSheet(),
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
          ['Junior', 'Senior', 'Expert', 'Master'],
          (value) => setState(() => _scoutFilters['scouting_level'] = value),
        ),
        const SizedBox(height: 16),
        _buildCountryFilter(),
      ],
    );
  }

  Widget _buildClubFilters() {
    return Column(
      children: [
        _buildFilterDropdown(
          'League',
          _clubFilters['league'],
          ['Ligue 1', 'Ligue 2', 'Regional League', 'Youth League'],
          (value) => setState(() => _clubFilters['league'] = value),
        ),
        const SizedBox(height: 16),
        _buildFilterDropdown(
          'Division',
          _clubFilters['division'],
          ['Professional', 'Semi-Professional', 'Amateur'],
          (value) => setState(() => _clubFilters['division'] = value),
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

  Widget _buildFootballersTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.yellow),
      );
    }

    if (!_hasSearched) {
      return _buildEmptyState('Search for footballers', Icons.sports_soccer);
    }

    if (_footballers.isEmpty) {
      return _buildEmptyState('No footballers found', Icons.search_off);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _footballers.length,
      itemBuilder:
          (context, index) => _buildFootballerCard(_footballers[index]),
    );
  }

  Widget _buildScoutsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.yellow),
      );
    }

    if (!_hasSearched) {
      return _buildEmptyState('Search for scouts', Icons.search);
    }

    if (_scouts.isEmpty) {
      return _buildEmptyState('No scouts found', Icons.search_off);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _scouts.length,
      itemBuilder: (context, index) => _buildScoutCard(_scouts[index]),
    );
  }

  Widget _buildClubsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.yellow),
      );
    }

    if (!_hasSearched) {
      return _buildEmptyState('Search for clubs', Icons.business);
    }

    if (_clubs.isEmpty) {
      return _buildEmptyState('No clubs found', Icons.search_off);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _clubs.length,
      itemBuilder: (context, index) => _buildClubCard(_clubs[index]),
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileViewPage(userId: footballer.userId),
            ),
          );
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileViewPage(userId: scout.userId),
            ),
          );
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileViewPage(userId: club.userId),
            ),
          );
        },
      ),
    );
  }
}
