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
  String _statusMessage = '音声読み込み中...';
  bool _isLoading = true;

  List<String> _scenario1Files = [];
  List<String> _scenario2Files = [];
  List<String> _scenario3Files = [];
  List<String> _commonFiles = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAudioAssets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAudioAssets() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final allAssets = manifest.listAssets();

      final audioPaths = allAssets.where((path) {
        return path.startsWith('assets/audio/') &&
            path.toLowerCase().endsWith('.wav');
      }).map((path) => path.split('/').last).toList();

      List<String> s1 = [];
      List<String> s2 = [];
      List<String> s3 = [];
      List<String> common = [];

      for (var fileName in audioPaths) {
        if (fileName.contains('シナリオ1') || fileName.contains('S1')) {
          s1.add(fileName);
        } else if (fileName.contains('シナリオ2') || fileName.contains('S2')) {
          s2.add(fileName);
        } else if (fileName.contains('シナリオ3') || fileName.contains('S3')) {
          s3.add(fileName);
        } else if (fileName.contains('共通') || fileName.contains('アドリブ')) {
          common.add(fileName);
        } else {
          s1.add(fileName);
        }
      }

      setState(() {
        _scenario1Files = s1;
        _scenario2Files = s2;
        _scenario3Files = s3;
        _commonFiles = common;
        _isLoading = false;
        _statusMessage = '準備完了（タップして再生）';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'アセット読み込みエラー: $e';
      });
    }
  }

  void _playSound(String fileName) {
    try {
      final encodedFileName = Uri.encodeComponent(fileName);
      final assetPath = 'assets/audio/$encodedFileName';

      final audio = html.AudioElement(assetPath);
      audio.play().then((_) {
        setState(() {
          _statusMessage = '再生中: ${fileName.replaceAll('.wav', '')}';
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

  Widget _buildTwoZoneLayout(List<String> scenarioFiles, List<String> commonFiles, String title) {
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
              files: scenarioFiles,
              emptyText: 'シナリオ用音声がありません\n(例: シナリオ1_胸が痛い.wav)',
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            flex: 4,
            child: _buildZoneCard(
              title: '共通アドリブ・反応',
              color: Colors.orange.shade100,
              badgeColor: Colors.orange.shade900,
              files: commonFiles,
              emptyText: '共通音声がありません\n(例: 共通_うー苦しい.wav)',
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
    required List<String> files,
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
            child: files.isEmpty
                ? Center(
                    child: Text(
                      emptyText,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = files.length > 8 ? 3 : 2;
                      
                      return GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: (constraints.maxWidth / crossAxisCount) /
                              (constraints.maxHeight / ((files.length / crossAxisCount).ceil())),
                        ),
                        itemCount: files.length,
                        itemBuilder: (context, index) {
                          final fileName = files[index];
                          final displayName = fileName
                              .replaceAll(RegExp(r'^(シナリオ1_|シナリオ2_|シナリオ3_|共通_|S1_|S2_|S3_|アドリブ_)'), '')
                              .replaceAll('.wav', '');

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
                            onPressed: () => _playSound(fileName),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  displayName,
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