import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokedex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.red, useMaterial3: true),
      home: const PokemonListScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// หน้าจอที่ 1: แสดงรายการ Pokemon (Pokemon List)
// ---------------------------------------------------------------------------
class PokemonListScreen extends StatefulWidget {
  const PokemonListScreen({super.key});

  @override
  State<PokemonListScreen> createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends State<PokemonListScreen> {
  List<dynamic> pokemonList = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool isGridView = false;
  int offset = 0;
  final int limit = 20;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchPokemonList();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        !isLoading) {
      loadMore();
    }
  }

  Future<void> fetchPokemonList() async {
    final url = Uri.parse(
      'https://pokeapi.co/api/v2/pokemon?limit=$limit&offset=$offset',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          pokemonList = data['results'];
          isLoading = false;
          offset = limit;
        });
      } else {
        throw Exception("ไม่สามารถโหลดข้อมูลได้");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error: $e');
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore) return;

    setState(() {
      isLoadingMore = true;
    });

    final url = Uri.parse(
      'https://pokeapi.co/api/v2/pokemon?limit=$limit&offset=$offset',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          pokemonList.addAll(data['results']);
          offset += limit;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingMore = false;
      });
      print('Error loading more: $e');
    }
  }

  int _extractIdFromUrl(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    return int.tryParse(segments.last) ?? 0;
  }

  String _getPokemonImageUrl(int id) {
    return 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                isGridView = !isGridView;
              });
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: isGridView ? _buildGridView() : _buildListView(),
                ),
                if (isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: pokemonList.length,
      itemBuilder: (context, index) {
        return _buildPokemonListTile(index);
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: pokemonList.length,
      itemBuilder: (context, index) {
        return _buildPokemonGridTile(index);
      },
    );
  }

  Widget _buildPokemonListTile(int index) {
    final pokemon = pokemonList[index];
    final name = pokemon['name'].toString();
    final detailUrl = pokemon['url'];
    final id = _extractIdFromUrl(detailUrl);
    final imageUrl = _getPokemonImageUrl(id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        leading: Hero(
          tag: 'pokemon-$id',
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey.shade200,
            child: Image.network(
              imageUrl,
              width: 45,
              height: 45,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.catching_pokemon, color: Colors.red),
            ),
          ),
        ),
        title: Text(
          name.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '#${id.toString().padLeft(3, '0')}',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PokemonDetailScreen(id: id, name: name, imageUrl: imageUrl),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPokemonGridTile(int index) {
    final pokemon = pokemonList[index];
    final name = pokemon['name'].toString();
    final detailUrl = pokemon['url'];
    final id = _extractIdFromUrl(detailUrl);
    final imageUrl = _getPokemonImageUrl(id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PokemonDetailScreen(id: id, name: name, imageUrl: imageUrl),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Number at top right
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4, right: 6),
                child: Text(
                  '#${id.toString().padLeft(3, '0')}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Pokemon Image
            Expanded(
              child: Hero(
                tag: 'pokemon-$id',
                child: Image.network(
                  imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.catching_pokemon,
                    size: 40,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
            // Name at bottom
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Text(
                name.toUpperCase(),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// หน้าจอที่ 2: แสดงรายละเอียด Pokemon (Pokemon Detail)
// ---------------------------------------------------------------------------
class PokemonDetailScreen extends StatefulWidget {
  final int id;
  final String name;
  final String imageUrl;

  const PokemonDetailScreen({
    super.key,
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  Map<String, dynamic>? pokemonDetail;
  bool isLoading = true;

  // Pokemon type colors
  static const Map<String, Color> typeColors = {
    'normal': Color(0xFFA8A878),
    'fire': Color(0xFFF08030),
    'water': Color(0xFF6890F0),
    'electric': Color(0xFFF8D030),
    'grass': Color(0xFF78C850),
    'ice': Color(0xFF98D8D8),
    'fighting': Color(0xFFC03028),
    'poison': Color(0xFFA040A0),
    'ground': Color(0xFFE0C068),
    'flying': Color(0xFFA890F0),
    'psychic': Color(0xFFF85888),
    'bug': Color(0xFFA8B820),
    'rock': Color(0xFFB8A038),
    'ghost': Color(0xFF705898),
    'dragon': Color(0xFF7038F8),
    'dark': Color(0xFF705848),
    'steel': Color(0xFFB8B8D0),
    'fairy': Color(0xFFEE99AC),
  };

  @override
  void initState() {
    super.initState();
    fetchPokemonDetail();
  }

  Future<void> fetchPokemonDetail() async {
    try {
      final response = await http.get(
        Uri.parse('https://pokeapi.co/api/v2/pokemon/${widget.id}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          pokemonDetail = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load detail');
      }
    } catch (e) {
      print(e);
      setState(() {
        isLoading = false;
      });
    }
  }

  Color _getTypeColor(String type) {
    return typeColors[type.toLowerCase()] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final primaryType = pokemonDetail != null
        ? (pokemonDetail!['types'] as List).first['type']['name'].toString()
        : 'normal';
    final bgColor = _getTypeColor(primaryType);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          widget.name.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '#${widget.id.toString().padLeft(3, '0')}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : pokemonDetail == null
          ? const Center(
              child: Text("ไม่พบข้อมูล", style: TextStyle(color: Colors.white)),
            )
          : Column(
              children: [
                // Pokemon Image
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Hero(
                    tag: 'pokemon-${widget.id}',
                    child: Image.network(
                      widget.imageUrl,
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.catching_pokemon,
                        size: 150,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Detail Card
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Types
                          Center(child: _buildTypes()),
                          const SizedBox(height: 24),

                          // About Section
                          _buildSectionTitle('About', bgColor),
                          const SizedBox(height: 16),
                          _buildAboutInfo(),
                          const SizedBox(height: 24),

                          // Abilities
                          _buildSectionTitle('Abilities', bgColor),
                          const SizedBox(height: 12),
                          _buildAbilities(),
                          const SizedBox(height: 24),

                          // Base Stats
                          _buildSectionTitle('Base Stats', bgColor),
                          const SizedBox(height: 12),
                          _buildStats(bgColor),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
    );
  }

  Widget _buildTypes() {
    final types = pokemonDetail!['types'] as List;
    return Wrap(
      spacing: 10,
      children: types.map((typeInfo) {
        final typeName = typeInfo['type']['name'].toString();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: _getTypeColor(typeName),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            typeName.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAboutInfo() {
    final height = (pokemonDetail!['height'] as int) / 10; // dm to m
    final weight = (pokemonDetail!['weight'] as int) / 10; // hg to kg

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInfoColumn(Icons.straighten, '${height}m', 'Height'),
        Container(height: 50, width: 1, color: Colors.grey.shade300),
        _buildInfoColumn(Icons.fitness_center, '${weight}kg', 'Weight'),
      ],
    );
  }

  Widget _buildInfoColumn(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildAbilities() {
    final abilities = pokemonDetail!['abilities'] as List;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: abilities.map((abilityInfo) {
        final abilityName = abilityInfo['ability']['name'].toString();
        final isHidden = abilityInfo['is_hidden'] as bool;
        return Chip(
          label: Text(
            isHidden ? '$abilityName (Hidden)' : abilityName,
            style: TextStyle(color: isHidden ? Colors.grey : Colors.black87),
          ),
          backgroundColor: isHidden
              ? Colors.grey.shade200
              : Colors.blue.shade50,
        );
      }).toList(),
    );
  }

  Widget _buildStats(Color barColor) {
    final stats = pokemonDetail!['stats'] as List;

    final statNames = {
      'hp': 'HP',
      'attack': 'ATK',
      'defense': 'DEF',
      'special-attack': 'SATK',
      'special-defense': 'SDEF',
      'speed': 'SPD',
    };

    return Column(
      children: stats.map((stat) {
        final statName = stat['stat']['name'].toString();
        final baseStat = stat['base_stat'] as int;
        final displayName = statNames[statName] ?? statName.toUpperCase();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: barColor,
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(
                width: 35,
                child: Text(
                  baseStat.toString().padLeft(3, '0'),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: baseStat / 255,
                    backgroundColor: Colors.grey.shade200,
                    color: barColor,
                    minHeight: 8,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
