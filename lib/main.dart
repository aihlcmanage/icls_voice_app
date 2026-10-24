import 'dart:convert';
import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/services.dart';

void main() {
  runApp(const IclsVoiceApp());
}

class IclsVoiceApp extends StatelessWidget {
  const IclsVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ICLS シミュレーション音声',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ScenarioVoicePage(),
    );
  }
}

class ScenarioVoicePage extends StatefulWidget {
  const ScenarioVoicePage({super.key});

  @override
  State<ScenarioVoicePage> createState() => _ScenarioVoicePageState();
}

class _ScenarioVoicePageState extends State<ScenarioVoicePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _statusMessage = '設定ファイルを読み込み中...';
  bool _isLoading = true;

  // JSONから読み込むデータ構造（file: 実ファイル名, label: 表示名）
  List<Map<String, String>> _scenario1Files = [];
  List<Map<String, String>> _scenario2Files = [];
  List<Map<String, String>> _scenario3Files = [];
  List<Map<String, String>> _commonFiles = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadConfigJson();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // JSONファイルを読み込んで各リストに割り振る
  Future<void> _loadConfigJson() async {
    try {
      final jsonString = await rootBundle.loadString('assets/audio_config.json');
      final Map<String, dynamic> data = json.decode(jsonString);

      setState(() {
        _scenario1Files = List<Map<String, String>>.from(
          data['scenario1'].map((x) => Map<String, String>.from(x)),
        );
        _scenario2Files = List<Map<String, String>>.from(
          data['scenario2'].map((x) => Map<String, String>.from(x)),
        );
        _scenario3Files = List<Map<String, String>>.from(
          data['scenario3'].map((x) => Map<String, String>.from(x)),
        );
        _commonFiles = List<Map<String, String>>.from(
          data['common'].map((x) => Map<String, String>.from(x)),
        );
        _isLoading = false;
        _statusMessage = '準備完了（タップして再生）';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'JSON読み込みエラー: $e';
      });
    }
  }

  // 半角英数字のファイル名で音声再生
  void _playSound(String fileName, String label) {
    try {
      final assetPath = 'assets/audio/$fileName';

      final audio = html.AudioElement(assetPath);
      audio.play().then((_) {
        setState(() {
          _statusMessage = '再生中: $label';
        });
      }).catchError((e) {
        setState(() {
          _statusMessage = '再生エラー: $e';
        });
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'エラー: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ICLS 音声シミュレーター', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        toolbarHeight: 40,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          indicatorWeight: 4,
          tabs: const [
            Tab(text: 'シナリオ 1'),
            Tab(text: 'シナリオ 2'),
            Tab(text: 'シナリオ 3'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              color: Colors.blue.shade50,
              child: Text(
                _statusMessage,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTwoZoneLayout(_scenario1Files, _commonFiles, 'シナリオ1 定型文'),
                        _buildTwoZoneLayout(_scenario2Files, _commonFiles, 'シナリオ2 定型文'),
                        _buildTwoZoneLayout(_scenario3Files, _commonFiles, 'シナリオ3 定型文'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTwoZoneLayout(List<Map<String, String>> scenarioFiles, List<Map<String, String>> commonFiles, String title) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Column(
        children: [
          Expanded(
            flex: 6,
            child: _buildZoneCard(
              title: title,
              color: Colors.blue.shade100,
              badgeColor: Colors.blue.shade800,
              items: scenarioFiles,
              emptyText: 'シナリオ用音声がありません',
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            flex: 4,
            child: _buildZoneCard(
              title: '共通アドリブ・反応',
              color: Colors.orange.shade100,
              badgeColor: Colors.orange.shade900,
              items: commonFiles,
              emptyText: '共通音声がありません',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneCard({
    required String title,
    required Color color,
    required Color badgeColor,
    required List<Map<String, String>> items,
    required String emptyText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      emptyText,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = items.length > 8 ? 3 : 2;
                      
                      return GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: (constraints.maxWidth / crossAxisCount) /
                              (constraints.maxHeight / ((items.length / crossAxisCount).ceil())),
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final fileName = item['file'] ?? '';
                          final label = item['label'] ?? '';

                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              elevation: 2,
                              padding: const EdgeInsets.all(4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: () => _playSound(fileName, label),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}